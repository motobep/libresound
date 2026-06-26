import 'dart:async';
import 'dart:isolate';

import 'package:music_player/logger.dart';

typedef CallMessage = (int id, (String fnName, dynamic args));

class IsolateMessager {
  final SendPort _mainSendPort;
  final ReceivePort _mainReceivePort;
  final Map<int, Completer<Object?>> _activeRequests = {};
  int _mainIdCounter = 0;
  bool _closed = false;

  Function(Object?)? handleIsolateRequest;

  Future<Object?> call(String fnName, List args) async {
    if (_closed) throw StateError('Closed');
    final completer = Completer<Object?>.sync();
    final id = _mainIdCounter++;
    _activeRequests[id] = completer;

    _mainSendPort.send((id, (fnName, args)));

    return await completer.future;
  }

  static Future<IsolateMessager> spawn(void Function(SendPort) func,
      Function(Object?) handleIsolateRequest) async {
    // Create a initial raw receive port
    final initPort = RawReceivePort();
    final connection = Completer<(ReceivePort, SendPort)>.sync();
    initPort.handler = (initialMessage) {
      final mainSendPort = initialMessage as SendPort;
      connection.complete((
        ReceivePort.fromRawReceivePort(initPort),
        mainSendPort,
      ));
    };

    // Spawn the isolate.
    try {
      await Isolate.spawn(func, (initPort.sendPort));
    } on Object {
      initPort.close();
      rethrow;
    }

    // Init a receive, send ports
    final (ReceivePort mainReceivePort, SendPort mainSendPort) =
        await connection.future;

    return IsolateMessager._(
        mainReceivePort, mainSendPort, handleIsolateRequest);
  }

  IsolateMessager._(
      this._mainReceivePort, this._mainSendPort, this.handleIsolateRequest) {
    _mainReceivePort.listen(_handleResponsesFromIsolate);
  }

  void _handleResponsesFromIsolate(dynamic message) async {
    final (int id, payload) = message as (int, dynamic);
    // Negative id for handling requests from slave isolate
    // logger.blue('handleIsolateRequest: $message');
    if (id < 0) {
      // logger.blue('handleIsolateRequest: $message');
      var data = handleIsolateRequest?.call(payload);
      // logger.blue('\tdata: $data');
      if (data is Future) {
        data = await data;
        // logger.blue('\tdata from future: $data');
      }
      _mainSendPort.send((id, ('handledResponse', data)));
      // logger.blue('\tsent');
      return;
    }

    final completer = _activeRequests.remove(id)!;
    if (payload is RemoteError) {
      completer.completeError(payload);
    } else {
      completer.complete(payload);
    }
    if (_closed && _activeRequests.isEmpty) _mainReceivePort.close();
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _mainSendPort.send('shutdown');
    if (_activeRequests.isEmpty) _mainReceivePort.close();
    logger.log('--- port closed --- ');
  }

  final Logger logger = Logger(prefix: 'IsolateMessager: ');
}
