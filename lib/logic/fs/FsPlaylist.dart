import 'package:m4a_tags_handler/Tags.dart';
import 'package:music_player/consts.dart' as CONSTS;

import 'package:music_player/logic/MusicItem.dart';
import 'package:music_player/logic/fs/files.dart'
    show deleteFile, existsFile, fetchPlaylistBasenames, writeToFile;
import 'package:music_player/logic/fs/m3u.dart' as m3u;
import 'package:music_player/logic/utils.dart' as utils;

class FsPlaylist {
  FsPlaylist(this._sourceDirPath);
  final String _sourceDirPath;

  List<String> getPlaylists() {
    return fetchPlaylistBasenames(_sourceDirPath);
  }

  PictureTag? getPlaylistPicture(String name, List<MusicItem> allMusicItems) {
    var filepaths = m3u.getPlaylistFilepaths(name, _sourceDirPath);
    for (var fpath in filepaths) {
      for (var mi in allMusicItems) {
        if (fpath == mi.filepath!) {
          return mi.tags.picture;
        }
      }
    }
    return null;
  }

  bool createPlaylist(String name) {
    String playlistPath = m3u.fmtPlaylistPath(name, _sourceDirPath);
    return writeToFile(playlistPath, CONSTS.m3uHeader);
  }

  bool existsPlaylist(String name) {
    String playlistPath = m3u.fmtPlaylistPath(name, _sourceDirPath);
    return existsFile(playlistPath);
  }

  bool savePlaylist(String name, List<MusicItem> items) {
    String contents = _toM3u(_sourceDirPath, items);
    return _writePlaylist(name, contents);
  }

  bool deletePlaylist(String name) {
    String playlistPath = m3u.fmtPlaylistPath(name, _sourceDirPath);
    return deleteFile(playlistPath);
  }

  void addToPlaylist(String name, List<MusicItem> items) {
    var playlistPath = m3u.fmtPlaylistPath(name, _sourceDirPath);
    for (var item in items) {
      var filepath =
          utils.relativeOrAbsolutePath(item.filepath!, _sourceDirPath);

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
    var playlistPath = m3u.fmtPlaylistPath(name, _sourceDirPath);
    for (var item in items) {
      var filepath =
          utils.relativeOrAbsolutePath(item.filepath!, _sourceDirPath);

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
    String playlistPath = m3u.fmtPlaylistPath(name, _sourceDirPath);
    return writeToFile(playlistPath, contents);
  }

  static List<String> getNotFoundPlaylistFiles(
      List<String> filepaths, List<MusicItem> playlistMIs) {
    Set<String> all = filepaths.toSet();
    var existing = playlistMIs.map((mi) => mi.filepath).toSet();
    return all.difference(existing).toList();
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
