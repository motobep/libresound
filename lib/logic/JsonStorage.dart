import 'dart:io';
import 'dart:convert';

import 'package:music_player/logger.dart';
import 'package:music_player/logic/KeyValue.dart';

/// Manages json file.
/// Creates file for given [filepath] in constructor if it doesn't exist.
/// **NOTICE**: constructor throws.
///
/// Main methods:
/// - [getProperty(String name)]
/// - [saveProperty(String name, dynamic value)]
class JsonStorage {
  final File _storageFile;
  KeyValue map = {};

  /// Manages json file.
  /// Creates file for given [filepath] in constructor if it doesn't exist.
  /// **NOTICE**: constructor throws.
  ///
  /// Main methods:
  /// - [getProperty(String name)]
  /// - [saveProperty(String name, dynamic value)]
  JsonStorage(String filepath) : _storageFile = File(filepath) {
    if (!_storageFile.existsSync()) {
      log('INFO: Creating config file');
      _storageFile.writeAsStringSync('{}');
    } else {
      String contents = _readConfig();
      map = jsonDecode(contents);
    }
  }

  JsonStorage.empty() : _storageFile = File('');

  dynamic getProperty(String propName) {
    return map.containsKey(propName) ? map[propName] : null;
  }

  bool saveProperty(String propName, dynamic propVal) {
    map[propName] = propVal;
    return saveConfig();
  }

  bool saveConfig() {
    String contents = json.encode(map);
    try {
      _storageFile.writeAsStringSync(contents);
    } catch (e) {
      log('WARN: Config file wasn\'t written');
      return false;
    }
    return true;
  }

  String _readConfig() {
    try {
      return _storageFile.readAsStringSync();
    } catch (e) {
      log('Exception while reading music file $e');
      return '';
    }
  }

  @override
  String toString() {
    return map.toString();
  }

  void log(s) {
    gLogger.log('JsonStorage: $s');
  }
}
