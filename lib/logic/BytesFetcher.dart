import 'dart:async' show StreamIterator;
import 'dart:io';
import 'dart:typed_data' show Uint8List;

import 'package:flutter/foundation.dart'
    show consolidateHttpClientResponseBytes;
import 'package:music_player/logger.dart';
import 'package:music_player/logic/network.dart' show makeHttpClient;

class BytesFetcher<T> {
  BytesFetcher({this.onBytesRecived, this.proxy, this.isTls1_3 = false});

  HttpClientRequest? request;
  void Function(int, int)? onBytesRecived;
  Map<String, String>? proxy;
  bool isTls1_3;

  bool _shouldAbort = false;
  double _fraction = 0;

  StreamIterator<List<int>>? _chunkIter;
  // int _counter = 0;

  void abort() {
    logger.log('Called abort()');
    _shouldAbort = true;
    request?.abort();
    if (_chunkIter != null) {
      logger.log('Cancelling _chunkIter');
      _chunkIter!.cancel();
    }
  }

  /// Throws
  Future<Map<String, dynamic>> fetch(
      String url_str, Map<String, dynamic> options) async {
    // logger.log('fetch: "$url_str"');
    try {
      if (_shouldAbort) {
        throw MpAbortException('fetch aborted');
      }
      request = await _makeHttpClientRequest(url_str, options,
          proxy: proxy, isTls1_3: isTls1_3);
      final HttpClientResponse response = await request!.close();
      return _makeResponseObj(
        response,
        getBytes: () async {
          // logger.log('> Calling fetchBytes in fetch() <');
          List<int> val = (await fetchBytes(response)).cast<int>();
          // logger.log('val: ${val.length}');
          return val;
        },
        getChunk: () async {
          logger.log('> Calling fetchChunk in fetch() <');
          final val = (await fetchChunk(response));
          logger.log('val: ${val?.length}');
          return val;
        },
        abort: abort,
      );
    } catch (e, s) {
      logger.exception('fetch error', e, s);
      rethrow;
    }
  }

  /// Throws exception.
  /// If bytes returned, then response is not null
  Future<Uint8List> fetchBytes(HttpClientResponse response) async {
    // logger.log('fetchBytes');
    try {
      var bytes = await consolidateHttpClientResponseBytes(response,
          onBytesReceived: (bytesReceived, expectedContentLength) {
        if (expectedContentLength != null) {
          var per = bytesReceived / expectedContentLength;
          if (per - _fraction >= 0.05) {
            _fraction = per;
            // logger.log('Fetched: ${(_fraction * 100).round()} %');
            onBytesRecived?.call(bytesReceived, expectedContentLength);
          }
        }
        if (_shouldAbort) {
          throw MpAbortException('consolidateHttpClientResponseBytes aborted');
        }
      });
      return bytes;
    } catch (e, stacktrace) {
      logger.exception('fetchBytes Exception', e, stacktrace);
      rethrow;
    }
  }

  /// Throws (maybe)
  Future<Uint8List?> fetchChunk(HttpClientResponse response) async {
    // log('----- Counter: ${_counter++}');
    try {
      _chunkIter ??= StreamIterator<List<int>>(response);
      if (await _chunkIter!.moveNext()) {
        return Uint8List.fromList(_chunkIter!.current);
      }
      return null;
    } catch (e, stacktrace) {
      logger.exception('fetchChunk Exception', e, stacktrace);
      rethrow;
    }
  }
}

final Logger logger = Logger(prefix: 'BytesFetcher: ');

class MpAbortException implements Exception {
  String message;
  MpAbortException(this.message);
  @override
  String toString() => 'MpAbortException: $message';
}

Future<HttpClientRequest> _makeHttpClientRequest(
    String url_str, Map<String, dynamic> options,
    {Map<String, String>? proxy, required bool isTls1_3}) async {
  Uri url = Uri.parse(url_str);
  String method = options.containsKey('method') ? options['method'] : 'GET';
  // TODO: Use one client
  gLogger.debug('($method, $url, $options)');
  // var client = HttpClient();
  var client = makeHttpClient(proxy: proxy, isTls1_3: isTls1_3);
  final request = await client.openUrl(method.toUpperCase(), url);
  // gLogger.blue('_addOptionsToRequest');
  _addOptionsToRequest(request, options);
  return request;
}

void _addOptionsToRequest(HttpClientRequest request, Map options) {
  if (options.containsKey('headers')) {
    Map<String, dynamic> headers = Map.castFrom(options['headers']);
    headers.forEach((k, v) {
      request.headers.add(k.toLowerCase(), v);
    });
  }

  if (options.containsKey('body')) {
    String body = options['body'];
    request.write(body);
  }
}

Map<String, dynamic> _makeResponseObj(
  HttpClientResponse response, {
  required Future<List<int>> Function() getBytes,
  required Future<Uint8List?> Function() getChunk,
  required void Function() abort,
}) {
  Map<String, String> headersMap = {};
  response.headers.forEach((name, values) {
    var s = values.toString(); // gets array of values
    var val =
        s.substring(1, s.length - 1); // removes brackets from array string
    headersMap[name] = val;
  });

  final List<String> cookies =
      response.cookies.map((c) => c.toString()).toList();
  return {
    'status': response.statusCode,
    'ok': response.statusCode >= 200 && response.statusCode < 300,
    'cookies': cookies,
    'location': response.headers.value('location'),
    'headers': headersMap,
    'getBytes': getBytes,
    'getChunk': getChunk,
    'abort': abort,
  };
}
