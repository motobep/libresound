import 'dart:async' show Completer, Timer;
import 'dart:convert' show utf8;
import 'dart:io';
import 'dart:isolate' show ReceivePort, RemoteError, SendPort;

import 'package:flutter/services.dart' show PlatformException, rootBundle;
import 'package:flutter_js/flutter_js.dart';
import 'package:music_player/config.dart' as CONFIG;

import 'package:music_player/logger.dart';
import 'package:music_player/logic/BytesFetcher.dart';
import 'package:music_player/logic/IsolateMessager.dart';
import 'package:music_player/logic/utils.dart'
    show atob, btoa, sanitizeWithTicks;

class DartJsProxy implements JsRuntimeI {
  late IsolateMessager messager;
  late MpJsRuntime runtime;

  Map<String, dynamic> mainThreadFuncs = {};

  DartJsProxy.self(String name) {
    runtime = MpJsRuntime(name: name);
  }

  handleIsolateRequest(Object? response) {
    // gLogger.blue('handle isolate request');
    final (String fnName, args) = response as (String, dynamic);
    return mainThreadFuncs[fnName](args);
  }

  @override
  Future<void> initAsync(List<(String, String)> libs) async {
    var func = makeIsolateHandler((fnName, args, isolateSendPort) {
      return runJs(
          fnName: fnName,
          args: args,
          runtime: runtime,
          isolateSendPort: isolateSendPort);
    });
    messager = await IsolateMessager.spawn(func, handleIsolateRequest);
    await messager.call('initAsync', [libs]);
  }

  @override
  Future<dynamic> runCodeInAsyncFunc(String code) async {
    return (await messager.call('runCodeInAsyncFunc', [code]));
  }

  @override
  Future<dynamic> onMessage(
      String channelName, dynamic Function(dynamic args) fn) async {
    mainThreadFuncs[channelName] = fn;
    return (await messager.call('onMessage', [channelName]));
  }

  @override
  Future<bool> loadPlugin(String path) async {
    return (await messager.call('loadPlugin', [path])) as bool;
  }

  @override
  Future<bool> loadPluginFromAssets(String path) async {
    return (await messager.call('loadPluginFromAssets', [path])) as bool;
  }

  void dispose() {
    messager.close();
  }
}

final Map<int, Completer<Object?>> _activeResponses = {};
int _isolateIdCounter = -1;

void Function(SendPort) makeIsolateHandler(
    Future<dynamic> Function(String fnName, dynamic args, SendPort sendPort)
        func) {
  return (SendPort isolateSendPort) {
    // Bind ports
    final isolateReceivePort = ReceivePort();
    isolateSendPort.send(isolateReceivePort.sendPort);

    // Handle commands
    isolateReceivePort.listen((message) async {
      try {
        // gLogger.blue('handle command: $message');
        if (message == 'shutdown') {
          isolateReceivePort.close();
          return;
        }
        final (int id, payload) = message as CallMessage;
        if (id < 0) {
          // Finish request to main isolate
          // gLogger.blue('Finish request ($id, $payload)');
          final data = payload.$2;
          final completer = _activeResponses.remove(id)!;
          if (payload is RemoteError) {
            completer.completeError(data);
          } else {
            completer.complete(data);
          }
          return;
        }

        final (String fnName, List args) = payload;
        try {
          final data = await func(fnName, args, isolateSendPort);
          isolateSendPort.send((id, data));
        } catch (e, s) {
          // gLogger.exception('Error in isolate', e, s);
          gLogger.error('Error in isolate. Sending RemoteError');
          isolateSendPort.send((id, RemoteError(e.toString(), '')));
        }
      } catch (e, stacktrace) {
        gLogger.error('Error in isolate listener: $e\n$stacktrace');
      }
    });
  };
}

