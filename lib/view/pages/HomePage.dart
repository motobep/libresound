import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logger.dart';
import 'package:music_player/logic/enums.dart';
import 'package:provider/provider.dart';

import 'package:music_player/states/AppState.dart';
import 'package:music_player/states/PlaybackState.dart';

import 'package:music_player/view/App.dart'
    show bindingsHandler, keyboardHandler;
import 'package:music_player/view/snackBarFuncs.dart';
import 'package:music_player/view/pages/MainPage.dart';
import 'package:music_player/wide_view/pages/MainPageWide.dart';

import 'package:window_manager/window_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WindowListener {
  @override
  void initState() {
    // Prevent orientation change on small screens
    ui.FlutterView view =
        WidgetsBinding.instance.platformDispatcher.views.first;
    Size size = view.physicalSize / view.devicePixelRatio;
    double width = size.width;
    double height = size.height;
    // gLogger.log('init: ($width, $height)');
    final widthHor = max(width, height);
    final heightHor = min(width, height);
    // gLogger.log('w/h hor: ($widthHor, $heightHor)');

    if (widthHor <= CONFIG.widthWideStart ||
        heightHor <= CONFIG.heightWideStart) {
      gLogger.log('Restricting to portrait mode');
      SystemChrome.setPreferredOrientations(<DeviceOrientation>[
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      gLogger.log('No orientation restriction');
      SystemChrome.setPreferredOrientations(<DeviceOrientation>[]);
    }

    if (Platform.isLinux) {
      windowManager.addListener(this);
      _initAsync();
    }
    super.initState();

    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      ServicesBinding.instance.keyboard
          .addHandler(keyboardHandler.keyboardHandle);
      ServicesBinding.instance.keyboard
          .addHandler(keyboardHandler.lastKeyCodesNotifier);
    }

    if (bindingsHandler.isWriteDefaultMappingsFailed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        const msg = 'Couldn\'t save default to file. Filesystem error';
        showSnackBar(msg, context);
      });
    }
  }

  @override
  void dispose() {
    if (Platform.isLinux) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  void _initAsync() async {
    if (Platform.isLinux) {
      await windowManager.setPreventClose(true);
    }
  }

  @override
  void onWindowClose() async {
    if (Platform.isLinux) {
      gLogger.view('Closing window');
      bool isPreventClose = await windowManager.isPreventClose();
      if (isPreventClose) {
        // ignore: use_build_context_synchronously
        await Provider.of<PlaybackState>(context, listen: false)
            .playback
            .dispose();
        await windowManager.destroy();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var appState = Provider.of<AppState>(context, listen: false);
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > CONFIG.widthWideStart &&
          constraints.maxHeight > CONFIG.heightWideStart) {
        appState.isWide = true;

        // We don't have this on wide
        WidgetsBinding.instance.addPostFrameCallback((_) {
          appState.controlsSheetOpenDegree = OpenDegree.closed;
          appState.onSheetControlsToggle?.call(OpenDegree.closed);
        });

        return const MainPageWide();
      } else {
        appState.isWide = false;
        return const MainPage();
      }
    });
  }
}
