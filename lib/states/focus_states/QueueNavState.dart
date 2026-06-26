import 'package:music_player/consts.dart' as CONSTS;
import 'package:music_player/logic/bindings/BindingsHandler.dart';
import 'package:music_player/logic/bindings/PlaybackKeybindings.dart';
import 'package:music_player/logic/enums.dart';
import 'package:music_player/logic/tapHandlers.dart';
import 'package:music_player/states/FocusState.dart';
import 'package:music_player/states/focus_states/FocusStateInterface.dart';
import 'package:music_player/states/focus_states/SimpleListNavigator.dart';

typedef KA = KeyboardAction;

class QueueNavStatePattern extends KeyboardStateBase {
  FocusManagerState focusState;
  PlaybackKeybindings playbackKeybindings;
  late void Function() update;

  @override
  String type = 'QueueNav';

  late SimpleListNavigator listNav;

  int _getLength() {
    return focusState.playback.queue.length;
  }

  QueueNavStatePattern(
      {required this.focusState, required this.playbackKeybindings}) {
    update = focusState.update;
    listNav = SimpleListNavigator(getLength: _getLength);

    _initHandlers();
  }

  void _initHandlers() {
    keyBindings = [
      KeyBinding(
        fullname: KA.choose.name,
        keyEvents: [KeyEventType.down],
        handler: () {
          if (listNav.isInBounds(listNav.index)) {
            focusState.playback.playByIdx_n(listNav.index);
          }
          return this;
        },
      ),
      KeyBinding(
        fullname: KA.focus_left_pane.name,
        keyEvents: [KeyEventType.down],
        handler: () {
          return focusState.bodyNavState;
        },
      ),
      KeyBinding(
        fullname: KA.show_item_dialog.name,
        keyEvents: [KeyEventType.down],
        handler: () {
          final idx = listNav.index;
          final item = focusState.playback.queue.getMusicItem(idx);
          showItemDialog(idx, item, sectionIndex: CONSTS.queueSectionIdx);
          return null;
        },
      ),
      KeyBinding(
        fullname: KA.focus_search.name,
        keyEvents: [KeyEventType.up],
        handler: () {
          focusSearch();
          return null;
        },
      ),
    ];
    keyBindings.addAll(SimpleListNavigator.getKeybindings(listNav, update));
    keyBindings.addAll(playbackKeybindings.getKeybindings());
    namespaceKeyBindingsNames();
  }

  void putFocusInScrollU(ListNavitatorScrollProps props) {
    if (listNav.putFocusInScroll(props)) {
      update();
    }
  }
}
