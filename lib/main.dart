import 'dart:io';

import 'package:flutter/material.dart';
import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logger.dart';
import 'package:music_player/logic/Syncing.dart' show useWsServer;
import 'package:music_player/logic/audioNotificationHandler.dart';

import 'package:music_player/logic/Config.dart';
import 'package:music_player/logic/fs/files.dart' as fs;
import 'package:music_player/logic/utils_flutter.dart' as utils_flutter;

import 'view/App.dart';

Config config = Config();

void main(List<String> args) async {
  if (CONFIG.isMemoryFs) {
    final dir = '${Directory.current.path}/test_targets';
    fs.initMemoryFs(dir);
  }

  if (CONFIG.isUseWsServer) {
    final testDirServer =
        '${Directory.current.path}/test_targets/music_playlists/server';
    final testDirPlaylistsServer = testDirServer;
    useWsServer(testDirServer, testDirPlaylistsServer);
  }

  WidgetsFlutterBinding.ensureInitialized();
  config.cliArgs = args;
  await config.init();
  MyAudioHandler? audioHandler = await initAudioService();

  logFilepath = config.logFilepath;
  Logger.setLogLevels(
    isLogToFile: config.getProperty('logging.isLogToFile'),
    isLogDebug: config.getProperty('logging.isLogDebug'),
    isLogTrace: config.getProperty('logging.isLogTrace'),
    isLogView: config.getProperty('logging.isLogView'),
    isLogBuild: config.getProperty('logging.isLogBuild'),
  );
  if (CONFIG.isDev()) {
    gLogger.log('Enabling logfile assertion');
    gLogger.isAssertLogFile = true;
  }
  gLogger.log('CliArgs=${config.cliArgs}');

  if (config.getProperty('isCheckCertificate') ?? false) {
    gLogger.warn('Certificate check disbled');
    HttpOverrides.global = _MyHttpOverrides();
  }
  try {
    await utils_flutter.addLicense();
    // await utils_flutter.genNoticeFile();
    runApp(App(audioHandler));
  } catch (e) {
    gLogger.error('main catch: $e');
    rethrow;
  }
}

class _MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
