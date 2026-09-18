import 'dart:io';

import 'package:path/path.dart' as pathPkg;
import 'package:m4a_tags_handler/Tags.dart';

import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logger.dart';
import 'package:music_player/logic/MusicItem.dart';
import 'package:music_player/logic/utils.dart' as utils;

final logger = Logger(prefix: '[DemoFsFuncs]: ');

Future<List<MusicItem>> getMusicItemsDemoAsync(
    String sourceDirPath, List<File> files) async {
  logger.blue('load music demo');
  List<MusicItem> items = [];
  final sourceDir = Directory(sourceDirPath);
  var entities = sourceDir.listSync();
  for (var entity in entities) {
    if (entity is File && entity.path.endsWith('.png') ||
        entity.path.endsWith('.jpeg') ||
        entity.path.endsWith('.jpg')) {
      File file = File(entity.path);
      logger.log('ent: ${entity.path}');

      String propsStr = pathPkg.basenameWithoutExtension(file.path);
      var props = propsStr.split('|');
      if (props.length != 4) {
        logger.warn('Bad file props str');
        continue;
      }
      var [title, artist, album, dur] = props;

      PictureTag picture = PictureTag(
          mime: utils.mimeFromPath(entity.path) ?? 'image/jpeg',
          bytes: file.readAsBytesSync());
      Tags tags = Tags(
        title: title,
        artist: artist,
        album: album,
        picture: picture,
      );
      var [minutes, secs] = dur.split(':');
      var duration =
          Duration(minutes: int.parse(minutes), seconds: int.parse(secs));
      MusicItem mi = MusicItem.directly(
        file.path,
        tags,
        sourceId: CONFIG.fsSourceId,
        duration: duration,
      );
      mi.filepath = File('./demo.mp3').absolute.path;
      items.add(mi);
    }
  }
  return items;
}

const en = {
  'Favorite_Songs': 'Favorite Songs',
  'Top_Playlists': 'Top Playlists',
  'Related_Albums': 'Related Albums',
};

const ru = {
  'Favorite_Songs': 'Любимые Песни',
  'Top_Playlists': 'Топ Плейлистов',
  'Related_Albums': 'Похожие Альбомы',
};

Map<String, String> getLangDemo(String code) => code == 'ru' ? ru : en;
