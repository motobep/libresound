import 'dart:io' show WebSocket;
import 'dart:typed_data';
import 'dart:convert';

import 'package:music_player/logger.dart';

import 'helpers.dart' as bytes_helpers;

class WsChannel {
  final WebSocket socket;
  final String type;

  static String serverType = 'server';
  static String clientType = 'client';

  WsChannel(this.socket, this.type);

  // Throws
  Future<void> close() async {
    assert(isOpenOrConnecting(),
        'Must call when open or connecting. readyState: ${socket.readyState}');
    gLogger.log('WsChannel: Closing channel');
    await _close();
  }

  bool isOpenOrConnecting() {
    // static const int connecting = 0;
    // static const int open = 1;
    // static const int closing = 2;
    // static const int closed = 3;
    int s = socket.readyState;
    return s == WebSocket.open || s == WebSocket.connecting;
  }

  // Throws
  Future _close([int? code, String? reason]) async {
    return await socket.close(code, reason);
  }

  /// Send json string
  /// Throws
  void sendAsJsonOld(dynamic obj) {
    String serialized = jsonEncode(obj);
    _sendAsString(serialized);
  }

  void sendAsBinary(Uint8List binary) {
    _send(binary);
  }

  void sendAsBinaryOld(Uint8List binary) {
    Uint8List payload = bytes_helpers.makePayloadFromBinary(binary);
    _send(payload);
  }

  void _sendAsString(String s) {
    Uint8List payload = bytes_helpers.makePayloadFromString(s);
    _send(payload);
  }

  void _send(dynamic val) {
    socket.add(val);
  }
}
