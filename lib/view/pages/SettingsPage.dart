import 'dart:io';
import 'dart:math' show max;

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:music_player/logic/Config.dart' show Config;
import 'package:music_player/view/PageRouter.dart';
import 'package:music_player/view/components/VolumeControls.dart';
import 'package:music_player/view/components/inputs.dart';
import 'package:provider/provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart'
    show DefaultCacheManager;

import 'package:music_player/consts.dart' as CONSTS;
import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logger.dart';
import 'package:music_player/logic/lang.dart';

import 'package:music_player/states/AppState.dart' show AppState;
import 'package:music_player/states/AppearanceState.dart';
import 'package:music_player/states/PlaybackState.dart';

import 'package:music_player/view/components/Equalizer.dart';
import 'package:music_player/view/components/KeyBindigsTable.dart';
import 'package:music_player/view/snackBarFuncs.dart';
import 'package:music_player/view/components/buttons.dart'
    show chooseMusicDir, StandardButton, ToPageButton, getBackBtn;

final DateFormat _formatter = DateFormat('yy-MM-dd_HH-mm-ss');
const int lastLogLinesNum = 500;

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: getBackBtn(context),
      ),
      body: const SettingsBody(),
    );
  }
}

class Settings {
  List<String> pages = ['Main', 'Equalizer', 'KeyBindings', 'Log'];
  String currPage = 'Main';

  bool canBack() {
    return currPage != 'Main';
  }

  bool back() {
    if (canBack()) {
      currPage = 'Main';
      return false; // don't pop
    }
    return true; // pop
  }
}

