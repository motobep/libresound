import 'dart:io' show Platform;

import 'package:music_player/logger.dart' show gLogger;
import 'package:music_player/logic/fs/files.dart';
import 'package:music_player/logic/getDeviceInfo.dart'
    show getAndroidSdkVersion;
import 'package:photo_manager/photo_manager.dart';

/// High level funcs
Future<bool> deleteFilesAsync(List<String> paths) async {
  bool allOk = true;
  // TODO: simplify
  if (Platform.isAndroid) {
    var audio =
        paths.where((p) => (p.endsWith('.mp3') || p.endsWith('.mp4'))).toList();
    var notAudio = paths
        .where((p) => !(p.endsWith('.mp3') || p.endsWith('.mp4')))
        .toList();

    if (audio.isNotEmpty) {
      int sdk = await getAndroidSdkVersion();
      const int ANDROID_10_SDK = 29;
      if (sdk < ANDROID_10_SDK) {
        allOk = _deleteAllFilesNative(paths);
      } else {
        allOk = await Android.mediaStoreDeleteFilesAsync(paths);
      }
    }
    if (notAudio.isNotEmpty) {
      gLogger.warn('Delete non-audio files');
      gLogger.warn('notAudio: ${notAudio.length}');
      if (allOk) {
        allOk = _deleteAllFilesNative(notAudio);
      }
    }
  } else {
    allOk = _deleteAllFilesNative(paths);
  }
  return allOk;
}

bool _deleteAllFilesNative(List<String> paths) {
  bool allOk = true;
  for (var p in paths) {
    bool ok = deleteFile(p);
    if (!ok) {
      allOk = false;
      gLogger.warn('Not ok while deleting $p');
    }
  }
  return allOk;
}

class Android {
  static Future<bool> mediaStoreDeleteFilesAsync(List<String> paths) async {
    final pathToIdMap = await buildMap();

    List<String> ids = [];
    final pattern = RegExp(r'^\/storage\/emulated\/0\/(.*)');

    for (var p in paths) {
      var fm = pattern.firstMatch(p);
      gLogger.debug('fm: ${fm?[1]} ${fm?.groupCount}');
      String? relativePath = fm?[1];

      if (relativePath == null) {
        gLogger.warn('relativePath is null');
        continue;
      }

      var id = pathToIdMap[relativePath];
      if (id == null) {
        gLogger.warn('Not Found path: $paths - ${id}');
        continue;
      }
      gLogger.debug('Found path: $paths - ${id}');
      ids.add(id);
    }

    if (ids.isEmpty) {
      gLogger.warn('Ids is empty');
      return false;
    }

    final List<String> result = await PhotoManager.editor.deleteWithIds(ids);
    gLogger.log('result: $result');
    if (result.isEmpty) {
      gLogger.warn("Couldn't delete");
      // TODO: fallback to usual io delete
      return false;
    }
    return true;
  }

  static Future<Map<String, String>> buildMap() async {
    Map<String, String> pathToIdMap = {};
    var audioPaths = await getAudioPaths();
    int count = await PhotoManager.getAssetCount();
    gLogger.warn('asset count: $count');

    for (final AssetPathEntity entity in audioPaths) {
      gLogger.log('Album: ${entity.name}');

      if (!['Music', 'Download'].contains(entity.name)) {
        continue;
      }

      var pal = await entity.relativePathAsync;
      gLogger.log('pal: $pal');

      final List<AssetEntity> audioFiles = await entity.getAssetListPaged(
        page: 0,
        size: 1000,
      );

      for (final AssetEntity audio in audioFiles) {
        // print('  -  $audio: ${audio.title} [${audio.relativePath}] (${audio.duration}s)');
        String p = '${audio.relativePath}${audio.title}';
        // print('path: $p - ${audio.id}');
        pathToIdMap[p] = audio.id;
      }
    }
    return pathToIdMap;
  }

  static Future<List<AssetPathEntity>> getAudioPaths() async {
    final List<AssetPathEntity> audioPaths =
        await PhotoManager.getAssetPathList(type: RequestType.audio);
    return audioPaths;
  }
}
