import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:m4a_tags_handler/M4a.dart';
import 'package:m4a_tags_handler/Tags.dart';
import 'package:music_player/logger.dart';
import 'package:path/path.dart' as p;
import 'package:id3tag/id3tag.dart' show Picture;

import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logic/ID3/ID3TagsV1.dart';
import 'package:music_player/logic/ID3/ID3TagsV2.dart';
import 'package:music_player/logic/MusicItem.dart';
import 'package:music_player/logic/KeyValue.dart';
import 'package:music_player/logic/fs/files.dart';

Future<List<MusicItem>> getMusicItemsAsync(Iterable<File> fileList) async {
  List<MusicItem> list = [];
  for (var file in fileList) {
    _addMusicItemToList(file, list);
  }
  return list;
}

void _addMusicItemToList(File file, List<MusicItem> list) {
  try {
    String ext = getExtension(file.path);
    Tags tags;
    if (ext == '.mp3') {
      Tags v2Tags = _getId3V2Tags(file);
      if (v2Tags.hasNecessary()) {
        tags = v2Tags;
      } else {
        Tags v1Tags = _getId3V1Tags(file);
        tags = _joinTags(v2Tags, v1Tags);
      }
      ID3TagsV2 id3TagsV2 = ID3TagsV2(file);
      Picture? pic = id3TagsV2.getPicture();
      if (pic != null) {
        String mimeType = pic.mime == 'image/jpg' ? 'image/jpeg' : pic.mime;
        tags.picture = PictureTag(
            mime: mimeType, bytes: Uint8List.fromList(pic.imageData));
      }
    } else if (ext == '.m4a') {
      tags = _getM4aTags(file);
    } else {
      assert(false, 'Wrong extension');
      return; // to shut up linter
    }

    tags.title ??= p.basename(file.path);

    MusicItem mi = MusicItem.fromFile(
      file.path,
      tags,
      sourceId: CONFIG.fsSourceId,
    );
    mi.fetchDuration();
    list.add(mi);
  } catch (e) {
    gLogger.warn('Error in getting file ${file.path}. \nInner exception: $e');
  }
}

Future<List<MusicItem>> getMusicItemsWithCacheAsync(
    (Iterable<File> fileList, KeyValue musicItemsInfo) pair) async {
  final (fileList, musicItemsInfo) = pair;
  List<MusicItem> list = [];
  for (var file in fileList) {
    String filename = file.path.split('/').last;
    if (musicItemsInfo.containsKey(filename)) {
      _addMusicItemToListCached(file.path, musicItemsInfo[filename], list);
    } else {
      _addMusicItemToList(file, list);
    }
  }
  return list;
}

void _addMusicItemToListCached(
    String filepath, KeyValue itemInfo, List<MusicItem> list) {
  try {
    Tags tags = Tags(
      title: itemInfo['title'],
      artist: itemInfo['artist'],
      album: itemInfo['album'],
      year: itemInfo['year'],
      track: itemInfo['track'],
      genre: itemInfo['genre'],
    );
    if (itemInfo['hasPicture']) {
      File file = File(filepath);
      if (itemInfo['extension'] == '.mp3') {
        ID3TagsV2 id3TagsV2 = ID3TagsV2(file);
        Picture? pic = id3TagsV2.getPicture();
        if (pic != null) {
          String mimeType = pic.mime == 'image/jpg' ? 'image/jpeg' : pic.mime;
          tags.picture = PictureTag(
              mime: mimeType, bytes: Uint8List.fromList(pic.imageData));
        }
      } else if (itemInfo['extension'] == '.m4a') {
        Uint8List bytes = file.readAsBytesSync();
        PictureTag? picture = M4aTagsHandler(bytes).getPicture();
        tags.picture = picture;
      }
    }

    tags.title ??= p.basename(filepath);

    MusicItem mi = MusicItem.fromFile(
      filepath,
      tags,
      sourceId: CONFIG.fsSourceId,
    );
    mi.duration = Duration(seconds: itemInfo['duration']);
    list.add(mi);
  } catch (e) {
    gLogger.warn(
        'Error in getting cached info of $filepath. \nInner exception: $e');
  }
}

Tags _joinTags(Tags a, Tags b) {
  return Tags(
    title: a.title ?? b.title,
    artist: a.artist ?? b.artist,
    album: a.album ?? b.album,
    year: a.year ?? b.year,
    track: a.track ?? b.track,
    genre: a.genre ?? b.genre,
  );
}

Tags _getId3V1Tags(File file) {
  Uint8List contents = Uint8List(128);
  try {
    contents = file.readAsBytesSync();
  } on FileSystemException {
    throw Exception('FileSystemException while reading music file');
  } catch (e) {
    throw Exception('Unexpected exception while reading music file $e');
  }

  var meta = contents.sublist(contents.length - 128);
  if (meta[0] == 'T'.codeUnitAt(0) &&
      meta[1] == 'A'.codeUnitAt(0) &&
      meta[2] == 'G'.codeUnitAt(0)) {
  } else {
    gLogger.warn('No ID3v1 metadata for: ${file.path}');
    return Tags(title: p.basename(file.path));
  }

  ID3TagsV1 id3TagsV1 = ID3TagsV1(meta.sublist(3));
  return id3TagsV1.getTags();
}

Tags _getId3V2Tags(File file) {
  ID3TagsV2 id3TagsV2 = ID3TagsV2(file);
  return id3TagsV2.getTags();
}

Tags _getM4aTags(File file) {
  Uint8List bytes = file.readAsBytesSync();
  var m4a = M4aTagsHandler(bytes);
  return m4a.getCommonTags();
}