class SettingsBody extends StatelessWidget {
  const SettingsBody({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    AppState appState = context.watch<AppState>();
    final settings = appState.settingsPages;
    var config = appState.config;
    String musicFolder = config.musicSourceDir?.path ?? "''";
    var equalizer =
        Provider.of<PlaybackState>(context, listen: false).playback.equalizer;

    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);

    Lang lang = context.select<AppearanceState, Lang>((s) => s.lang);

    List<Widget> widgets = switch (settings.currPage) {
      'Main' => [
          const SizedBox(height: 6.0),
          Heading(lang.Folder_with_music),
          const SizedBox(height: 2.0),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: SelectableText(musicFolder),
          ),
          const SizedBox(height: 10.0),
          StandardButton(lang.Choose, onTap: () => chooseMusicDir(context)),
          const SizedBox(height: 24.0),
          Heading(lang.Language),
          const SizedBox(height: 8.0),
          StandardButton('English', onTap: () {
            appearanceState.setLang(EnLang());
          }),
          const SizedBox(height: 8.0),
          StandardButton('Русский', onTap: () {
            appearanceState.setLang(RuLang());
          }),
          if (!CONFIG.isDisableDownloadPlugins) ...[
            const SizedBox(height: 24.0),
            Heading(lang.Plugins),
            const SizedBox(height: 8.0),
            Text(
              lang.Automatically_load_the_home_page_when_entering_the_plugins_page,
              softWrap: true,
              maxLines: 2,
            ),
            const SizedBox(height: 4.0),
            CheckboxInput(
              initial:
                  config.getProperty('isAutoLoadPluginHomePage', orElse: true),
              onSelect: (b) {
                gLogger.log('isAutoLoadPluginHomePage: $b');
                bool ok = config.saveProperty('isAutoLoadPluginHomePage', b);
                return ok;
              },
              isToggler: true,
            ),
            const SizedBox(height: 8.0),
            Text(
              lang.Automatic_check_for_plugin_updates,
              softWrap: true,
            ),
            const SizedBox(height: 4.0),
            CheckboxInput(
              initial:
                  config.getProperty('isAutoCheckPluginUpdates', orElse: true),
              onSelect: (b) {
                gLogger.log('isAutoCheckPluginUpdates: $b');
                bool ok = config.saveProperty('isAutoCheckPluginUpdates', b);
                return ok;
              },
              isToggler: true,
            ),
          ],
          const SizedBox(height: 10.0),
          if (!appState.isWide) ...[
            const SizedBox(height: 14.0),
            Heading(lang.Volume),
            const SizedBox(height: 6.0),
            const VolumeControls(isAlwaysVisible: true),
            const SizedBox(height: 10.0),
          ],
          const SizedBox(height: 14.0),
          Heading(lang.Cache),
          const SizedBox(height: 6.0),
          StandardButton(lang.Clear, onTap: () async {
            var messengerFunc = getSnackBarMessangerFunc(context);

            AppState appState = Provider.of<AppState>(context, listen: false);
            bool ok = appState.fsSource.deleteCachedFilesInfoConfig();

            await DefaultCacheManager().emptyCache();

            String msg = '';
            if (ok) {
              msg = lang.Cache_cleared;
              appState.reloadFsSource();
            } else {
              msg = lang.phrase__cache_errored;
            }
            messengerFunc(msg);
          }),
          if (CONFIG.isDev()) ...[
            const SizedBox(height: 10.0),
            StandardButton('Clean File Info Cache', onTap: () {
              AppState appState = Provider.of<AppState>(context, listen: false);
              bool ok = appState.fsSource.deleteCachedFilesInfoConfig();
              var msg = '';
              if (ok) {
                msg = 'Cache has been cleaned';
                appState.reloadFsSource();
              } else {
                msg = 'Something went wrong during cache cleaning';
              }
              showSnackBar(msg, context);
            }),
            const SizedBox(height: 10.0),
            StandardButton('Clean cached files', onTap: () async {
              var messengerFunc = getSnackBarMessangerFunc(context);
              await DefaultCacheManager().emptyCache();
              String msg = 'Cached files have been cleaned';
              messengerFunc(msg);
            }),
          ],
          const SizedBox(height: 10.0 + 8),
          if (Platform.isLinux || Platform.isAndroid) ...[
            const SizedBox(height: 14.0),
            ToPageButton(lang.Equalizer, onTap: () {
              settings.currPage = settings.pages[1];
              appState.update();
            }),
          ],
          if (Platform.isLinux || Platform.isWindows) ...[
            const SizedBox(height: 14.0),
            ToPageButton(lang.Key_bindings, onTap: () {
              settings.currPage = settings.pages[2];
              appState.update();
            }),
          ],
          const SizedBox(height: 14.0),
          ToPageButton(lang.Licenses, onTap: () {
            PageRouter.toPage(LicensePage(
              applicationName: 'LibreSound',
              applicationIcon: Image.asset(
                'assets/images/logo_mp_512_gaps.png',
                fit: BoxFit.contain,
                width: 50,
                height: 50,
              ),
            ));
          }),
          const SizedBox(height: 14.0),
          ToPageButton(lang.For_developers, onTap: () {
            settings.currPage = settings.pages[3];
            appState.update();
          }),
          const SizedBox(height: 40.0),
          const SelectableText('Build: "${CONFIG.buildVerbose}"',
              style: TextStyle(fontSize: 12.0)),
        ],
      'Equalizer' => [
          Heading(lang.Equalizer),
          const SizedBox(height: 6.0),
          EqualizerWidget(equalizer: equalizer),
        ],
      'KeyBindings' => [
          Heading(lang.Key_bindings),
          const KeyBindingsTable(),
        ],
      'Log' => [
          Heading(lang.For_developers),
          const SizedBox(height: 20.0),
          StandardButton('Copy log to clipboard', onTap: () async {
            final logFile = File(config.logFilepath);
            try {
              final contents = logFile.readAsStringSync();
              await Clipboard.setData(ClipboardData(text: contents));
            } catch (e) {
              gLogger.error('Exception copying log file to clipboard: $e');
            }
          }),
          const SizedBox(height: 10.0),
          StandardButton('Copy log to downloads', onTap: () async {
            try {
              final dirPath = switch (Platform.operatingSystem) {
                'android' => CONFIG.androidDefaultDownloadsDir,
                'linux' => '${Platform.environment["HOME"]}/Downloads',
                _ => ''
              };

              final Directory dir = Directory(dirPath);
              if (dir.existsSync()) {
                final f = File(logFilepath!);
                final dateStr = _formatter.format(DateTime.now());
                final newPath = '${dir.absolute.path}/mp_log_$dateStr.txt';
                f.copySync(newPath);
                gLogger.log('Logfile Copied to: $newPath');
              } else {
                gLogger.warn('No dir: $dir');
              }
            } catch (e) {
              gLogger.error('Exception copying log file to downloads: $e');
            }
          }),
          const SizedBox(height: 24.0),
          ..._getLogToggler(
              config, 'logging.isLogToFile', (b) => Logger.isLogToFile = b),
          ..._getLogToggler(
              config, 'logging.isLogDebug', (b) => Logger.isLogDebug = b),
          ..._getLogToggler(
              config, 'logging.isLogTrace', (b) => Logger.isLogTrace = b),
          ..._getLogToggler(
              config, 'logging.isLogView', (b) => Logger.isLogView = b),
          ..._getLogToggler(
              config, 'logging.isLogBuild', (b) => Logger.isLogBuild = b),
          const SizedBox(height: 24.0),
          const Heading('Watch Plugins Directories\n(app reload is necessary)'),
          const SizedBox(height: 6.0),
          CheckboxInput(
            isToggler: true,
            initial: config.getProperty('isWatchPluginDirs') ?? false,
            onSelect: (bool value) {
              gLogger.view('toggle watch plugins dir switch');
              bool v = config.getProperty('isWatchPluginDirs') ?? false;
              config.saveProperty('isWatchPluginDirs', !v);
              appState.update();
              return true;
            },
          ),
          const SizedBox(height: 24.0),
          const Heading('Disable certificate check\n(app reload is necessary)'),
          const SizedBox(height: 6.0),
          CheckboxInput(
            isToggler: true,
            initial: config.getProperty('isCheckCertificate') ?? false,
            onSelect: (bool value) {
              gLogger.view('toggle check certificate switch');
              bool v = config.getProperty('isCheckCertificate') ?? false;
              config.saveProperty('isCheckCertificate', !v);
              appState.update();
              return true;
            },
          ),
          const SizedBox(height: 20.0),
          ExpansionTile(
            title: const Text('Config'),
            expandedAlignment: Alignment.topLeft,
            children: <Widget>[
              Text(config.toString()),
            ],
          ),
          const SizedBox(height: 20.0),
          const Text('Log of last $lastLogLinesNum lines:'),
          const SizedBox(
            height: 500,
            child: SingleChildScrollView(
              reverse: true,
              child: _LogText(),
            ),
          ),
        ],
      _ => throw 'wrong branch',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CONFIG.pagePaddingHor,
        vertical: CONFIG.pagePaddingVert,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: widgets,
        ),
      ),
    );
  }
}

