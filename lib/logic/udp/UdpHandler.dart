import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/consts.dart' show APP_MSG_PREFIX;
import 'package:music_player/logger.dart';
import 'package:music_player/logic/PairCandidate.dart';
import 'package:music_player/logic/enums.dart';

import 'helpers.dart' show makeJsonEncoded;

class UdpHandler {
  UdpHandler({
    required this.ipSelf,
    required this.multicastIp,
    required this.multicastUdpPort,
    required this.deviceName,
    required this.addPairCandidateCallback,
    this.pairRequestHandler,
    this.setNetworkError,
    this.loggingName = '',
  });

  String ipSelf;
  String multicastIp;
  int multicastUdpPort;
  late int wsPort;
  String deviceName;
  void Function(PairCandidate) addPairCandidateCallback;
  void Function(String ip, int port)? pairRequestHandler;
  void Function(NetworkError)? setNetworkError;

  RawDatagramSocket? udpSocket;

  String loggingName;

  bool _isBroadCastInfo = false;

  Future<void> start(int wsPort) async {
    this.wsPort = wsPort;
    await bind();
    listenBroadcast();
  }

  Future<void> bind() async {
    var ia = InternetAddress(multicastIp);
    udpSocket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, multicastUdpPort);
    udpSocket!.joinMulticast(ia);
    udpSocket!.multicastHops = 5;
  }

  bool listenBroadcast([void Function(Uint8List bytes)? additionalListener]) {
    if (udpSocket == null) return false;

    try {
      udpSocket!.listen((RawSocketEvent e) {
        String eventStr = e.toString();

        switch (eventStr) {
          case 'RawSocketEvent.read':
            // trace('read event');
            break;
          case 'RawSocketEvent.write':
            trace('write event');
            break;
          case 'RawSocketEvent.readClosed':
            trace('readClosed event');
            break;
          case 'RawSocketEvent.closed':
            trace('closed event');
            break;
          default:
            log('Unexpected event value');
        }

        Datagram? dg = udpSocket!.receive();
        if (dg != null) {
          _broadcasLitener(dg.data);
          if (additionalListener != null) {
            additionalListener(dg.data);
          }
        } else {
          // log('dg null');
        }
      }, onError: (e) {
        // Error occured: SocketException: Send failed (OS Error: Network is unreachable, errno = 101),
        log('Error occured: $e');
        log('Setting NetworkError.networkUnreachable');
        setNetworkError?.call(NetworkError.networkUnreachable);
      }, cancelOnError: true);
    } catch (e) {
      log('Already in use: $e');
      return false;
    }
    return true;
  }

  void close() {
    udpSocket?.close();
  }

  void startBroadcastSelfInfo() async {
    _isBroadCastInfo = true;
    while (_isBroadCastInfo) {
      broadcastSelfInfo();
      await Future.delayed(
          const Duration(milliseconds: CONFIG.udpBroadcastDelayMs));
    }
  }

  void stopBroadcastSelfInfo() {
    _isBroadCastInfo = false;
  }

  void sendBroadcast(List<int> data) {
    _sendMulticast(data);
  }

  void _sendMulticast(List<int> data) {
    InternetAddress ia = InternetAddress(multicastIp);
    udpSocket?.send(data, ia, multicastUdpPort);
  }

  void broadcastSelfInfo() {
    var obj = {
      'type': 'INFO',
      'ip': ipSelf,
      'udp_port': multicastUdpPort,
      'ws_port': wsPort,
      'name': deviceName
    };
    var data = makeJsonEncoded(obj);
    sendBroadcast(data);
  }

  // Might not reach destination. Make multiple requests
  void sendPairRequest(String destIp, int destPort) {
    var obj = {
      'type': 'PAIR_REQUEST',
      'ip': ipSelf,
      'udp_port': multicastUdpPort,
      'ws_port': wsPort,
    };

    trace('Pair Request to $destIp:$destPort');
    trace(obj);
    var data = makeJsonEncoded(obj);

    _sendMulticast(data);
  }

  void _broadcasLitener(Uint8List bytes) {
    String data = utf8.decode(bytes);
    // trace('Received: $data');

    const String validationStr = '$APP_MSG_PREFIX:json:{"';
    if (!data.contains(validationStr)) return;

    const String startOfMsg = '$APP_MSG_PREFIX:json:';
    String encoded = data.substring(startOfMsg.length);
    Map obj = jsonDecode(encoded) as Map;
    if (!obj.containsKey('type')) return;

    switch (obj['type']) {
      case 'INFO':
        _infoHandle(obj);
        break;
      case 'PAIR_REQUEST':
        if (_isSelf(obj['ip'], obj['ws_port'])) {
          trace('Self PAIR_REQUEST. Decline');
          return;
        }

        String ip = obj['ip'];
        int port = obj['ws_port'] as int;

        if (pairRequestHandler != null) {
          pairRequestHandler!(ip, port);
        }
        break;
    }
  }

  void _infoHandle(Map obj) {
    if (!obj.containsKey('ip') ||
        !obj.containsKey('udp_port') ||
        !obj.containsKey('ws_port') ||
        !obj.containsKey('name')) return;

    String deviceName = obj['name'];
    String ip = obj['ip'];
    int ws_port = obj['ws_port'];
    int udp_port = obj['udp_port'];

    if (_isSelf(obj['ip'], obj['ws_port'])) {
      // log('Same device');
    } else {
      // log('Client device');
      // Add device
      addPairCandidateCallback(
          PairCandidate(deviceName, ip, ws_port, udp_port));
    }
  }

  bool _isSelf(String ip, int ws_port) {
    return ip == ipSelf && ws_port == wsPort;
  }

  void log(s) {
    if (loggingName != '') {
      gLogger.log(' 📦 UDP [$loggingName]: $s');
      return;
    }
    gLogger.log(' 📦 UDP: $s');
  }

  void trace(s) {
    if (CONFIG.logLevel == LogLevel.trace) {
      log('(trace) $s');
    }
  }
}
