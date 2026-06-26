import 'package:dart_tags/dart_tags.dart';
import 'package:m4a_tags_handler/Tags.dart';

/// Throws exception (may throw)
Future<List<int>> addTagsToMp3Bytes(
    Future<List<int>> bytes, Tags tags, PictureTag? picture) async {
  final tp = TagProcessor();
  var iTags = await tp.getTagsFromByteArray(bytes);
  for (var f in iTags) {
    if (f.version == null) continue;

    if (f.version!.startsWith('1')) {
      f.tags['title'] = prepareID3v1NameString(tags.title);
      f.tags['artist'] = prepareID3v1NameString(tags.artist);
      f.tags['album'] = prepareID3v1NameString(tags.album);

      f.tags['genre'] = '';
      f.tags['year'] = '0';
      f.tags['comment'] = '';
      f.tags['track'] = '0';
    } else {
      f.tags['title'] = tags.title ?? '';
      f.tags['artist'] = tags.artist ?? '';
      f.tags['album'] = tags.album ?? '';
    }

    if (picture != null && f.version!.startsWith('2')) {
      const imageTypeCode = 0;
      String description = 'default_description';

      var newPic = AttachedPicture(
          picture.mime, imageTypeCode, description, picture.bytes);
      f.tags['picture'] = {'Other': newPic};
    }
  }

  return tp.putTagsToByteArray(bytes, iTags);
}

String prepareID3v1NameString(String? s) {
  return truncate(s, 30).replaceAll(RegExp(r'[^A-Za-z0-9().,;?]'), ' ');
}

String truncate(String? text, int length) {
  if (text == null) return '';
  if (length >= text.length) {
    return text;
  }
  return text.substring(0, length);
}