Future<dynamic> runJs(
    {required String fnName,
    required dynamic args,
    required MpJsRuntime runtime,
    required SendPort isolateSendPort}) async {
  // gLogger.log('runJs $fnName');
  // gLogger.blue('runtime [$fnName] code=${runtime.hashCode}');
  // print('args: $args');
  if (fnName == 'runCodeInAsyncFunc') {
    // executePendingJob?
    // gLogger.log('args: $args');
    // handlePromise
    try {
      return await runtime.runCodeInAsyncFunc(args[0]);
    } catch (e, s) {
      // gLogger.exception('runJs', e, s);
      gLogger.error('runJs Exception rethrow');
      rethrow;
    }
  } else if (fnName == 'onMessage') {
    return await runtime.onMessage(args[0], (data) async {
      final completer = Completer<Object?>.sync();
      final id = _isolateIdCounter--;
      _activeResponses[id] = completer;
      // gLogger.blue('Calling: ($id) ${args[0]} - $data');
      isolateSendPort.send((id, (args[0], data)));

      var val = await completer.future;
      // gLogger.blue('val: ($id) ${args[0]} - $val');
      return val;
    });
  } else if (fnName == 'initAsync') {
    var val = await runtime.initAsync(args[0]);
    // gLogger.blue('HIP HOP');
    return val;
  } else if (fnName == 'loadPlugin') {
    var val = await runtime.loadPlugin(args[0]);
    return val;
  } else if (fnName == 'loadPluginFromAssets') {
    var val = await runtime.loadPluginFromAssets(args[0]);
    return val;
  } else if (fnName == 'handledResponse') {
    var val = 'yo';
    print('val: $val');
    return val;
  } else {
    throw Exception('Unknown function name: "$fnName"');
  }
}

abstract class JsRuntimeI {
  /// Throws
  Future<dynamic> runCodeInAsyncFunc(String code);
  Future<dynamic> onMessage(
      String channelName, dynamic Function(dynamic args) fn);

  Future<void> initAsync(List<(String, String)> libs);

  Future<bool> loadPlugin(String path);
  Future<bool> loadPluginFromAssets(String path);
}

class MpJsRuntime implements JsRuntimeI {
  late JavascriptRuntime flutterJs =
      getJavascriptRuntime(hostPromiseRejectionHandler: (err) async {
    logger.error('Unhandled promise rejection');
    if (err is JSError) {
      JSError jsError = err;
      String code = '<unknown>';
      await _runJsCodeAsync('''// js
        (async function() {
            let e = {
              message: `${sanitizeWithTicks(jsError.message)}`,
              stack: `${sanitizeWithTicks(jsError.stack)}`,
            }
            let c = `${sanitizeWithTicks(code)}`
            let newErr = await musicPlayer.runtime.addMappingsToErrorAsync(e, c)
            musicPlayer.runtime.logger.error(newErr.message + '\\n' + newErr.stack)
        })()
    ''', sourceUrl: '<MpJsRuntime.dart eval async>');
    } else {
      logger.error('Unhandled promise rejection: [${err.runtimeType}] $err');
    }
  });

  String name;

  MpJsRuntime({
    required this.name,
  }) : logger = Logger(prefix: '📘 MpJsRuntime [$name]: ');
  final Logger logger;

  @override
  Future<void> initAsync(List<(String, String)> libs) async {
    for (var (String path, String contents) in libs) {
      await _loadLib(path, contents);
    }
    await _initMpFuncsAsync();
    _setupSetTimeout();
    _setupClearTimeout();
  }

  Future<void> _loadLib(String path, String execStr) async {
    try {
      var res = flutterJs.evaluate(execStr, sourceUrl: path);
      if (res.isError) {
        logger.error('Load lib [$path] error: ${res.stringResult}');
      } else {
        // logger.log('Load lib [$path] output: ${res.stringResult}');
      }
    } catch (e) {
      logger.error('ERROR while loading [${path}]: $e');
    }
  }

  /// Runs code in async closure
  /// Throws
  @override
  Future<dynamic> runCodeInAsyncFunc(String code) async {
    var wrappedCode = '''// js
        (async function() {
        try {
					$code
        } catch(e) {
          let newErr = await musicPlayer.runtime.addMappingsToErrorAsync(e, `${sanitizeWithTicks(code)}`)
          // musicPlayer.runtime.logger.error(newErr.message + '\\n' + newErr.stack)
          throw newErr
        }
        })();
    ''';
    // logger.log(wrappedCode);
    return await _runJsCodeAsync(wrappedCode,
        sourceUrl: '<MpJsRuntime.dart eval async>');
  }

  /// Throws
  Future<dynamic> _runJsCodeAsync(String code, {String? sourceUrl}) async {
    try {
      var res = await flutterJs.evaluateAsync(code, sourceUrl: sourceUrl);
      final prom = await flutterJs.handlePromise(res,
          timeout: const Duration(seconds: CONFIG.promiseTimeout));
      var result = await prom.rawResult;
      // logger.blue('Promise result (${result.runtimeType}): $result');
      // flutterJs.executePendingJob();
      if (result is JSError) {
        logger.error('JSError: $result');
      }
      return result;
    } on PlatformException catch (e) {
      logger.error('Platform exception [runJsCodeAsync]: ${e.details}');
      rethrow;
    } catch (e) {
      // logger.error('Exception [runJsCodeAsync]: rethrow: ${e}');
      logger.error('Exception [runJsCodeAsync]: rethrow');
      rethrow;
    }
  }

