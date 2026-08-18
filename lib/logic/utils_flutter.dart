import 'dart:io';

import 'package:music_player/logic/utils.dart' as utils;
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

/// Retries 2 times
Future<PictureTag?> downloadPictureAsync(String url, HttpClient client) async {
  try {
    final HttpClientResponse response =
        await _fetchWithRetry(url, client, maxRetries: 2);
    final Uint8List bytes = await consolidateHttpClientResponseBytes(response);

    String? mimeContentType = response.headers.contentType?.mimeType;
    return utils.bytesToPictureTag(bytes, mimeType: mimeContentType);
  } catch (e) {
    gLogger.error('downloadPicture(): Exception downloading image data: $e');
    return null;
  }
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
