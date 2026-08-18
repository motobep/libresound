import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

import 'package:music_player/consts.dart' as CONSTS;
import 'package:music_player/config.dart' as CONFIG;

String? logFilepath;

class Logger {
  String prefix;

  bool isAssertLogFile = false;
  int _fileCheck = 0;
  Logger({this.prefix = ''}) {
    assert(!isAssertLogFile || logFilepath != null,
        'logFilepath must not be null');
  }

  static setLogLevels({
    bool? isLogToFile,
    bool? isLogDebug,
    bool? isLogTrace,
    bool? isLogView,
    bool? isLogBuild,
  }) {
    Logger.isLogToFile = isLogToFile ?? Logger.isLogToFile;
    Logger.isLogDebug = isLogDebug ?? Logger.isLogDebug;
    Logger.isLogTrace = isLogTrace ?? Logger.isLogTrace;
    Logger.isLogView = isLogView ?? Logger.isLogView;
    Logger.isLogBuild = isLogBuild ?? Logger.isLogBuild;
  }

  void log(s, [String color = '']) {
    assert(!isAssertLogFile || logFilepath != null,
        'logFilepath must not be null');

    final str = '$prefix${CONSTS.colorMap[color]}$s\x1B[0m';
    if (Platform.isLinux) {
      stdout.writeln(str);
    } else {
      print(str);
    }
    if (isLogToFile && logFilepath != null) {
      logToFile(str);
    }
  }

  void debug(s, [String color = 'blue']) {
    if (isLogDebug) {
      log('[DEBUG]: $s', color);
    }
  }

  void trace(s, [String color = '']) {
    if (isLogTrace) {
      log('[TRACE]: $s', color);
    }
  }

  void view(s, [String color = '']) {
    if (isLogView) {
      log('🌂 View: $s', color);
    }
  }

  void build(s, [String color = '']) {
    if (isLogBuild) {
      log('🏡 Build: $s', color);
    }
  }

  static bool isLogToFile = CONFIG.isLogToFile;
  static bool isLogDebug = CONFIG.isLogDebug;
  static bool isLogTrace = CONFIG.isLogTrace;
  static bool isLogView = CONFIG.isLogView;
  static bool isLogBuild = CONFIG.isLogBuild;

  void green(s) => log(s, 'green');
  void blue(s) => log(s, 'blue');
  void warn(s) => log(s, 'yellow');
  void error(s) => log(s, 'red');
  void exception(String preface, e, [stacktrace]) {
    if (stacktrace == null) {
      log('Exception ($preface): $e', 'red');
    } else {
      log('Exception ($preface): $e\nStacktrace: $stacktrace', 'red');
    }
  }

  void logToFile(String s) {
    final file = File(logFilepath!);
    final time = _nowFormatted();
    final str = '[$time] $s\n';
    try {
      file.writeAsStringSync(str, mode: FileMode.append);
    } catch (e) {
      stdout.writeln('Error writing to log file.\n\tError: $e');
    }

    _checkLogFile(file);
  }

  String _nowFormatted() {
    return _formatter.format(DateTime.now());
  }

  void _checkLogFile(File file) {
    if (_fileCheck == 0) {
      final l = file.lengthSync();
      if (l > CONFIG.maxLogFileSize) {
        final dir = path.dirname(file.path);
        file.renameSync('$dir/log_previous.txt');
      }
      _fileCheck = 50;
    }
    _fileCheck--;
  }
}

final DateFormat _formatter = DateFormat('yy-MM-dd_HH:mm:ss');

final Logger gLogger = Logger();
