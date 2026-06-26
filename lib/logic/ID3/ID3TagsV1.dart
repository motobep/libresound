import 'dart:typed_data';

import 'package:m4a_tags_handler/Tags.dart';
import 'package:music_player/consts.dart' as CONSTS;

class ID3TagsV1 {
  final Uint8List list;

  final Tags tags = Tags();

  int pos = 0;

  ID3TagsV1(this.list) {
    tags.title = next(30);
    tags.artist = next(30);
    tags.album = next(30);
    tags.year = next(4);
    next(28); // Skipping comment bytes
    next(1); // Skipping zero byte
    tags.track = next(1);
    tags.genre = toGenreName(next(1));
  }

  Tags getTags() {
    return tags;
  }

  String? next(int take) {
    var s = listAsString(list, pos, pos + take);
    pos += take;
    return s != '' ? s : null;
  }

  String? toGenreName(String? s) {
    if (s == null) return null;
    int? idx = int.tryParse(s);
    if (idx == null ||
        idx < CONSTS.id3v1GenreLowerLimit ||
        idx > CONSTS.id3v1GenreUpperLimit) return null;
    return CONSTS.id3v1GenreList[idx];
  }
}

String listAsString(Uint8List list, int start, int end) {
  return String.fromCharCodes(
      list.sublist(start, end).where((el) => el != 0 && el != 255));
}
