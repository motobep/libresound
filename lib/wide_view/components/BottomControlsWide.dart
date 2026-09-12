import 'package:music_player/logger.dart' show gLogger;
import 'package:music_player/states/AppState.dart';
import 'package:music_player/states/AppearanceState.dart';
import 'package:music_player/states/SelectionState.dart';
import 'package:music_player/view/PageRouter.dart' show PageRouter;
import 'package:music_player/view/components/Equalizer.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:music_player/states/PlaybackState.dart';

import 'package:music_player/consts.dart' as CONSTS;
import 'package:music_player/logic/tapHandlers.dart';
import 'package:music_player/logic/MusicItem.dart';
import 'package:music_player/logic/playback/Playback.dart' show Playback;

import 'package:music_player/view/components/VolumeControls.dart';
import 'package:music_player/view/pages/PlaybackControlsPage.dart';
import 'package:music_player/view/components/parts.dart' show TrackDescription;
import 'package:music_player/view/components/getIconFuncs.dart'
    show getPlayIcon, getRepeatIcon;

class BottomControlsWide extends StatelessWidget {
  const BottomControlsWide({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    Playback playback = context.watch<PlaybackState>().playback;
    IconData icon = getPlayIcon(playback.playState);
    IconData repeatIcon = getRepeatIcon(playback.repeatState);

    bool isSelectionHidden =
        context.select<SelectionState, bool>((s) => s.isEmpty);

    MusicItem musicItem = context.select<PlaybackState, MusicItem>(
        (s) => s.playback.getCurrentMusicItem());

    return Container(
      padding: const EdgeInsets.only(bottom: 2.0),
      color: Theme.of(context).colorScheme.surface,
      // color: Colors.blue,
      child: Column(
        children: [
          const PlaybackSlider(thumbRadius: 1.0, activeThumbRadius: 6.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.only(top: 2.0, bottom: 6.0, left: 8.0),
                    child: TrackDescription(
                      imgSize: 64,
                      musicItem: playback.getCurrentMusicItem(),
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: !playback.isIdle()
                            ? () {
                                playback.shuffle();
                              }
                            : null,
                        icon: const Icon(PhosphorIconsLight.shuffle),
                        iconSize: 22,
                      ),
                      IconButton(
                        onPressed: playback.canPrev
                            ? () {
                                playback.playPrev();
                              }
                            : null,
                        icon: const Icon(PhosphorIconsLight.skipBack),
                        iconSize: 26,
                      ),
                      IconButton(
                        onPressed: !playback.isIdle()
                            ? () async {
                                await playback.togglePlayback();
                              }
                            : null,
                        icon: Icon(icon),
                        iconSize: 32,
                      ),
                      IconButton(
                        onPressed: playback.canNext
                            ? () {
                                playback.playNext();
                              }
                            : null,
                        icon: const Icon(PhosphorIconsLight.skipForward),
                        iconSize: 26,
                      ),
                      IconButton(
                        onPressed: () {
                          playback.toggleRepeat();
                        },
                        icon: Icon(repeatIcon),
                        iconSize: 22,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    spacing: 4.0,
                    children: [
                      VolumeControls(isAlwaysVisible: !appState.isWide),
                      InkWell(
                        onTapUp: (details) {
                          var pos = details.globalPosition;
                          showEqualizerContextMenu(context, pos);
                        },
                        mouseCursor: SystemMouseCursors.click,
                        child: const Icon(PhosphorIconsThin.sliders),
                      ),
                      IconButton(
                        onPressed: isSelectionHidden
                            ? () {
                                showCurrItemDialog(musicItem,
                                    sectionIndex: CONSTS.queueSectionIdx);
                              }
                            : null,
                        icon:
                            const Icon(PhosphorIconsRegular.dotsThreeVertical),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void showEqualizerContextMenu(BuildContext context, Offset pos) {
  double vh = MediaQuery.of(context).size.height;
  double vw = MediaQuery.of(context).size.width;
  const double iconSize = 20;
  final double width = 560;
  final double height = 400;
  final top = pos.dy + height + 8.0 > vh ? pos.dy - height - iconSize : pos.dy;
  final left = pos.dx + width + 8.0 > vw ? pos.dx - width - iconSize : pos.dx;

  final appearanceState = Provider.of<AppearanceState>(context, listen: false);
  var equalizer =
      Provider.of<PlaybackState>(context, listen: false).playback.equalizer;

  showGeneralDialog(
    context: context,
    pageBuilder: (_, __, ___) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          gLogger.debug('didPop: $didPop');
          if (didPop) {
            return;
          }
          PageRouter.back(context);
        },
        child: Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              child: Material(
                child: Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: ColorScheme.of(context).surface,
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x20000000),
                          blurRadius: 12.0,
                          blurStyle: BlurStyle.outer)
                    ],
                    border: Border.all(
                        color: appearanceState.lerpBgColor(0.07), width: 1.0),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 14.0, horizontal: 16.0),
                  child: SizedBox(
                    height: height,
                    child: EqualizerWidget(equalizer: equalizer),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
    // barrierColor: Colors.black12,
    barrierColor: Colors.transparent,
    barrierDismissible: true,
    barrierLabel: 'barrier_label',
  );
}
