import 'dart:convert' show jsonEncode;

import 'package:music_player/logic/MpJsRuntime.dart';
import 'package:music_player/logic/MusicItem.dart' show MusicItem;
import 'package:music_player/view/components/Lrc.dart' show LyricsObj;

class LyricsPlugin {
  LyricsPlugin(
    this.mpJsRuntime,
  );

  final String pluginMainObjectName = 'plugin';
  JsRuntimeI mpJsRuntime;

  /// Throws
  Future<LyricsObj?> getLyricsAsync(MusicItem mi) async {
    final miJson = jsonEncode(mi);
    Map? resp = await mpJsRuntime.runCodeInAsyncFunc('''// js
			return await $pluginMainObjectName.getLyricsAsync($miJson);
    ''');
    if (resp == null) return null;
    return LyricsObj(
      text: resp['text'],
      isSynced: resp['isSynced'],
      descr: resp['descr'],
    );
  }

  Future<void> afterPluginLoaded() async {
    await mpJsRuntime.runCodeInAsyncFunc('''// js
			await $pluginMainObjectName.initAsync();
    ''');
  }
}
