import 'package:music_player/states/AppState.dart';
import 'package:music_player/states/SelectionState.dart';
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
                    children: [
                      VolumeControls(isAlwaysVisible: !appState.isWide),
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
