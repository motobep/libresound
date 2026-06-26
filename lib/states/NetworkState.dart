import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logger.dart';

import 'package:music_player/logic/Config.dart';
import 'package:music_player/logic/PairCandidate.dart';
import 'package:music_player/logic/Syncing.dart';
import 'package:music_player/logic/lang.dart';
import 'package:music_player/logic/udp/UdpHandler.dart';
import 'package:music_player/logic/ws/WsHandler.dart';
import 'package:music_player/logic/UiNotification.dart';
import 'package:music_player/logic/enums.dart';
import 'package:music_player/view/App.dart';
import 'package:music_player/view/components/dialogs.dart';

class NetworkState extends ChangeNotifier {
  NetworkState(this.config, {required this.reloadFsSource}) : super();

  final Config config;

  late Syncing _syncing;
  String? currIp;

  List<PairCandidate> pairCandidates = [];
  PairCandidate? chosenCandidate;

  bool isShowSyncPage() {
    return _syncing.wsHandler.isConnectionOpenOrConnecting();
  }

  bool get isNetworkActivated {
    return _syncing.isNetworkActivated;
  }

  bool get isSyncing {
    return _syncing.wsHandler.isSyncing;
  }

  String syncingHeader = '';
  int gotItems = 0;
  int allItems = 0;
  List<String> errorsDuringSync = [];

  NetworkError networkError = NetworkError.none;

  void _setNetworkError(NetworkError err) async {
    await _syncing.deactivateNetwork();
    networkError = err;
    notifyListeners();
  }

  final void Function() reloadFsSource;

  void update() {
    notifyListeners();
  }

  // Notifies
  void tryInit() {
    if (config.allIps.isEmpty) {
      networkError = NetworkError.noIp;
      logger.log('NetworkError. Private IP address cannot be found');
    } else {
      networkError = NetworkError.none;
      currIp = config.allIps[0];
      _init(config);
    }
    notifyListeners();
  }

  void _init(Config config) {
    assert(currIp != null, 'currIp is null');

    // Init UDP
    UdpHandler udpHandler = UdpHandler(
      ipSelf: currIp!,
      multicastIp: CONFIG.multicastIp,
      multicastUdpPort: CONFIG.udpPort,
      deviceName: config.deviceName,
      addPairCandidateCallback: _addPairCandidate,
      pairRequestHandler: _pairRequestHandler,
      setNetworkError: _setNetworkError,
    );

    // Init WS
    WsHandler wsServer = WsHandler(currIp!, () => config.musicSourceDir!.path,
        notifyUiCallback: _notifyUiCallback,
        interruptCallback: _interruptCallback,
        connectHandler: _wsConnectHandler,
        closeHandler: _wsCloseHandler);

    _syncing = Syncing(udpHandler, wsServer);
  }

  Future<void> retry() async {
    await config.updateIps();
    tryInit();
  }

  void changeIp(String ip) {
    currIp = ip;
    _syncing.udpHandler.ipSelf = ip;
    _syncing.wsHandler.ip = ip;
    notifyListeners();
  }

  Future<void> activateNetwork() async {
    try {
      await _syncing.activateNetwork();
    } catch (e) {
      networkError = NetworkError.badActivation;
      logger.error('Error activating network: $e');
      notifyListeners();
      return;
    }

    int checkDelay =
        min(CONFIG.udpBroadcastDelayMs, CONFIG.udpPairRequestDelayMs);
    _checkPairTimer = Timer.periodic(Duration(milliseconds: checkDelay), (_) {
      _checkPairCandidates();
    });

    notifyListeners();
  }

  void deactivateNetwork() async {
    _checkPairTimer.cancel();

    await _syncing.deactivateNetwork();

    chosenCandidate = null;
    pairCandidates = [];
    notifyListeners();
  }

  void find() {
    _syncing.udpHandler.broadcastSelfInfo();
  }

  Future<void> pair(PairCandidate p) async {
    chosenCandidate = p;
    notifyListeners();

    _sendPairRequestsTillAcceptOrCancel(p);
  }

  bool _shouldSendPairRequsts() {
    return chosenCandidate != null &&
        !_syncing.wsHandler.isConnectionOpenOrConnecting();
  }

  Future<void> _sendPairRequestsTillAcceptOrCancel(PairCandidate p) async {
    while (_shouldSendPairRequsts()) {
      await Future.delayed(
          const Duration(milliseconds: CONFIG.udpPairRequestDelayMs));
      _syncing.udpHandler.sendPairRequest(p.ip, p.udpPort);
    }
  }

  Future<void> accept(PairCandidate p) async {
    bool ok = await _syncing.wsHandler.connect(p.ip, p.wsPort);
    if (ok) {
      chosenCandidate = p;
      notifyListeners();
    }
  }