  dynamic runJsCodeSync(String code) {
    try {
      var res = flutterJs.evaluate(code, sourceUrl: '<MpJsRuntime.dart eval>');
      var result = res.rawResult;
      if (result is JSError) {
        logger.error(result);
      }
      return result;
    } on PlatformException catch (e) {
      logger.error('Platform exception: ${e.details}');
      rethrow;
    } catch (e) {
      logger.error('ERROR [runJsCodeSync]');
      rethrow;
    }
  }

  @override
  Future<bool> loadPlugin(String path) async {
    var f = File(path);
    String libStr = f.readAsStringSync();
    return await _executeAsyncLibAsync(libStr, sourceUrl: path);
  }

  @override
  Future<bool> loadPluginFromAssets(String path) async {
    String libStr = await rootBundle.loadString(path);
    return await _executeAsyncLibAsync(libStr, sourceUrl: path);
  }

  // Private funcs
  Future<bool> _executeAsyncLibAsync(String libStr, {String? sourceUrl}) async {
    try {
      var promise = await flutterJs.evaluateAsync(libStr, sourceUrl: sourceUrl);
      flutterJs.executePendingJob();
      var res = await flutterJs.handlePromise(
        promise,
      );
      flutterJs.executePendingJob();
      if (res.isError) {
        await _runJsCodeAsync('''// js
        (async function() {
            var logger = musicPlayer.logger
            var mapper = musicPlayer.runtime._mapper
            let err = '[Error placeholder]'
            try {
              err = `${sanitizeWithTicks(res.stringResult)}`
              let stack = await mapper.mapStacktraceAsync(err)
              logger.error('Error in plugin lib code (_executeAsyncLibAsync):',
                '' + stack);
            } catch(mappingErr) {
              logger.warn('Mapping Error (_executeAsyncLibAsync)', mappingErr.message + '\\n' + mappingErr.stack);
              logger.error('Error in plugin code:', err);
            }
        })();
        ''', sourceUrl: '<_executeAsyncLibAsync map error eval>');
        return false;
      }
      // log('Load lib output: ${prom.stringResult}');
    } catch (e) {
      logger.log('ERROR while loading js lib: $e');
      return false;
    }
    return true;
  }

  @override
  Future<dynamic> onMessage(
      String channelName, dynamic Function(dynamic args) fn) async {
    return await flutterJs.onMessage(channelName, fn);
  }

  Future<void> _initMpFuncsAsync() async {
    flutterJs.onMessage('atob', (arg) {
      return atob(arg);
    });
    flutterJs.onMessage('btoa', (arg) {
      return btoa(arg);
    });

    Map<String, Function(dynamic)> funcs = {
      'fetch': (args) async {
        String url;
        Map<String, dynamic> options = args['options'] ?? {};
        // logger.blue('initial options: $options');
        // logger.blue('args url: ${args['url'].runtimeType} | ${args['url']}');
        if (args['url'] is! String && args['url'] is Map) {
          var request = args['url'];
          url = request['url'];
          if (request['method'] != null) {
            options['method'] = request['method'];
          }
          Map? reqHeaders = request['headers'];
          if (reqHeaders != null && reqHeaders.containsKey('map')) {
            if (options['headers'] == null) {
              options['headers'] = {};
            }
            reqHeaders['map'].forEach((k, v) {
              options['headers'][k.toLowerCase()] = v;
            });
            if (request['referrer'] != null) {
              options['headers']['referrer'] = request['referrer'];
            }
          }
        } else {
          url = args['url'];
        }
        return await _MP_fetch(url, options);
      },
      'runtime.fs.readFile': (args) async {
        var f = File(args['path']);
        return await f.readAsString();
      },
      'runtime.fs.existsSync': (args) {
        var f = File(args['path']);
        return f.existsSync();
      },
      'runtime.fs.readFileSync': (args) {
        var f = File(args['path']);
        return f.readAsStringSync();
      },
      'getProxyConfig': (_) {
        return _proxyConfig;
      },
      'setProxyConfig': (env) {
        logger.blue('setProxyConfig: $env');
        _proxyConfig = env?.cast<String, String>();
      },
      'isTls1_3_set': (b) {
        logger.blue('isTls1_3: $b');
        _isTls1_3 = b;
      },
      'isTls1_3_get': (_) {
        return _isTls1_3;
      },
      'uint8ListToString': (list) async {
        return _MP_uint8ListToString(list);
      },
      'BytesFetcher.new': (args) {
        var fetcher = BytesFetcher(proxy: _proxyConfig, isTls1_3: _isTls1_3);
        int id = _fetchersCounter++;
        _fetchers[id] = fetcher;
        return id;
      },
      'BytesFetcher.delete': (args) {
        var fetcher = _fetchers.remove(args['id']);
        return fetcher;
      },
      'BytesFetcher.fetch': (args) async {
        return await _fetchers[args['id']]!.fetch(args['url'], args['options']);
      },
      'BytesFetcher.abort': (args) {
        _fetchers[args['id']]!.abort();
      },
      'logger.logGeneral': (o) {
        gLogger.log(o['s'], o['color']);
      },
    };

    for (var entry in funcs.entries) {
      await MP(entry.key, entry.value);
    }
  }

