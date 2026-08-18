import 'dart:convert' show base64;
import 'dart:io';
import 'dart:typed_data' show Uint8List;

import 'package:path/path.dart' as path;

import 'package:m4a_tags_handler/Tags.dart';
import 'package:music_player/logger.dart';

String formatDuration(Duration duration) {
  String twoDigitMinutes = duration.inMinutes.toString();
  String twoDigitSeconds =
      duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$twoDigitMinutes:$twoDigitSeconds';
}

String escapeFilename(String name) {
  String str = name;
  // Reserved chars: |\?*<":>/
  Map<String, String> replaceMap = {
    '|': '[pipe]',
    '\\': '[backslash]',
    '?': '[question_mark]',
    '*': '[asterisk]',
    '<': '[less_than]',
    '>': '[more_than]',
    '"': '[double_quotes]',
    ':': '[colon]',
    '/': '[slash]',
  };
  for (var e in replaceMap.entries) {
    str = str.replaceAll(e.key, e.value);
  }
  return str;
}

List<String> prefixOrNotFilenames(List<String> filenames, String prefix) {
  return filenames
      .map((s) => s.startsWith('/') ? s : path.join(prefix, s))
      .toList();
}

bool checkEveryNotNull(List arr) {
  return arr.every((el) => el != null);
}

bool checkAnyHasNewline(List<String> arr) {
  return arr.any((s) => s.contains('\n'));
}

String relativeOrAbsolutePath(String path, String dir) {
  var els = path.split('$dir/');
  var filepath = els.length == 1 ? els[0] : els[1];
  return filepath;
}

bool isValidAbsolutePath(String path) {
  // Regexp for absolute filepath
  var re = RegExp(r'''^(\/|\p{Letter}:)[\p{Letter}\w\- \/.\\()'"]+$''',
      unicode: true);
  return re.hasMatch(path);
}

String removeTrailingSlash(String s) {
  if (s.endsWith('/')) {
    return s.substring(0, s.length - 1);
  }
  return s;
}

/// Throws Exception
Future<int> downloadFile(Uri uri, String path) async {
  var c = HttpClient();
  c.userAgent = null;
  final request = await c.getUrl(uri);
  final response = await request.close();
  await response.pipe(File(path).openWrite());
  return response.statusCode;
}

PictureTag bytesToPictureTag(Uint8List bytes, {String? mimeType}) {
  final picture = PictureTag(mime: mimeType ?? 'image/jpeg', bytes: bytes);
  return picture;
}

List<List<String>> prefixList(List<List<String>> list, String prefix) {
  for (var t in list) {
    t[0] = '$prefix${t[0]}';
  }
  return list;
}

String sanitize(String s) {
  return _sanitizeSingleQuotes(_sanitizeBackSlash(s));
}

String sanitizeWithTicks(String s) {
  return _sanitizeTicks(_sanitizeBackSlash(s));
}

String _sanitizeTicks(String s) {
  return s.replaceAll('`', '\\`');
}

String _sanitizeSingleQuotes(String s) {
  return s.replaceAll("'", "\\'");
}

String _sanitizeBackSlash(String s) {
  return s.replaceAll('\\', '\\\\');
}

String formatBytes(int bytes) {
  if (bytes == 0) return '0 Bytes';

  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
  int index = 0;

  double b = bytes.toDouble();
  while (b >= 1024 && index < suffixes.length - 1) {
    b /= 1024;
    index++;
  }

  return '${b.toStringAsFixed(2)} ${suffixes[index]}';
}

String btoa(String input) {
  return base64.encode(input.codeUnits);
}

String atob(String base64Str) {
  List<int> bytes = base64.decode(base64Str);
  return String.fromCharCodes(bytes);
}

/// Supported: png, jpeg
String? mimeFromPath(String path) {
  if (path.endsWith('.png')) return 'image/png';
  if (path.endsWith('.jpeg') || path.endsWith('.jpg')) return 'image/jpeg';
  return null;
}

/// Supported: png, jpeg
String? extensionFromMime(String mime) {
  if (mime == 'image/png') return 'png';
  if (mime == 'image/jpeg') return 'jpeg';
  return null;
}
