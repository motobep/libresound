import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:music_player/config.dart';
import 'package:music_player/consts.dart' as CONSTS;
import 'package:music_player/logger.dart';
import 'package:music_player/logic/fs/files.dart' as fs;
import 'package:music_player/logic/utils.dart' as utils;

/// Throws
List<String> getPlaylistFilepaths(String name, String sourceDir) {
  String playlistPath = fmtPlaylistPath(name, sourceDir);
  List<String> filenames = _getPlaylistFilenames(playlistPath);
  return utils.prefixOrNotFilenames(filenames, sourceDir);
}

/// Throws
List<String> _getPlaylistFilenames(String playlistPath) {
  List<String> lines;
  try {
    lines = File(playlistPath).readAsLinesSync();
  } catch (e, stacktrace) {
    gLogger.error('Exception while reading: $e\n$stacktrace');
    rethrow;
  }

  return _getFilesFromM3U(lines);
}

List<String> _getFilesFromM3U(List<String> lines) {
  List<String> filenames = [];
  if (lines[0] != CONSTS.m3uHeader) {
    return [];
  }
  for (var line in lines) {
    String newLine = line.trim();
    if (newLine.isNotEmpty && newLine[0] != '#') {
      filenames.add(newLine);
    }
  }
  return filenames;
}

bool appendToM3uFile(String playlistPath, String itemPath,
    {String? seconds, String? artist, String? title}) {
  String contents = formatM3uRecord(itemPath, seconds, artist, title);
  return fs.appendToFile(playlistPath, contents);
}

bool removeFromM3uFile(String playlistPath, String itemPath,
    {String? seconds, String? artist, String? title}) {
  final f = fileSystem.file(playlistPath);
  try {
    String s = f.readAsStringSync();
    // gLogger.log('s: $s');
    // TODO: ignore seconds, artist and etc.
    String record = formatM3uRecord(itemPath, seconds, artist, title);
    s = s.replaceFirst(record, '');
    // gLogger.log('s2: $s');
    f.writeAsStringSync(s);
    return true;
  } catch (e) {
    gLogger.error('removeFromM3uFile(): $e');
    return false;
  }
}

String formatM3uRecord(
    String itemFilepath, String? seconds, String? artist, String? title) {
  var arr = [seconds, artist, title];
  if (utils.checkEveryNotNull(arr) &&
      !utils.checkAnyHasNewline([seconds!, artist!, title!])) {
    var a = arr.map((s) => s!.contains(RegExp(r'#|,|-')) ? "'$s'" : s).toList();
    return '\n#EXTINF:${a[0]}, ${a[1]} - ${a[2]}\n$itemFilepath\n';
  }
  return '\n$itemFilepath\n';
}

String fmtPlaylistPath(String playlistName, String sourceDir) {
  return path.join(sourceDir, '$playlistName.m3u');
}
