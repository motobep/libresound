import 'dart:convert' show base64;
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart'
    show
        LicenseEntry,
        LicenseEntryWithLineBreaks,
        LicenseRegistry,
        consolidateHttpClientResponseBytes;

import 'package:flutter/services.dart'
    show ByteData, FontLoader, Uint8List, rootBundle;
import 'package:m4a_tags_handler/Tags.dart';
import 'package:music_player/logger.dart';

import 'package:music_player/logic/getDeviceInfo.dart';
import 'package:permission_handler/permission_handler.dart';

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

Future<bool> requestManageExternalStorage() async {
  if (!Platform.isAndroid) return false;

  // For Android 13 and above
  int sdk = await getAndroidSdkVersion();
  if (sdk < 33) return false;

  PermissionStatus status = await Permission.manageExternalStorage.status;
  if (!status.isGranted) {
    return (await Permission.manageExternalStorage.request()).isGranted;
  }
  return status.isGranted;
}

Future<bool> requestAudioPermission() async {
  // For Android 13 and above
  if (Platform.isAndroid) {
    int sdk = await getAndroidSdkVersion();
    if (sdk >= 33) {
      PermissionStatus status = await Permission.audio.status;
      if (!status.isGranted) {
        return (await Permission.audio.request()).isGranted;
      }
      return status.isGranted;
    }
  }

  // For Android below 12 and other OS
  if (Platform.isAndroid || Platform.isIOS || Platform.isWindows) {
    PermissionStatus status = await Permission.storage.status;
    if (!status.isGranted) {
      return (await Permission.storage.request()).isGranted;
    }
    return status.isGranted;
  } else {
    // Linux
    return true;
  }
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

/// Retries 2 times
Future<PictureTag?> downloadPictureAsync(String url, HttpClient client) async {
  try {
    final HttpClientResponse response =
        await _fetchWithRetry(url, client, maxRetries: 2);
    final Uint8List bytes = await consolidateHttpClientResponseBytes(response);

    String? mimeContentType = response.headers.contentType?.mimeType;
    return bytesToPictureTag(bytes, mimeType: mimeContentType);
  } catch (e) {
    gLogger.error('downloadPicture(): Exception downloading image data: $e');
    return null;
  }
}

PictureTag bytesToPictureTag(Uint8List bytes, {String? mimeType}) {
  final picture = PictureTag(mime: mimeType ?? 'image/jpeg', bytes: bytes);
  return picture;
}

/// Throws
Future<HttpClientResponse> _fetchWithRetry(String url, HttpClient client,
    {required int maxRetries}) async {
  final int maxTries = 1 + maxRetries;
  const int baseDelayMs = 200;

  for (int attempt = 1; attempt <= maxTries; attempt++) {
    try {
      if (attempt > 1) gLogger.log('_fetchWithRetry retrying: ${attempt}');
      var urlObj = Uri.parse(url);
      final HttpClientRequest request = await client.getUrl(urlObj);
      final HttpClientResponse response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw Exception('Bad status: ${response.statusCode} for "$url"');
      }
      return response;
    } catch (e) {
      gLogger.warn(e);
      if (attempt < maxTries) {
        gLogger.warn('Retrying');
        var delayMs = baseDelayMs * (attempt + 1);
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }
  throw Exception('Failed fetch after $maxTries attempts');
}

/// TTF or OTF format.
/// Returns error message or null if there is no error.
Future<String?> loadFont(String name, String path) async {
  RegExp regex = RegExp(r'\.(ttf|otf)$');
  bool found = regex.hasMatch(path);
  if (!found) {
    var err = 'File must have "ttf" or "otf" extension.';
    gLogger.warn(err);
    return err;
  }

  try {
    var fontLoader = FontLoader(name);
    fontLoader.addFont(_readFont(path));
    await fontLoader.load();
  } catch (e) {
    var err = '------------\nError loading font: $e.';
    gLogger.warn(err);
    return err;
  }

  return null;
}

Future<ByteData> _readFont(String path) async {
  var file = File(path);
  var bodyBytes = file.readAsBytesSync();

  return ByteData.view(bodyBytes.buffer);
}

String formatBottomLine(String time, String artist) {
  if (time == '0:00') {
    return artist;
  }
  return '$time · $artist';
}

List<List<String>> prefixList(List<List<String>> list, String prefix) {
  for (var t in list) {
    t[0] = '$prefix${t[0]}';
  }
  return list;
}

// Licenses functions
Future<void> addLicense() async {
  String s = await _loadAssetAstring();
  LicenseRegistry.addLicense(() => Stream<LicenseEntry>.value(
        LicenseEntryWithLineBreaks(
          ['libresound'],
          s,
        ),
      ));
}

Future<void> genNoticeFile() async {
  final licenses = await LicenseRegistry.licenses.toList();
  String contents = '';
  Map<String, dynamic> map = {};
  for (var l in licenses) {
    for (var p in l.packages) {
      final text =
          l.paragraphs.map<String>((paragraph) => paragraph.text).join('\n\n');
      if (!map.containsKey(p)) {
        map[p] = text;
      } else {
        String delim = '-' * 5;
        map[p] = '${map[p]}\n\n$delim\n\n$text';
      }
    }
  }
  var sortedKeys = map.keys.toList()..sort();
  for (var key in sortedKeys) {
    final title = key;
    final text = map[key];

    String delim = '-' * 50;
    contents += '$title\n\n$text\n\n$delim\n\n\n';
  }
  File('NOTICE').writeAsStringSync(contents);
}

Future<String> _loadAssetAstring() async {
  return await rootBundle.loadString('assets/LICENSE');
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