  void cancel() {
    _unsetChosenCandidate();
  }

  Future<void> unpair() async {
    _syncing.wsHandler.closeCurrChannel();
  }

  void sync() {
    _syncing.wsHandler.sync();
    notifyListeners();
  }

  void download() {
    _syncing.wsHandler.download();
    notifyListeners();
  }

  void clean() {
    _syncing.wsHandler.clean();
    notifyListeners();
  }

  void _addPairCandidate(PairCandidate p) {
    if (!pairCandidates.contains(p)) {
      pairCandidates += [p];
    } else {
      // Update timestamp
      int idx = pairCandidates.indexOf(p);
      pairCandidates[idx].lastTimestamp = p.lastTimestamp;
    }
    notifyListeners();
  }

  void _pairRequestHandler(String ip, int port) {
    for (var p in pairCandidates) {
      if (ip == p.ip && port == p.wsPort) {
        p.setToAcceptState();
      }
    }
    pairCandidates = List.from(pairCandidates);
    notifyListeners();
  }

  void _unsetChosenCandidate() {
    // assert(chosenCandidate != null, 'chosenCandidate is null');
    if (chosenCandidate == null) {
      logger.log('chosenCandidate is null');
      return;
    }
    chosenCandidate!.setToPairState();
    chosenCandidate = null;
    notifyListeners();
  }

  void _printPairCandidates() {
    logger.log('Start: Pair Candidates');
    for (var p in pairCandidates) {
      p.show();
    }
    logger.log('End: Pair Candidates');
  }

  void _notifyUiCallback(UiNotification note) {
    switch (note.type) {
      case SyncNotify.start:
        syncingHeader = '';
        gotItems = 0;
        allItems = 0;
        errorsDuringSync = [];
        syncingHeader = lang.Preparation;
        break;
      case SyncNotify.finish:
        reloadFsSource();
        break;
      case SyncNotify.setText:
        syncingHeader = note.body!;
        logger.log(syncingHeader);
        break;
      case SyncNotify.setProgress:
        var arr = note.body!.split('/');
        logger.log('syncProgress: $arr');
        gotItems = int.parse(arr[0]); // Must be parsed correctly
        allItems = int.parse(arr[1]);
        break;
      case SyncNotify.addError:
        errorsDuringSync.add(note.body!);
        break;
    }
    notifyListeners();
  }

  Future<String> _interruptCallback(String s) async {
    logger.log('_interruptCallback arg=$s');
    if (s == 'playlists_conflict') {
      String? syncPriority = await showDialog<String>(
        context: navigatorKey.currentContext!,
        barrierDismissible: false,
        builder: (context) => const PopScope(
          canPop: false,
          child: PriorityDialog(),
        ),
      );
      logger.log('syncPriority=$syncPriority');

      if (syncPriority == null) {
        return SyncPriority.none;
      }
      return syncPriority;
    } else {
      assert(false, 'Wrong branch');
      return ''; // to shut up compiler
    }
  }

  void _wsConnectHandler() {
    // _setPairCandidate(p); // NOTICE: technically should be used here
    _printPairCandidates();
    notifyListeners();
  }

  void _wsCloseHandler() async {
    // curr wsChannel closed, cancelPairing
    _unsetChosenCandidate();

    _printPairCandidates();
    notifyListeners();
  }

  late Timer _checkPairTimer;

  // Removes candidates when they are not responding and etc.
  void _checkPairCandidates() async {
    // NOTICE: only an optimization trick. Doesn't change logic
    if (_syncing.wsHandler.isConnectionOpenOrConnecting()) {
      // Don't check if we already have a connection with a pair
      // logger.log('No check');
      return;
    }
    // logger.log('check');
    var copy = pairCandidates.toList();
    bool wasCopyUpdated = false;
    for (int i = copy.length - 1; i >= 0; i--) {
      // Check for accept time expiration
      var pairCandidate = copy[i];
      if (pairCandidate.requestedAt != 0 && !pairCandidate.isAcceptState) {
        // Change accept state to pair
        pairCandidate.setToPairState();
        wasCopyUpdated = true;
      }

      // Check for pair info time expiration
      int now = DateTime.now().millisecondsSinceEpoch;
      int candidateTimestamp = copy[i].lastTimestamp;
      if (candidateTimestamp < now - CONFIG.udpBroadcastExpirationMs) {
        copy.removeAt(i);
        wasCopyUpdated = true;
      }
    }
    if (wasCopyUpdated) {
      pairCandidates = copy;
      notifyListeners();
    }
  }

  static final Logger logger = Logger(prefix: 'NetworkState: ');
}
