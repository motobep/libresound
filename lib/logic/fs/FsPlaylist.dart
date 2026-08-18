import 'dart:io' show Platform;

import 'package:m4a_tags_handler/Tags.dart';
import 'package:music_player/consts.dart' as CONSTS;
import 'package:music_player/logger.dart' show gLogger;

import 'package:music_player/logic/MusicItem.dart';
import 'package:music_player/logic/fs/files.dart' as fs;
import 'package:music_player/logic/fs/m3u.dart' as m3u;
import 'package:music_player/logic/utils.dart' as utils;

class FsPlaylist {
  FsPlaylist(this.playlistsDirPath);

  final String playlistsDirPath;

  List<String> getPlaylists() {
    return fs.fetchPlaylistBasenames(playlistsDirPath);
  }

  PictureTag? getPlaylistPicture(String name, List<MusicItem> allMusicItems) {
    var filepaths = m3u.getPlaylistFilepathsCanonical(name, playlistsDirPath);
    // gLogger.debug('filepaths: $filepaths');

    for (var fpath in filepaths) {
      for (var mi in allMusicItems) {
        // gLogger.warn('($fpath, ${mi.filepath})');
        if (fpath == mi.filepath!) {
          return mi.tags.picture;
        }
      }
    }
    return null;
  }

  List<String> getPlaylistFilepaths(name) {
    List<String> arr = [];
    try {
      arr = m3u.getPlaylistFilepathsCanonical(name, playlistsDirPath);
    } catch (e, s) {
      gLogger.exception('getPlaylistFilepaths', e, s);
    }
    return arr;
  }

  bool createPlaylist(String name) {
    String playlistPath = m3u.fmtPlaylistPath(name, playlistsDirPath);
    return fs.writeToFile(playlistPath, CONSTS.m3uHeader);
  }

  bool existsPlaylist(String name) {
    String playlistPath = m3u.fmtPlaylistPath(name, playlistsDirPath);
    return fs.existsFile(playlistPath);
  }

  bool savePlaylist(String name, List<MusicItem> items) {
    String contents = _toM3u(playlistsDirPath, items);
    return _writePlaylist(name, contents);
  }

  bool deletePlaylist(String name) {
    String playlistPath = m3u.fmtPlaylistPath(name, playlistsDirPath);
    return fs.deleteFile(playlistPath);
  }

  void addToPlaylist(String name, List<MusicItem> items) {
    var playlistPath = m3u.fmtPlaylistPath(name, playlistsDirPath);
    for (var item in items) {
      var filepath =
          utils.relativeOrAbsolutePath(item.filepath!, playlistsDirPath);

      m3u.appendToM3uFile(
        playlistPath,
        filepath,
        seconds: item.durationInSeconds.toString(),
        artist: item.artistName,
        title: item.title,
      );
    }
  }

  void removeFromPlaylist(String name, List<MusicItem> items) {
    var playlistPath = m3u.fmtPlaylistPath(name, playlistsDirPath);
    for (var item in items) {
      var filepath =
          utils.relativeOrAbsolutePath(item.filepath!, playlistsDirPath);

      m3u.removeFromM3uFile(
        playlistPath,
        filepath,
        seconds: item.durationInSeconds.toString(),
        artist: item.artistName,
        title: item.title,
      );
    }
  }

  bool _writePlaylist(String name, String contents) {
    String playlistPath = m3u.fmtPlaylistPath(name, playlistsDirPath);
    return fs.writeToFile(playlistPath, contents);
  }

  static List<String> getNotFoundMisFilesInPlaylist(
      List<String> filepaths, List<MusicItem> playlistMIs) {
    Set<String> all = filepaths.toSet();
    gLogger.log('all: $all');
    var existing = playlistMIs.map((mi) => mi.filepath).toSet();
    gLogger.log('existing: $existing');
    var notFound = all.difference(existing).toList();
    gLogger.error('notFound: $notFound');
    return notFound;
  }
}

String _toM3u(String sourceDir, List<MusicItem> items) {
  String contents = '${CONSTS.m3uHeader}\n';
  for (var item in items) {
    String filepath = utils.relativeOrAbsolutePath(item.filepath!, sourceDir);
    contents += m3u.formatM3uRecord(filepath, item.durationInSeconds.toString(),
        item.artistName, item.title);
  }
  return contents;
}
