import 'dart:io';

import 'package:id3tag/id3tag.dart';
import 'package:m4a_tags_handler/Tags.dart';
import 'package:music_player/consts.dart' as CONSTS;

class ID3TagsV2 {
  final File file;
  late ID3Tag tags;
  late ID3TagReader parser;

  ID3TagsV2(this.file) {
    parser = ID3TagReader(file);
    tags = parser.readTagSync();
  }

  Tags getTags() {
    var genreFrameValue =
        tags.frameWithTypeAndName<TextInformation>('TCON')?.value;
    return Tags(
      title: tags.title,
      artist: tags.artist,
      album: tags.album,
      track: tags.track,
      genre: toGenreName(genreFrameValue),
    );
  }

  Picture? getPicture() {
    final pictures = parser.readTagSync().pictures;
    if (pictures.isNotEmpty) {
      return pictures[0];
    } else {
      return null;
    }
  }

  String? toGenreName(String? s) {
    if (s == null) return null;
    if (s == '') return null;
    int lidx = s.length - 1;
    if (s[0] != '(' || s[lidx] != ')') return s; // Return genre name

    // Find genre name by index
    String stringIdx = s.substring(1, lidx);

    int? idx = int.tryParse(stringIdx);
    if (idx == null ||
        idx < CONSTS.id3v1GenreLowerLimit ||
        idx > CONSTS.id3v1GenreUpperLimit) return s;
    return CONSTS.id3v1GenreList[idx];
  }
}
