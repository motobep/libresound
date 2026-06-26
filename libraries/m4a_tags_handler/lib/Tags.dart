import 'dart:typed_data' show Uint8List;

class Tags {
  String? title;
  String? artist;
  String? album;
  String? year;
  String? track;
  String? genre;
  PictureTag? picture;

  Tags({
    this.title,
    this.artist,
    this.album,
    this.year,
    this.track,
    this.genre,
    this.picture,
  });

  bool hasNecessary() {
    return (title != null && artist != null && album != null && genre != null);
  }

  void show() {
    print('''Title: $title
Artist: $artist
Album: $album
Year: $year
Track: $track
Genre: $genre''');
  }
}

class PictureTag {
  final String mime; // image/jpeg or image/png
  final Uint8List bytes;

  PictureTag({required this.mime, required this.bytes})
      : assert(mime == 'image/jpeg' || mime == 'image/png', 'Wrong mime=$mime');

  PictureTag.fromMimeInt({required int mimeInt, required this.bytes})
      : assert(mimeInt == 13 || mimeInt == 14, 'Wrong mimeInt=$mimeInt'),
        mime = mimeInt == 13 ? 'image/jpeg' : 'image/png';

  int mimeToInt() {
    return mime == 'image/jpeg' ? 13 : 14;
  }
}
