import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;

void main(List<String> args) async {
  // print(args);
  void checkArgs(int num) {
    if (args.length < num) {
      print('Minimum amount of args is $num');
      exit(1);
    }
  }

  checkArgs(1);

  switch (args[0]) {
    case 'apk_release':
      final f = File('./build/app/outputs/flutter-apk/app-release.apk');
      final targetFile = File('./ignore/downloads/libresound.apk');

      final targetDir = Directory(path.dirname(targetFile.path));
      if (!targetDir.existsSync()) targetDir.createSync(recursive: true);

      f.copySync(targetFile.path);
      break;
    case 'appbundle_release':
      final f = File('./build/app/outputs/bundle/release/app-release.aab');
      final targetFile = File('./ignore/downloads/libresound.aab');

      final targetDir = Directory(path.dirname(targetFile.path));
      if (!targetDir.existsSync()) targetDir.createSync(recursive: true);

      f.copySync(targetFile.path);
      break;
    case 'linux_release':
      zipDirectory('./build/linux/x64/release/bundle/',
          './ignore/downloads/libresound_linux_x64.zip');
      break;
    case 'windows_release':
      zipDirectory('./build/windows/x64/runner/Release/',
          './ignore/downloads/libresound_windows_x64.zip');
      break;

    default:
      print('Not a proper argument "${args[0]}"');
  }
}

void zipDirectory(String dirpath, String zipFilePath) {
  final dir = Directory(dirpath);
  final archive = Archive();
  final targetFile = File(zipFilePath);

  final targetDir = Directory(path.dirname(targetFile.path));
  if (!targetDir.existsSync()) targetDir.createSync(recursive: true);

  // Recursively add files and directories
  void addFiles(Directory directory, String basePath) {
    for (var entity in directory.listSync()) {
      if (entity is File) {
        final fname = entity.path.replaceFirst(basePath, 'libresound/');
        print(fname);
        final fileBytes = entity.readAsBytesSync();
        final archiveFile = ArchiveFile(
          fname,
          fileBytes.length,
          fileBytes,
        );
        archive.addFile(archiveFile);
      } else if (entity is Directory) {
        addFiles(entity, basePath);
      }
    }
  }

  print('zip "${dir.path}" -> $zipFilePath');
  addFiles(dir, dir.path);

  // Encode the archive as a zip file
  final zipData = ZipEncoder().encode(archive);
  if (zipData == null) {
    print('Error: zipData is null');
    return;
  }

  targetFile.writeAsBytesSync(zipData);
}

