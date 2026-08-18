import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:music_player/config.dart' show fileSystem;
import 'package:path/path.dart' as path;
import 'package:music_player/logic/fs/files.dart' as fs;

Uint8List makePayloadFromBinary(Uint8List bin) {
  return Uint8List.fromList([1] + bin);
}

Uint8List makePayloadFromString(String s) {
  List<int> sbytes = [0] + utf8.encode(s);
  return Uint8List.fromList(sbytes);
}

/// Used only in dev environment
void prepare_directory(String s) {
  fileSystem.directory(pivotD(s)).createSync(recursive: true);
  deleteAll(pivotD(s));
  copyDirPreserveLastModified(constD(s), pivotD(s));
}

/// Used only in dev environment
void deleteAll(String dir) {
  var all = scanDirFilepaths(dir);
  for (var file in all) {
    fs.deleteFile(file);
  }
}

List<String> scanDirFilepaths(String dirname) {
  List<FileSystemEntity> entities = scanDirFiles(dirname);

  final Iterable<String> files = entities.map((f) => f.path);
  return files.toList();
}

List<File> scanDirFiles(String dirname) {
  final dir = fileSystem.directory(dirname);
  return dir.listSync().whereType<File>().toList();
}

void copyDirPreserveLastModified(String from, String to) {
  var source = fileSystem.directory(from);
  var destination = fileSystem.directory(to);
  _copyDirPreserveLastModified(source, destination);
}

void _copyDirPreserveLastModified(Directory source, Directory destination) {
  source.listSync(recursive: false).forEach((var entity) {
    if (entity is Directory) {
      var newDirectory = fileSystem.directory(
          path.join(destination.absolute.path, path.basename(entity.path)));
      newDirectory.createSync();

      _copyDirPreserveLastModified(entity.absolute, newDirectory);
    } else if (entity is File) {
      var copied = entity
          .copySync(path.join(destination.path, path.basename(entity.path)));
      copied.setLastModifiedSync(entity.lastModifiedSync());
    }
  });
}

String pivotD(String s) {
  return '$s/pivot';
}

String constD(String s) {
  return '$s/const';
}
