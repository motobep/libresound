import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logger.dart';

class PairCandidate {
  PairCandidate(this.deviceName, this.ip, this.wsPort, this.udpPort);
  final String deviceName;
  final String ip;
  final int wsPort;
  final int udpPort;

  int lastTimestamp = DateTime.now().millisecondsSinceEpoch;

  // bool requested = false;
  int requestedAt = 0;

  bool get isAcceptState {
    int now = DateTime.now().millisecondsSinceEpoch;
    return requestedAt + CONFIG.udpPairRequestExpirationMs > now;
  }

  void setToAcceptState() {
    requestedAt = DateTime.now().millisecondsSinceEpoch;
  }

  void setToPairState() {
    requestedAt = 0;
  }

  @override
  bool operator ==(Object other) {
    return (other is PairCandidate &&
        deviceName == other.deviceName &&
        ip == other.ip &&
        wsPort == other.wsPort);
  }

  @override
  int get hashCode => Object.hash(deviceName, ip, wsPort);

  void show() {
    gLogger.log(
        'PairCandidate:\nDevice name: $deviceName\nIP: $ip\nWs port: $wsPort\nUdp port: $udpPort\nRequested: $isAcceptState');
  }
}
