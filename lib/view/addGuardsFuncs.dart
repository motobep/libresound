import 'dart:io' show Directory, File, Platform;

import 'package:flutter/material.dart';
import 'package:music_player/logger.dart';
import 'package:music_player/logic/fs/files.dart' as fs;
import 'package:music_player/logic/lang.dart';
import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/states/AppearanceState.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import 'package:music_player/states/AppState.dart';

import 'package:music_player/view/components/buttons.dart';

Widget addGuardsToPageBody(Widget body, BuildContext context) {
  AppState appState = Provider.of<AppState>(context, listen: false);
  // bool isShowGrantStorageAccess =
  //     context.select<AppState, bool>((s) => s.isShowGrantStorageAccess);
  bool isShowChooseMusicDir =
      context.select<AppState, bool>((s) => s.isShowChooseMusicDir);
  bool isAudioAccessGranted =
      context.select<AppState, bool>((s) => s.isAudioAccessGranted);

  var currentSource =
      Provider.of<AppState>(context, listen: false).currentSource;
  var isSourceLoaded = context.select<AppState, bool>((s) => s.isSourceLoaded);
  var errorMsg =
      context.select<AppState, String>((s) => s.currentSource.errorMsg);

  if (!isAudioAccessGranted) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(lang.Grant_audio_permission),
          const SizedBox(
            height: 10,
          ),
          StandardButton(lang.Grant, onTap: () {
            appState.tryGrantAudioAccess();
            appState.update();
          }),
        ],
      ),
    );
  } else if (isShowChooseMusicDir) {
    return const SelectSourceDir();
  } else if (!isSourceLoaded) {
    return const Center(
      child: SizedBox(
          width: 35,
          height: 35,
          child: CircularProgressIndicator(strokeWidth: 3)),
    );
  } else if (errorMsg != '') {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(errorMsg, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 14),
          StandardButton(lang.Reload, onTap: () {
            gLogger.view('reload');
            currentSource.reloadAsync();
          })
        ],
      )),
    );
  }
  return body;
}

class SelectSourceDir extends StatelessWidget {
  const SelectSourceDir({
    super.key,
    this.onSelect,
  });

  final void Function()? onSelect;

  @override
  Widget build(BuildContext context) {
    logger.build('SelectSourceDir');
    logger.debug('SelectSourceDir');
    final androidMusicDir = Directory(CONFIG.androidDefaultMusicDir);
    final androidDownloadsDir = Directory(CONFIG.androidDefaultDownloadsDir);
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);

    List<Widget> androidWidgets = [];
    if (Platform.isAndroid &&
        (androidMusicDir.existsSync() || androidDownloadsDir.existsSync())) {
      List<File>? musicDirFiles;
      List<File>? downloadsDirFiles;

      try {
        musicDirFiles = fs.fetchMusicFiles(CONFIG.androidDefaultMusicDir);
        logger.debug('musicDirFiles: ${musicDirFiles.length}');
      } catch (e, s) {
        gLogger.exception('musicDirFiles', e, s);
      }
      try {
        downloadsDirFiles =
            fs.fetchMusicFiles(CONFIG.androidDefaultDownloadsDir);
      } catch (e, s) {
        gLogger.exception('downloadsDirFiles', e, s);
      }
      if (musicDirFiles == null && downloadsDirFiles == null) {
        androidWidgets = [];
      } else {
        androidWidgets = [
          Container(
            width: 330,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              border: Border.all(
                  color: appearanceState.lerpBgColor(0.07), width: 1.0),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              children: [
                Text(
                  lang.Quick_pick,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(
                  height: 18,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (musicDirFiles != null)
                      Column(
                        children: [
                          const Icon(PhosphorIconsThin.musicNotes, size: 30),
                          const SizedBox(
                            height: 8,
                          ),
                          Text(
                            lang.Music_folder,
                            // textAlign: TextAlign.center,
                          ),
                          // TODO: implement properly
                          Text(
                            '${musicDirFiles.length} ${lang.tracks__genetive}',
                            style: TextStyle(
                                color: ColorScheme.of(context).secondary),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          StandardButton(lang.Choose, onTap: () async {
                            onSelect?.call();
                            await loadMusicDir(
                                context, CONFIG.androidDefaultMusicDir);
                          }),
                        ],
                      ),
                    const SizedBox(
                      width: 38,
                    ),
                    if (downloadsDirFiles != null)
                      Column(
                        children: [
                          const Icon(PhosphorIconsThin.download, size: 30),
                          const SizedBox(
                            height: 8,
                          ),
                          Text(
                            lang.Downloads_folder,
                            textAlign: TextAlign.center,
                          ),
                          // TODO: implement properly
                          Text(
                            '${downloadsDirFiles.length} ${lang.tracks__genetive}',
                            style: TextStyle(
                                color: ColorScheme.of(context).secondary),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          StandardButton(lang.Choose, onTap: () async {
                            onSelect?.call();
                            await loadMusicDir(
                                context, CONFIG.androidDefaultDownloadsDir);
                          }),
                        ],
                      )
                  ],
                ),
              ],
            ),
          ),
          // Padding(
          //   padding: const EdgeInsets.symmetric(vertical: 30.0),
          //   child: Text(lang.Or),
          // ),
        ];
      }
    }

    Widget pcWidget = _PickButton(
      onTap: () {
        onSelect?.call();
        chooseMusicDir(context);
      },
      child: Column(
        children: [
          const Icon(PhosphorIconsThin.folderOpen, size: 30),
          const SizedBox(
            height: 5,
          ),
          SizedBox(
            width: 250,
            child: Text(
              lang.Select_the_music_folder,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          StandardButton(lang.Choose, onTap: () {
            onSelect?.call();
            chooseMusicDir(context);
          }),
        ],
      ),
    );

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (Platform.isAndroid) ...androidWidgets,
          if (!Platform.isAndroid) pcWidget,
        ],
      ),
    );
  }
}

class _PickButton extends StatelessWidget {
  const _PickButton({
    required this.child,
    required this.onTap,
  });
  final Widget child;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);

    return InkWell(
      onTap: onTap,
      child: Container(
        width: 330,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 28),
        decoration: BoxDecoration(
          border:
              Border.all(color: appearanceState.lerpBgColor(0.07), width: 1.0),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: child,
      ),
    );
  }
}
