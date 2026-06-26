import 'dart:io';
import 'dart:async';
import 'dart:typed_data' show Uint8List;
import 'package:m4a_tags_handler/Tags.dart';
import 'package:music_player/logic/ID3/addTagsToMp3Bytes.dart';
import 'package:music_player/logic/MusicItem.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:music_player/logic/fs/files.dart';
import 'package:m4a_tags_handler/M4a.dart';
import 'package:music_player/logic/utils.dart' as utils;

/// Throws Exception (may throw)
Future<File> writeBytesWithTagsToCache(List<int> bytes, MusicItem item) async {
  List<int> newBytes = await _addTags(bytes, item);
  var f = await DefaultCacheManager().putFile(
      'cached_web_file_${item.id}', Uint8List.fromList(newBytes),
      eTag: 'cached_web_file',
      maxAge: const Duration(minutes: 30),
      fileExtension: item.extension);
  return f;
}

/// Throws Exception (may throw)
Future<File> cachePictureAsync(String id, PictureTag picture) async {
  var f = await DefaultCacheManager().putFile(
    id,
    picture.bytes,
    eTag: 'cached_web_file',
    maxAge: const Duration(minutes: 10),
    fileExtension: utils.extensionFromMime(picture.mime) ?? 'jpeg',
  );
  return f;
}

/// Throws Exception (may throw)
Future<bool> writeBytesWithTagsToFile(
    List<int> bytes, String filepath, MusicItem item) async {
  List<int> newBytes = await _addTags(bytes, item);
  return writeToPathAsBytes(filepath, newBytes);
}

Future<List<int>> _addTags(List<int> bytes, MusicItem item) async {
  List<int> newBytes;
  if (item.extension == '.mp3') {
    newBytes = await addTagsToMp3Bytes(
        Future.value(bytes), item.tags, item.tags.picture);
  } else if (item.extension == '.m4a') {
    var m4a = M4aTagsHandler(
        Uint8List.fromList(bytes)); // Note: fromList makes a copy
    Tags tags = item.tags;
    // tags.show();
    m4a.setTags(tags);
    newBytes = m4a.build().buffer;
  } else {
    assert(false, 'Wrong extension: ${item.extension}');
    newBytes = []; // To shut up linter
  }
  return newBytes;
}

/// Throws
/// Funcs with CacheManager
Future<File?> saveWebFileCached(String filepath, MusicItem item) async {
  File? cachedFile = await getCachedWebFile(item.id);
  if (cachedFile != null) {
    return cachedFile.copySync(filepath);
  }
  return null;
}

Future<bool> cachedWebFileExists(String id) async {
  return (await getCachedWebFile(id)) != null;
}

Future<File?> getCachedWebFile(String id) async {
  FileInfo? fInfo =
      await DefaultCacheManager().getFileFromCache('cached_web_file_$id');
  return fInfo?.file;
}
