import 'dart:io';
import 'dart:convert';

import 'package:music_player/logger.dart';
import 'package:music_player/logic/KeyValue.dart';
import 'package:music_player/logic/lang.dart' as language;
import 'package:path/path.dart' as p;

enum PluginInfoStatus {
  loading,
  loaded,
  errored,
}

enum PluginPermissions {
  net,
  read,
  write;

  static PluginPermissions fromString(String s) {
    return PluginPermissions.values.firstWhere((e) => e.name == s, orElse: () {
      assert(false, 'Wrong name "$s"');
      throw 'Wrong name "$s"';
    });
  }
}

class PluginInfo {
  PluginInfo({
    required this.type,
    required this.options,
    required this.title,
    this.longtitle,
    this.descr,
    required this.version,
    required this.minimum_app_version,
    required this.permissions,
    this.langs,
    // ------------
    required this.dirpath,
    required this.mainObjectName,
    required this.isAsset,
  });

  String type;
  List<String> options;
  String title;
  String? longtitle;
  String? descr;
  String version;
  String minimum_app_version;
  List<PluginPermissions> permissions;
  KeyValue? langs;
  // ------------
  String dirpath;
  String mainObjectName;
  bool isAsset;
  String? newVersion;
  PluginInfoStatus status = PluginInfoStatus.loading;

  String get id => mainObjectName;

  bool get isSource => type == 'js:source';
  bool get isLyrics => type == 'js:lyrics';

  String titleTranslated() {
    final t = langs?[language.lang.code_]?['title'];
    if (t is String) return t;
    return title;
  }

  String? longtitleTranslated() {
    final t = langs?[language.lang.code_]?['longtitle'];
    if (t is String) return t;
    return longtitle;
  }

  /// Compares this `version` to `other`.
  ///
  /// Returns a negative number if `this` is less than `other`, zero if they are
  /// equal, and a positive number if `this` is greater than `other`.
  int versionsCompareTo(String v) {
    var v1 = version.split('.').map((s) => int.parse(s)).toList();
    var v2 = v.split('.').map((s) => int.parse(s)).toList();
    // #1 number
    if (v1[0] != v2[0]) {
      return v1[0].compareTo(v2[0]);
    }
    // #2 number
    if (v1[1] != v2[1]) {
      return v1[1].compareTo(v2[1]);
    }
    // #3 number
    return v1[2].compareTo(v2[2]);
  }
}

List<PluginInfo> getInstalledPluginsFromDir(String pluginsDir) {
  List<PluginInfo> pluginsList = [];
  Directory dir = Directory(pluginsDir);
  Iterable<Directory> plugins = dir.listSync().whereType<Directory>();
  for (var pluginDir in plugins) {
    final dir = pluginDir.path;

    var scriptFile = File('$dir/script.js');
    if (!scriptFile.existsSync()) {
      gLogger.warn('Invalid plugin (script.js): ${pluginDir.path}');
      continue;
    }

    var info = _getPluginInfo(dir);
    if (info != null) {
      pluginsList.add(info);
    } else {
      gLogger.warn('Invalid plugin info: ${pluginDir.path}');
    }
  }
  return pluginsList;
}

PluginInfo? _getPluginInfo(String rootDir) {
  var file = File('$rootDir/info.json');
  if (!file.existsSync()) {
    return null;
  }

  try {
    var input = file.readAsStringSync();
    var json = jsonDecode(input);

    final info = PluginInfo(
      type: json['type'],
      options: json['options'] != null ? json['options'].cast<String>() : [],
      title: json['title'],
      longtitle: json['longtitle'],
      descr: json['descr'],
      version: json['version'],
      minimum_app_version: json['minimum_app_version'],
      permissions: (json['permissions'] as List)
          .map((el) => PluginPermissions.fromString(el))
          .toList(),
      langs: json['langs'],
      dirpath: rootDir,
      mainObjectName: p.basename(rootDir),
      isAsset: false,
    );
    return info;
  } catch (e, stacktrace) {
    gLogger.error('Error while getting $rootDir/info.json: $e\n$stacktrace');
    return null;
  }
}

bool ensurePluginDirectoriesCreated(String pluginsDir) {
  try {
    Directory('$pluginsDir/archives').createSync(recursive: true);
    Directory('$pluginsDir/installed').createSync(recursive: true);
    return true;
  } catch (e) {
    gLogger.error('Error while creatind plugins\' directories: $e');
    return false;
  }
}
