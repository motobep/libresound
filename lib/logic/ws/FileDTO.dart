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

  /// Timestamp in milliseconds
  late int modified;
  late Uint8List bContents;
  String getExtension() {
    return p.extension(fileSystem.file(filename).path);
  }

  FileDTO(this.filename, this.modified, this.bContents) {
    assert(filename.isNotEmpty, 'filename.length <= 0');
  }

  FileDTO.header(this.filename, this.modified) {
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

    // Modified
    int modifiedStart = sflb + filenameLen;
    Uint8List bModified = bytes.sublist(modifiedStart, modifiedStart + 8);
    modified = bModified.buffer.asInt64List()[0];

    // Contents
    int contentsStart = modifiedStart + 8;
    bContents = bytes.sublist(contentsStart, bytes.length);
  }

  Uint8List toBytes() {
    Uint8List bFilename = utf8.encode(filename);
    Uint8List bFilenameLen = Uint8List.fromList([bFilename.length]);
    Uint8List bModified = Uint8List(8);
    bModified.buffer.asInt64List()[0] = modified;

    final size = bFilenameLen.length +
        bFilename.length +
        bModified.length +
        bContents.length;
    final modifiedStart = bFilenameLen.length + bFilename.length;
    final modifiedEnd = modifiedStart + bModified.length;

    final bytes = Uint8List(size);
    // Filename length
    bytes.setRange(0, bFilenameLen.length, bFilenameLen);
    // Filename
    bytes.setRange(bFilenameLen.length,
        modifiedStart, bFilename);
    // Modified
    bytes.setRange(modifiedStart,
        modifiedEnd, bModified);
    // Contents
    bytes.setRange(modifiedEnd,
        modifiedEnd + bContents.length, bContents);
    return bytes;
  }

  static FileDTO fromFile(File file) {
    String filename = p.basename(file.path);
    int modified = file.lastModifiedSync().millisecondsSinceEpoch;

    try {
      Uint8List bContents = file.readAsBytesSync();
      return FileDTO(filename, modified, bContents);
    } catch (e) {
      gLogger.error('Error in FileDTO.fromFile(): $e');
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is FileDTO &&
        filename == other.filename &&
        modified == other.modified;
  }

  @override
  int get hashCode => Object.hash(filename, modified);

  @override
  String toString() {
    return 'FileDTO: (filename: $filename, modified: $modified)';
  }

  static Set<FileDTO> filenameDifference(Set<FileDTO> aSet, Set<FileDTO> bSet) {
    Set<FileDTO> resultSet = Set.from(aSet);

    for (var aDto in aSet) {
      for (var bDto in bSet) {
        if (aDto.filename == bDto.filename) {
          resultSet.remove(aDto);
          break;
        }
      }
    }

    return resultSet;
  }
}
