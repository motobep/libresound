import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show File;
import 'package:music_player/logic/KeyValue.dart';
import 'package:music_player/logic/ws/FileDTO.dart';
import 'package:path/path.dart' as p;

class FileListInfoDTO {
  late List<KeyValue> list;

  FileListInfoDTO(this.list);

  FileListInfoDTO.fromBytes(Uint8List bytes) {
    String json = utf8.decode(bytes);
    list = jsonDecode(json).cast<KeyValue>();
  }

  Uint8List toBytes() {
    String json = jsonEncode(list);
    return utf8.encode(json);
  }

  static FileListInfoDTO fromFiles(List<File> files) {
    List<KeyValue> list = [];
    for (var f in files) {
      String filename = p.basename(f.path);
      int modified = f.lastModifiedSync().millisecondsSinceEpoch;
      KeyValue l = {filename: modified};
      list.add(l);
    }
    return FileListInfoDTO(list);
  }

  Set<FileDTO> toFileDTOSet() {
    Set<FileDTO> x = {};
    for (var m in list) {
      var fDto = FileDTO.header(m.keys.first, m.values.first);
      x.add(fDto);
    }
    return x;
  }

  static Set<FileDTO> differenceAsFileDtoSet(
      FileListInfoDTO a, FileListInfoDTO b) {
    Set<FileDTO> filePool = a.toFileDTOSet().difference(b.toFileDTOSet());
    return filePool;
  }

  static Set<FileDTO> filenamesDifferenceAsFileDtoSet(
      FileListInfoDTO a, FileListInfoDTO b) {
    var resultSet = a.toFileDTOSet();

    var aSet = a.toFileDTOSet();
    var bSet = b.toFileDTOSet();
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
