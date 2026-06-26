import 'package:music_player/logger.dart';
import 'package:music_player/states/AppState.dart' show AppState;
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import 'package:music_player/logic/playback/Playback.dart' show Playback;
import 'package:music_player/logic/MusicItem.dart';
import 'package:music_player/logic/enums.dart';

import 'package:music_player/states/AppearanceState.dart';
import 'package:music_player/states/PlaybackState.dart';

import 'package:music_player/view/components/parts.dart' show TrackDescription;
import 'package:music_player/view/components/getIconFuncs.dart'
    show getPlayIcon;
import 'package:music_player/view/components/ScrolledOpacityAnimation.dart';
import 'package:music_player/view/pages/PlaybackControlsPage.dart';

double maxControlsChildSize = -1;
double minControlsChildSize = -1;

final controlsSheetController = DraggableScrollableController();

void controlsSheetController_animateToZero() {
  controlsSheetController.animateTo(0,
      duration: const Duration(milliseconds: 200), curve: Curves.easeOutBack);
}

class BottomControls extends StatelessWidget {
  const BottomControls({
    super.key,
    required this.minControlsChildSizeArg,
    required this.viewPadding,
  });
  final double minControlsChildSizeArg;
  final EdgeInsets viewPadding;

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;

    maxControlsChildSize = 1.0;
    minControlsChildSize = minControlsChildSizeArg;

    var appState = Provider.of<AppState>(context, listen: false);

    if (controlsSheetController.isAttached &&
        appState.controlsSheetOpenDegree == OpenDegree.closed &&
        controlsSheetController.size > minControlsChildSizeArg) {
      // TODO: use StatefulWidget
      controlsSheetController.reset();
    }

    return DraggableScrollableSheet(
      snapAnimationDuration: const Duration(milliseconds: 180),
      snap: true,
      minChildSize: minControlsChildSizeArg,
      initialChildSize: minControlsChildSizeArg,
      maxChildSize: maxControlsChildSize,
      controller: controlsSheetController,
      builder: (BuildContext context, ScrollController scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Material(
            child: Stack(
              children: [
                SizedBox(
                    height: height - (viewPadding.top + viewPadding.bottom),
                    child: PlaybackControlsBody(onCloseTap: () {
                      gLogger.view('To=$minControlsChildSizeArg');
                      controlsSheetController.animateTo(minControlsChildSizeArg,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutBack);
                    })),
                Positioned(
                  left: 0,
                  top: 0,
                  child: ScrolledOpacityAnimation(
                    sheetController: controlsSheetController,
                    fadeInPercent: minControlsChildSizeArg,
                    fadeOutPercent: 0.3,
                    child: _BottomControlsBody(
                      onTap: () {
                        gLogger.view('animateTo ${maxControlsChildSize}');
                        controlsSheetController.animateTo(maxControlsChildSize,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutBack);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        // return const _BottomControlsBody();
      },
    );

    // return Dismissible(
    //   key: UniqueKey(),
    //   onDismissed: (direction) {
    //     playback.deleteQueue();
    //   },
    //   direction: DismissDirection.down,
    //   child: const _BottomControlsBody(),
    // );
  }
}

class _BottomControlsBody extends StatelessWidget {
  const _BottomControlsBody({required this.onTap});

  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);

    Playback playback =
        Provider.of<PlaybackState>(context, listen: false).playback;

    MusicItem mi = context.select<PlaybackState, MusicItem>(
        (s) => s.playback.getCurrentMusicItem());
    bool playback_canNext =
        context.select<PlaybackState, bool>((s) => s.playback.canNext);
    bool playback_canPrev =
        context.select<PlaybackState, bool>((s) => s.playback.canPrev);
    PlayState playback_playState =
        context.select<PlaybackState, PlayState>((s) => s.playback.playState);
    IconData icon = getPlayIcon(playback_playState);

    double width = MediaQuery.of(context).size.width;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            Builder(
              builder: (ctx) => LinearProgressIndicator(
                color: ColorScheme.of(context).primary,
                backgroundColor: appearanceState.inactiveTrackColor(),
                value: ctx.select<PlaybackState, double>(
                    (s) => s.playback.progressRatio),
                minHeight: 1,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration:
                  BoxDecoration(color: Theme.of(context).colorScheme.surface),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    flex: 1,
                    child: TrackDescription(
                      imgSize: 45,
                      musicItem: mi,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                          onPressed: playback_canPrev
                              ? () async {
                                  await playback.playPrev();
                                }
                              : null,
                          icon: const Icon(PhosphorIconsLight.skipBack)),
                      IconButton(
                          onPressed: () async {
                            await playback.togglePlayback();
                          },
                          icon: Icon(icon)),
                      IconButton(
                          onPressed: playback_canNext
                              ? () async {
                                  await playback.playNext();
                                }
                              : null,
                          icon: const Icon(PhosphorIconsLight.skipForward)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
