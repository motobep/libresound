import 'package:music_player/consts.dart' as CONSTS;
import 'package:music_player/logger.dart';
import 'package:music_player/logic/bindings/BindingsHandler.dart';
import 'package:music_player/logic/enums.dart';
import 'package:music_player/logic/playback/Playback.dart';
import 'package:music_player/logic/tapHandlers.dart';

typedef KA = KeyboardAction;

class PlaybackKeybindings {
  Playback playback;

  PlaybackKeybindings({
    required this.playback,
  });

  List<KeyBinding> getKeybindings() {
    return [
      KeyBinding(
        fullname: KA.toggle_playback.name,
        keyEvents: [KeyEventType.down],
        handler: () {
          if (!playback.isIdle()) {
            playback.togglePlayback();
          } else {
            gLogger.log('Idle toggle');
          }
          return null;
        },
      ),
      KeyBinding(
        fullname: KA.play_prev.name,
        keyEvents: [KeyEventType.down],
        handler: () {
          if (playback.canPrev) {
            playback.playPrev();
          }
          return null;
        },
      ),
      KeyBinding(
        fullname: KA.play_next.name,
        keyEvents: [KeyEventType.down],
        handler: () {
          if (playback.canNext) {
            playback.playNext();
          }
          return null;
        },
      ),
      KeyBinding(
        fullname: KA.shuffle.name,
        keyEvents: [KeyEventType.down],
        handler: () {
          if (!playback.isIdle()) {
            playback.shuffle();
          }
          return null;
        },
      ),
      KeyBinding(
        fullname: KA.toggle_repeat.name,
        keyEvents: [KeyEventType.down],
        handler: () {
          playback.toggleRepeat();
          return null;
        },
      ),
      KeyBinding(
        fullname: KA.show_current_item_dialog.name,
        keyEvents: [KeyEventType.down],
        handler: () {
          final mi = playback.getCurrentMusicItem();
          showCurrItemDialog(mi, sectionIndex: CONSTS.queueSectionIdx);
          return null;
        },
      ),
    ];
  }
}
