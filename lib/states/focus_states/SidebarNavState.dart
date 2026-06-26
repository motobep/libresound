import 'package:music_player/logic/bindings/BindingsHandler.dart';
import 'package:music_player/logic/bindings/PlaybackKeybindings.dart';
import 'package:music_player/logic/enums.dart';
import 'package:music_player/states/FocusState.dart';
import 'package:music_player/states/focus_states/FocusStateInterface.dart';
import 'package:music_player/states/focus_states/SimpleListNavigator.dart';

typedef KA = KeyboardAction;

class SidebarNavStatePattern extends KeyboardStateBase {
  FocusManagerState focusState;
  PlaybackKeybindings playbackKeybindings;
  late void Function() update;

  @override
  String type = 'SidebarNav';

  SidebarNavStatePattern(
      {required this.focusState, required this.playbackKeybindings}) {
    update = focusState.update;
    listNav = SimpleListNavigator(getLength: _getLength);

    _initHandlers();
  }

  late SimpleListNavigator listNav;

  int _getLength() {
    return focusState.appState.getSidebarButtonOnTaps().length;
  }

  bool _isLocked = false;

  void chooseButton(int index) {
    assert(listNav.isInBounds(index), 'index out of bounds');
    listNav.index = index;
    focusState.appState.getSidebarButtonOnTaps()[index]();
    if (index >= 4) {
      // Source buttons
      _isLocked = false;
    } else {
      _isLocked = true;
    }
  }

  void _initHandlers() {
    keyBindings = [
      KeyBinding(
        fullname: KA.choose.name,
        keyEvents: [KeyEventType.down],
        handler: () {
          chooseButton(listNav.index);
          return this;
        },
      ),
      KeyBinding(
        fullname: KA.focus_right_pane.name,
        keyEvents: [KeyEventType.down],
        handler: () {
          if (_isLocked) return this;
          return focusState.bodyNavState;
        },
      ),
      KeyBinding(
        fullname: KA.focus_search.name,
        keyEvents: [KeyEventType.up],
        handler: () {
          if (_isLocked) return this;
          focusSearch();
          return null;
        },
      ),
      KeyBinding(
        fullname: KA.back.name,
        keyEvents: [KeyEventType.down],
        handler: () {
          if (focusState.appState.canBack()) {
            focusState.appState.back();
          }
          return this;
        },
      ),
    ];
    keyBindings.addAll(SimpleListNavigator.getKeybindings(listNav, update));
    // TODO later: make properly
    keyBindings.addAll(playbackKeybindings.getKeybindings());
    namespaceKeyBindingsNames();
  }

  void putFocusInScrollU(ListNavitatorScrollProps props) {
    if (listNav.putFocusInScroll(props)) {
      update();
    }
  }
}
