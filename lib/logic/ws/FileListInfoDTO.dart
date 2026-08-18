import 'dart:convert';
import 'dart:typed_data';
import 'package:music_player/logic/KeyValue.dart';

import 'package:collection/collection.dart';

class FileInfo {
  String filename;
  int size;
  List<int> hash;

  FileInfo(this.filename, this.size, this.hash);

  static FileInfo fromJson(dynamic m) {
    return FileInfo(m['filename'], m['size'], m['hash'].cast<int>());
  }

  toJson() {
    return {
      'filename': filename,
      'size': size,
      'hash': hash,
    };
  }

  @override
  String toString() {
    return '($filename,\n\tsize: $size,\n\thash: $hash)';
  }
}

class FileInfoList {
  List<FileInfo> list = [];

  FileInfoList([this.list = const []]);

  FileInfoList.fromBytes(Uint8List bytes) {
    String json = utf8.decode(bytes);
    var listObj = jsonDecode(json).cast<KeyValue>();
    for (var el in listObj) {
      final info = FileInfo.fromJson(el);
      list.add(info);
    }
  }

  Uint8List toBytes() {
    String json = jsonEncode(list);
    return utf8.encode(json);
  }

  static FileInfoList fullDifference(FileInfoList left, FileInfoList right) {
    FileInfoList result = FileInfoList(List.from(left.list));
    const eq = ListEquality();
    for (var a in left.list) {
      for (var b in right.list) {
        if (a.filename == b.filename &&
            a.size == b.size &&
            eq.equals(a.hash, b.hash)) {
          result.list.remove(a);
          break;
        }
      }
    }
    return result;
  }

  static FileInfoList filenameDifference(
      FileInfoList left, FileInfoList right) {
    FileInfoList result = FileInfoList(List.from(left.list));
    for (var a in left.list) {
      for (var b in right.list) {
        if (a.filename == b.filename) {
          result.list.remove(a);
          break;
        }
      }
    }
    return result;
  }
}
