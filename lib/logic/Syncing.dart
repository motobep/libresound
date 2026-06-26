import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logger.dart';
import 'package:music_player/logic/udp/UdpHandler.dart';
import 'package:music_player/logic/ws/WsHandler.dart';
import 'package:music_player/logic/enums.dart';
import 'package:music_player/logic/UiNotification.dart';
import 'package:music_player/logic/ws/helpers.dart' as ws_helpers;

class Syncing {
  Syncing(this.udpHandler, this.wsHandler, {this.name = ''});
  UdpHandler udpHandler;
  WsHandler wsHandler;
  String name;

  bool isNetworkActivated = false;

  Future<void> activateNetwork() async {
    assert(!isNetworkActivated);

    trace('starting wsServer');
    await wsHandler.startServer();
    trace('starting udpHandler');
    await udpHandler.start(wsHandler.serverPort);
    trace('broadcastSelfInfo');
    udpHandler.startBroadcastSelfInfo();
    isNetworkActivated = true;
  }

  Future<void> deactivateNetwork() async {
    assert(isNetworkActivated);

    udpHandler.stopBroadcastSelfInfo();
    udpHandler.close();

    if (wsHandler.isConnectionOpenOrConnecting())
      await wsHandler.closeCurrChannel();
    await wsHandler.stopServer();
    isNetworkActivated = false;
  }

  void log(s) {
    gLogger.log(' 🔁 Syncing [$name]: $s');
  }

  void trace(s, {String color = ''}) {
    if (CONFIG.logLevel == LogLevel.trace) {
      log(s);
    }
  }
}

Future<void> useWsServer(String testDirServer) async {
  WsHandler wsServer =
      WsHandler.test(CONFIG.devIP, () => ws_helpers.pivotD(testDirServer),
          notifyUiCallback: (UiNotification n) {
    // logger.log('TEST: Client Notification: $n');
  }, interruptCallback: (String s) async {
    gLogger.log('--------\nServer interrupt - $s');
    return SyncPriority.none;
  });
  UdpHandler udpServer = UdpHandler(
    ipSelf: CONFIG.devIP,
    multicastIp: CONFIG.multicastIp,
    multicastUdpPort: CONFIG.udpPort,
    deviceName: 'Server test machine',
    addPairCandidateCallback: (p) {},
    pairRequestHandler: (ip, port) {
      wsServer.connect(ip, port);
    },
    loggingName: 'Test Server',
  );
  var syncingServer = Syncing(udpServer, wsServer, name: 'Server');

  await syncingServer.activateNetwork();
}

final Logger logger = Logger(prefix: 'Syncing: ');
