// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logger.dart';
import 'package:music_player/logic/Config.dart';
import 'package:music_player/logic/EventRegistrar.dart' show eventRegistrar;
import 'package:music_player/logic/JsonStorage.dart';
import 'package:music_player/logic/MpJsRuntime.dart';
import 'package:music_player/logic/PluginSource.dart';
import 'package:music_player/logic/Source.dart';
import 'package:music_player/logic/plugins.dart'
    show PluginInfo, PluginInfoStatus, getInstalledPluginsFromDir;
import 'package:music_player/logic/plugins/LyricsPlugin.dart';
import 'package:music_player/logic/plugins/PluginsClient.dart';
import 'package:music_player/states/DownloadsState.dart';

import 'package:music_player/states/AppState.dart';
import 'package:music_player/states/PlaybackState.dart';

const jsLibsPaths = [
  '${CONFIG.jsLibsDir}/MusicPlayer.js',
  '${CONFIG.jsLibsDir}/Streams.js',
  '${CONFIG.jsLibsDir}/AbortController.js',
  '${CONFIG.jsLibsDir}/TextEncoderDecoder.js',
  '${CONFIG.jsLibsDir}/URL.js',
  '${CONFIG.jsLibsDir}/Request.js',
  '${CONFIG.jsLibsDir}/Headers.js',
  '${CONFIG.jsLibsDir}/FormData.js',
];

class PluginManager {
  Config config;

  String pluginsDir;

  PlaybackState playbackState;
  DownloadsState downloadsState;

  List<PluginInfo> pluginsList = [];
  Map<String, Source> sources = {};
  Map<String, LyricsPlugin> lyrics = {};
  String getLyricsPluginId() {
    final ls = lyrics.entries.toList();
    if (ls.isEmpty) {
      return '';
    }
    return ls[0].key;
  }

  List<(String, String)> _jsLibs = [];

  // final Map<String, JsRuntimeI> _runtimesMap = {};

  PluginManager(this.config, this.downloadsState, this.playbackState)
      : pluginsDir = (CONFIG.isDev() && !Platform.isAndroid)
            ? CONFIG.devPluginsDir
            : config.pluginsInstalledDir;

  int pluginUpdatesCount = 0;
  int _calcPluginUpdatesCount() => pluginsList.fold<int>(
      0, (acc, p) => acc + (p.newVersion != null ? 1 : 0));

  Future<void> checkPluginUpdatesAsync() async {
    try {
      final uri = Uri.parse(config.pluginsServerUrl);
      final arr = await PluginsClient(uri).getPluginsVersions(
          pluginsList.map((p) => p.mainObjectName).toList());
      _checkedPluginsVersions = arr;
      checkPluginVersions();
    } catch (e, s) {
      logger.exception('checkPluginUpdatesAsync', e, s);
    }
  }

  List _checkedPluginsVersions = [];

  void checkPluginVersions() {
    /* obj = [{
      name: $name,
      version: $version,
    }] */
    final arr = _checkedPluginsVersions;
    logger.blue(arr);
    for (var o in arr) {
      var idx = pluginsList.indexWhere((p) => p.mainObjectName == o['name']);
      if (idx != -1) {
        var p = pluginsList[idx];
        String otherVersion = o['version'] as String;
        if (p.versionsCompareTo(otherVersion) < 0) {
          p.newVersion = otherVersion;
        }
      }
    }
    pluginUpdatesCount = _calcPluginUpdatesCount();
  }

  List<PluginInfo> getInstalledPlugins() =>
      getInstalledPluginsFromDir(pluginsDir);

  List<PluginInfo> getNewInstalledPlugins() {
    var prevNames = pluginsList.map((p) => p.mainObjectName);
    var newPlugins = getInstalledPlugins();
    newPlugins
        .removeWhere((needle) => prevNames.contains(needle.mainObjectName));
    return newPlugins;
  }

  Future<void> loadPlugins(AppState appState, List<PluginInfo> plugins) async {
    _jsLibs = await _loadJsLibs();
    for (var plugin in plugins) {
      await loadPlugin(appState, plugin);
    }
  }

  Future<bool> loadPlugin(
    AppState appState,
    PluginInfo plugin,
  ) async {
    final pluginId = plugin.id;
    sources.remove(pluginId);
    lyrics.remove(pluginId);

    final p = await _loadPlugin(appState, plugin, _jsLibs);
    if (p.plugin.status != PluginInfoStatus.loaded) {
      return false;
    }

    if (p.source != null) {
      sources[pluginId] = p.source!;
    } else if (p.lyrics != null) {
      lyrics[pluginId] = p.lyrics!;
    }
    return true;
  }

  /// Modifies only pluginInfo
  Future<_PluginDescr> _loadPlugin(AppState appState, PluginInfo plugin,
      List<(String, String)> jsLibs) async {
    String mainObjectName = plugin.mainObjectName;

    PluginSource? source;
    LyricsPlugin? lyrics;
    try {
      // Create and Add runtime to map
      JsRuntimeI runtime = DartJsProxy.self(mainObjectName);
      await runtime.initAsync(jsLibs);
      logger.debug('after initAsync');
      // _runtimesMap[mainObjectName] = runtime;

      if (plugin.type == 'js:source') {
        logger.log('Creating PluginSource. isAsset=${plugin.isAsset}');

        // Create source
        String sourceId = plugin.id;
        source = PluginSource(
          sourceId,
          runtime,
          pluginTitle: plugin.title,
          playback: appState.playback,
          toThisSourceAsync: () => appState.toSource(sourceId),
          propertyStorage: JsonStorage('${plugin.dirpath}/settings.json'),
          updateAppState: appState.update,
          updatePlaybackState: playbackState.update,
          findMusicItem: appState.findMusicItem,
          downloadsState: downloadsState,
          eventRegistrar: eventRegistrar,
          autoplaySources: appState.autoplaySources,
        );
        source.isCurrentSource = () => appState.currentSource == source;
        await source.initAsync();
        await _loadPluginScript(plugin, runtime);
        await source.afterPluginLoaded();
      } else if (plugin.type == 'js:lyrics') {
        // Create lyrics
        lyrics = LyricsPlugin(runtime);
        await _loadPluginScript(plugin, runtime);
        await lyrics.afterPluginLoaded();
      }
      plugin.status = PluginInfoStatus.loaded;
    } catch (e, stacktrace) {
      logger.warn(
          'Exception while creating Plugin source "$mainObjectName": $e\n${stacktrace}');
      plugin.status = PluginInfoStatus.errored;
    }
    return _PluginDescr(plugin, source: source, lyrics: lyrics);
  }
}

class _PluginDescr {
  PluginInfo plugin;
  PluginSource? source;
  LyricsPlugin? lyrics;
  _PluginDescr(this.plugin, {this.source, this.lyrics});
}

Future<void> _loadPluginScript(PluginInfo plugin, JsRuntimeI runtime) async {
  if (plugin.isAsset) {
    logger.log('_loadPluginScript() from asset');
    bool ok = await runtime.loadPluginFromAssets('${plugin.dirpath}/script.js');
    if (!ok) throw Exception('Plugin asset errored loading');
  } else {
    bool ok = await runtime.loadPlugin('${plugin.dirpath}/script.js');
    if (!ok) throw Exception('Plugin errored loading');
  }
}

Future<List<(String, String)>> _loadJsLibs() async {
  List<(String, String)> libs = [];
  for (var el in jsLibsPaths) {
    libs.add((el, await rootBundle.loadString(el)));
  }
  return libs;
}

final Logger logger = Logger(prefix: '📘 PluginManager: ');