class _LogText extends StatelessWidget {
  const _LogText();

  @override
  Widget build(BuildContext context) {
    try {
      var logfile = File(logFilepath!);
      var logLines = logfile.readAsLinesSync();

      List<TextSpan> spans = [];
      int toSkip = max(logLines.length - lastLogLinesNum, 0);
      for (var l in logLines.skip(toSkip)) {
        String text = l;
        text = '${text.replaceAll(CONSTS.colorMap['reset']!, '')}\n';
        TextSpan? span;
        for (var key in CONSTS.colorMap.keys) {
          if (l.contains(CONSTS.colorMap[key]!)) {
            text = text.replaceAll(CONSTS.colorMap[key]!, '');
            span = TextSpan(
                text: text,
                style: TextStyle(
                  color: colors[key],
                  fontFamily: 'monospace',
                ));
            break;
          }
        }
        span ??= TextSpan(text: text);
        spans.add(span);
      }
      return RichText(text: TextSpan(children: spans));
    } catch (e, s) {
      gLogger.exception('_LogText', e, s);
      return const SizedBox.shrink();
    }
  }

  static const Map<String, Color> colors = {
    'black': Colors.black,
    'red': Colors.red,
    'green': Colors.green,
    'yellow': Colors.yellow,
    'blue': Colors.blue,
    'magenta': Colors.purple,
    'cyan': Colors.cyan,
    'white': Colors.white,
  };
}

class Heading extends StatelessWidget {
  final String text;
  const Heading(
    this.text, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 18.0));
  }
}

List<Widget> _getLogToggler(
    Config config, String propName, void Function(bool b) fn) {
  return [
    Heading(propName.split('.').last),
    const SizedBox(height: 6.0),
    CheckboxInput(
      isToggler: true,
      initial: config.getProperty(propName) ?? false,
      onSelect: (bool value) {
        gLogger.view('${propName}: $value');
        bool b = !(config.getProperty(propName) ?? false);
        config.saveProperty(propName, b);
        fn(b);
        return true;
      },
    )
  ];
}