  Map<String, String>? _proxyConfig;
  bool _isTls1_3 = false;

  final Map<int, BytesFetcher> _fetchers = {};
  int _fetchersCounter = 0;

  Future<dynamic> MP(
      String channelName, dynamic Function(dynamic args) fn) async {
    return await onMessage('MP.${channelName}', fn);
  }

  Future<Map<String, dynamic>> _MP_fetch(
      String url_str, Map<String, dynamic> options) async {
    return await BytesFetcher(proxy: _proxyConfig, isTls1_3: _isTls1_3)
        .fetch(url_str, options);
  }

  String _MP_uint8ListToString(List<dynamic> list) {
    // logger.log('_MP_unit8ListToString');
    return utf8.decode(list.cast<int>());
  }

  void _setupSetTimeout() {
    flutterJs.evaluate("""// js
      var __NATIVE_FLUTTER_JS__setTimeoutCount = -1;
      var __NATIVE_FLUTTER_JS__setTimeoutCallbacks = {};
        // console.log('Set Timeout register');
      function setTimeout(fnTimeout, timeout) {
        // console.log('Set Timeout Called');
        try {
        __NATIVE_FLUTTER_JS__setTimeoutCount += 1;
          var timeoutIndex = '' + __NATIVE_FLUTTER_JS__setTimeoutCount;
          __NATIVE_FLUTTER_JS__setTimeoutCallbacks[timeoutIndex] =  fnTimeout;
          ;
          __dartjs_sendMessage('mySetTimeout', JSON.stringify({ timeoutIndex, timeout}));
					return timeoutIndex;
        } catch (e) {
          musicPlayer.runtime.logger.error('ERROR',e.message);
        }
      };
      1
    """);
    flutterJs.onMessage('mySetTimeout', (dynamic args) {
      // logger.blue('setTimeout');
      try {
        int duration = args['timeout'] ?? 0;
        String idx = args['timeoutIndex'];

        Timer(Duration(milliseconds: duration), () async {
          try {
            var timeout_res = await _runJsCodeAsync('''// js
          // musicPlayer.runtime.logger.blue('calling callback', '$idx');
            var prom = (async () => {
            await __NATIVE_FLUTTER_JS__setTimeoutCallbacks[$idx].call();
            })();
          // musicPlayer.runtime.logger.blue('deleting callback', '$idx');
            delete __NATIVE_FLUTTER_JS__setTimeoutCallbacks[$idx];
            prom
          ''');
          } catch (e, s) {
            logger.exception('during setTimeout', e, s);
          }

          // logger.blue('timeout_res: ${timeout_res}');
        });
      } on Exception catch (e) {
        logger.log('Exception no setTimeout: $e');
      } catch (e, s) {
        logger.exception('setting timeout', e, s);
      }
    });
  }

  void _setupClearTimeout() {
    flutterJs.evaluate("""// js
      function clearTimeout(timeoutIndex) {
        // console.log('Clear Timeout Called');
        try {
          __dartjs_sendMessage('clearTimeout', JSON.stringify({ timeoutIndex }));
        } catch (e) {
          musicPlayer.runtime.logger.error('ERROR',e.message);
        }
      };
    """);

    flutterJs.onMessage('clearTimeout', (dynamic args) {
      logger.blue('clearTimeout');
      try {
        String idx = args['timeoutIndex'];

        flutterJs.evaluate('''
					delete __NATIVE_FLUTTER_JS__setTimeoutCallbacks[$idx];
				''');
      } on Exception catch (e) {
        logger.log('Exception no clearTimeout: $e');
      } on Error catch (e) {
        logger.log('Erro no clearTimeout: $e');
      }
    });
  }
}

class MpNothingToDownloadException implements Exception {
  String message;
  MpNothingToDownloadException(this.message);
  @override
  String toString() => 'MpNothingToDownloadException: $message';
}
