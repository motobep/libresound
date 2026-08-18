import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show File;
import 'package:music_player/logger.dart';
import 'package:path/path.dart' as p;
import 'package:music_player/config.dart' show fileSystem;

const int SIZE_OF_FILENAME_LENGTH_BYTES =
    1; // Maximum length of a filename is usually 255 bytes, so 1 byte is enough to contain its length

class FileDTO {
  late String filename;

  late Uint8List bContents;

  /// Gets the file extension of [path]: the portion of [basename] from the last
  /// `.` to the end (including the `.` itself).
  ///
  ///     p.extension('path/to/foo.dart');    // -> '.dart'
  ///     p.extension('path/to/foo');         // -> ''
  ///     p.extension('path.to/foo');         // -> ''
  ///     p.extension('path/to/foo.dart.js'); // -> '.js'
  ///
  /// If the file name starts with a `.`, then that is not considered the
  /// extension:
  ///
  ///     p.extension('~/.bashrc');    // -> ''
  ///     p.extension('~/.notes.txt'); // -> '.txt'
  String getExtension() {
    return p.extension(fileSystem.file(filename).path);
  }

  FileDTO(this.filename, this.bContents) {
    assert(filename.isNotEmpty, 'filename.length <= 0');
  }

  FileDTO.header(this.filename) {
    assert(filename.isNotEmpty, 'filename.length <= 0');
    bContents = Uint8List(0);
  }

  FileDTO.fromBytes(Uint8List bytes) {
    // FilnameLen
    int filenameLen = bytes[0];
    assert(filenameLen > 0, 'filenameLen <= 0');

    // Filname
    const int sflb = SIZE_OF_FILENAME_LENGTH_BYTES;
    Uint8List bFilename = bytes.sublist(sflb, sflb + filenameLen);
    filename = utf8.decode(bFilename);

    // Contents
    int contentsStart = sflb + filenameLen;
    bContents = bytes.sublist(contentsStart, bytes.length);
  }

  Uint8List toBytes() {
    Uint8List bFilename = utf8.encode(filename);
    Uint8List bFilenameSize = Uint8List.fromList([bFilename.length]);

    final size = bFilenameSize.length + bFilename.length + bContents.length;
    final filenameBoxEnd = bFilenameSize.length + bFilename.length;

    final bytes = Uint8List(size);
    // Filename length
    bytes.setRange(0, bFilenameSize.length, bFilenameSize);
    // Filename
    bytes.setRange(bFilenameSize.length, filenameBoxEnd, bFilename);
    // Contents
    bytes.setRange(
        filenameBoxEnd, filenameBoxEnd + bContents.length, bContents);
    return bytes;
  }

  static FileDTO fromFile(File file) {
    String filename = p.basename(file.path);

    try {
      Uint8List bContents = file.readAsBytesSync();
      return FileDTO(filename, bContents);
    } catch (e) {
      gLogger.error('Error in FileDTO.fromFile(): $e');
      rethrow;
    }
  }

  @override
  String toString() {
    return 'FileDTO: (filename: $filename)';
  }
}
