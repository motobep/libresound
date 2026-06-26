import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:io' show File, FileSystemException;

import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logger.dart';
import 'package:music_player/logic/KeyValue.dart';
import 'package:music_player/logic/MusicItem.dart';
import 'package:music_player/logic/fs/files.dart' as fs;
import 'package:music_player/main.dart';

bool writeCachedInfoToFile(List<MusicItem> items, String sourceDir) {
  // log('Cached Info Filepath: ${config.cachedInfoFilepath}');

  KeyValue cachedInfoEntry = {};

  try {
    KeyValue pair = {'items': items, 'sourceDir': sourceDir};
    cachedInfoEntry = _cacheMapFromMusicItems(pair);
    // cachedInfoEntry = await compute(_getJsonFromMusicItems, pair); // compute requires simple things inside function
  } catch (e) {
    logger.error('logger.error writing cachedInfo (during compute()): $e');
    return false;
  }

  if (cachedInfoEntry.isEmpty) return false;
  String dir = cachedInfoEntry.keys.first;

  try {
    KeyValue cachedInfo = getCachedInfo();
    cachedInfo.addAll(cachedInfoEntry);

    _removeMapExtraEnrtries(
        cachedInfo, CONFIG.maxCachedMusicInfoEntries, [dir]);

    String cachedInfoJson = jsonEncode(cachedInfo);
    bool ok = fs.writeToFile(config.cachedInfoFilepath, cachedInfoJson);
    if (!ok) {
      logger.log('WARN: Cached info file wasn\'t written');
    }
  } catch (e) {
    logger.error('logger.error writing cachedInfo: $e');
    return false;
  }
  return true;
}

KeyValue getCachedInfo() {
  String cachedInfoStr = _getCachedInfoStr();
  if (cachedInfoStr == '') {
    return {};
  }

  Map<String, dynamic> cachedInfo = jsonDecode(cachedInfoStr);
  return cachedInfo;
}

bool updateCachedInfoMiDuration(MusicItem mi, String sourceDirPath) {
  final cachedInfo = getCachedInfo();

  final key = mi.filepath!.split('/').last;
  final miMap = cachedInfo[sourceDirPath][key];
  if (miMap == null) return false;
  miMap['duration'] = mi.durationInSeconds;
  return saveCachedInfo(cachedInfo);
}

bool saveCachedInfo(KeyValue cachedInfo) {
  String cachedInfoJson = jsonEncode(cachedInfo);
  return fs.writeToFile(config.cachedInfoFilepath, cachedInfoJson);
}

String _getCachedInfoStr() {
  String cachedInfoStr = '';

  File cachedInfoFile = File(config.cachedInfoFilepath);
  if (!cachedInfoFile.existsSync()) {
    return '';
  }

  try {
    cachedInfoStr = cachedInfoFile.readAsStringSync();
  } on FileSystemException {
    logger.log('FileSystemException while reading cachedInfo file');
    return '';
  } catch (e) {
    logger.log('Unexpected exception while reading cachedInfo file $e');
    return '';
  }

  return cachedInfoStr;
}

KeyValue _cacheMapFromMusicItems(KeyValue pair) {
  List<MusicItem> items = pair['items'];
  String sourceDir = pair['sourceDir'];
  KeyValue cachedDirInfo = {sourceDir: {}};
  for (var mi in items) {
    KeyValue jsonObj = mi.toFilepathKeyMap();
    cachedDirInfo[sourceDir].addAll(jsonObj);
  }
  return cachedDirInfo;
}

void _removeMapExtraEnrtries(KeyValue map, int maxEntries,
    [List<String> exceptList = const []]) {
  while (map.length > maxEntries) {
    for (var key in map.keys) {
      if (!exceptList.contains(key)) {
        map.remove(key);
        break;
      }
    }
  }
}

final Logger logger = Logger(prefix: '📗 CacheConfig: ');
