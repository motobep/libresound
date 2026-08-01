import 'package:flutter/material.dart' show IconData;
import 'package:music_player/config.dart' as CONFIG;
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:music_player/logic/enums.dart' show PlayState, RepeatState;

IconData getPlayIcon(PlayState playState) {
  if (CONFIG.isProd()) {
    switch (playState) {
      case PlayState.playing:
        return PhosphorIconsLight.pause;
      case PlayState.pause:
        return PhosphorIconsLight.play;
      case PlayState.endOfQueue:
        return PhosphorIconsLight.arrowsCounterClockwise;
      case PlayState.notReady:
        return PhosphorIconsLight.play;
      case PlayState.loading:
        return PhosphorIconsLight.stop;
      default:
        return PhosphorIconsLight.play;
    }
  }
  switch (playState) {
    case PlayState.playing:
      return PhosphorIconsLight.pause;
    case PlayState.pause:
      return PhosphorIconsLight.play;
    case PlayState.endOfQueue:
      return PhosphorIconsLight.arrowsCounterClockwise;
    case PlayState.notReady:
      return PhosphorIconsLight.arrowLineDown;
    case PlayState.loading:
      return PhosphorIconsLight.stop;
    default:
      return PhosphorIconsLight.x;
  }
}

IconData getPlayFillIcon(PlayState playState) {
  if (CONFIG.isProd()) {
    switch (playState) {
      case PlayState.playing:
        return PhosphorIconsFill.pause;
      case PlayState.pause:
        return PhosphorIconsFill.play;
      case PlayState.endOfQueue:
        return PhosphorIconsFill.arrowsCounterClockwise;
      case PlayState.notReady:
        return PhosphorIconsFill.play;
      case PlayState.loading:
        return PhosphorIconsFill.stop;
      default:
        return PhosphorIconsFill.play;
    }
  }

  switch (playState) {
    case PlayState.playing:
      return PhosphorIconsFill.pause;
    case PlayState.pause:
      return PhosphorIconsFill.play;
    case PlayState.endOfQueue:
      return PhosphorIconsFill.arrowsCounterClockwise;
    case PlayState.notReady:
      return PhosphorIconsFill.arrowLineDown;
    case PlayState.loading:
      return PhosphorIconsFill.stop;
    default:
      return PhosphorIconsFill.x;
  }
}

IconData getRepeatIcon(RepeatState repeatState) {
  switch (repeatState) {
    case RepeatState.norepeat:
      return PhosphorIconsLight.repeat;
    case RepeatState.repeatOne:
      return PhosphorIconsLight.repeatOnce;
    case RepeatState.repeatAll:
      return PhosphorIconsRegular.repeat;
  }
}
