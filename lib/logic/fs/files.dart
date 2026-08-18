import 'dart:io';
import 'package:music_player/logger.dart';
import 'package:path/path.dart' as p;
import 'package:music_player/config.dart' show fileSystem;
import 'package:path/path.dart' as path;

const List<String> allowedExt = ['.mp3', '.m4a', '.m3u'];

List<File> fetchMusicFiles(String dirname) {
  var mp3Files = fetchFilesFromDirByExt(dirname, '.mp3');
  return mp3Files + fetchFilesFromDirByExt(dirname, '.m4a');
}

/// Throws
List<File> fetchFilesFromDirByExt(String dirname, String ext) {
  assert(allowedExt.contains(ext), 'Use allowed Extension. Passed "$ext"');

  final dir = fileSystem.directory(dirname);
  List<FileSystemEntity> entities;
  try {
    entities = dir.listSync().toList();
  } catch (e) {
    gLogger.error('-------\nExeption in fetchFilesFromDir(): $e');
    throw FetchDirectoryFilesException(e.toString());
  }
  final Iterable<File> files =
      entities.where((f) => p.extension(f.path) == ext).whereType<File>();
  return files.toList();
}

class FetchDirectoryFilesException implements Exception {
  String cause;
  FetchDirectoryFilesException(this.cause);
  @override
  String toString() => 'FetchDirectoryFilesException: $cause';
}

List<String> fetchPlaylistBasenames(String dirname) {
  var files = fetchFilesFromDirByExt(dirname, '.m3u');
  return _getFileNamesWithoutExtension(files);
}

String getExtension(String filepath) {
  var f = fileSystem.file(filepath);
  return p.extension(f.path);
}

List<String> _getFileNamesWithoutExtension(List<File> files) {
  return (files.map((file) => p.basenameWithoutExtension(file.path))).toList();
}

bool writeToFile(String filepath, String contents) {
  var file = fileSystem.file(filepath);

  try {
    file.writeAsStringSync(contents);
  } catch (e) {
    gLogger.error('Error while writing to file.\n\tError: $e');
    return false;
  }

  return true;
}

bool writeToFileAsBytes(File file, List<int> contents) {
  try {
    file.writeAsBytesSync(contents);
  } catch (e) {
    gLogger.error('Error while writing to file.\n\tError: $e');
    return false;
  }

  return true;
}

bool existsFile(String filepath) {
  return fileSystem.file(filepath).existsSync();
}

bool appendToFile(String filepath, String contents) {
  var file = fileSystem.file(filepath);
  if (!file.existsSync()) {
    return false;
  }

  try {
    file.writeAsStringSync(contents, mode: FileMode.append);
  } catch (e) {
    gLogger.error('Error while appending to file.\n\tError: $e');
    return false;
  }

  return true;
}

bool deleteFile(String path) {
  var f = fileSystem.file(path);
  if (f.existsSync()) {
    try {
      f.deleteSync();
    } catch (e, s) {
      gLogger.exception('deleteFile', e, s);
      return false;
    }
    return true;
  }
  return false;
}

void initMemoryFs(String dirpath) {
  var dir = Directory(dirpath);
  var mDir = fileSystem.directory(dir.path)..createSync(recursive: true);
  _copyDirectory(dir, mDir);
}

void _copyDirectory(Directory source, Directory destination) {
  source.listSync(recursive: false).forEach((var entity) {
    if (entity is Directory) {
      var newDirectory = fileSystem.directory(
          path.join(destination.absolute.path, path.basename(entity.path)));
      newDirectory.createSync();

      _copyDirectory(entity.absolute, newDirectory);
    } else if (entity is File) {
      String mFilepath =
          path.join(destination.path, path.basename(entity.path));
      File mFile = fileSystem.file(mFilepath);
      if (path.extension(entity.path) == '.m3u') {
        mFile.writeAsBytesSync(entity.readAsBytesSync());
      } else {
        mFile.createSync();
      }

      mFile.setLastModifiedSync(entity.lastModifiedSync());
    }
  });
}

void watchSubDirs(
  String dirpath, {
  required void Function() callback,
  required int delayMs,
  ext = '',
}) {
  final mainDir = Directory(dirpath);
  if (!mainDir.existsSync()) {
    gLogger.error('Directory does not exist.');
    return;
  }

  final stopwatch = Stopwatch()..start();
  int lastTime = 0;

  final Iterable<Directory> dirs = mainDir.listSync().whereType<Directory>();
  for (final dir in dirs) {
    dir.watch(events: FileSystemEvent.modify).listen((event) {
      if (stopwatch.elapsedMilliseconds > lastTime + delayMs) {
        if (event.path.endsWith(ext)) {
          lastTime = stopwatch.elapsedMilliseconds;
          callback();
        }
      }
    });

    gLogger.log('Watching directory: ${dir.path}');
  }
}
