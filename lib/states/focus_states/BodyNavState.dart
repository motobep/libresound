import 'package:music_player/config.dart' as CONFIG;

import 'package:music_player/logic/bindings/BindingsHandler.dart';
import 'package:music_player/logic/bindings/PlaybackKeybindings.dart';
import 'package:music_player/logic/enums.dart';
import 'package:music_player/logic/tapHandlers.dart';
import 'package:music_player/main.dart' show config;

import 'package:music_player/states/AppState.dart';
import 'package:music_player/states/FocusState.dart';
import 'package:music_player/states/focus_states/FocusStateInterface.dart';
import 'package:music_player/states/focus_states/SimpleListNavigator.dart';

typedef KA = KeyboardAction;

class BodyNavStatePattern extends KeyboardStateBase {
  FocusManagerState focusState;
  PlaybackKeybindings playbackKeybindings;
  late AppState appState;
  late void Function() update;

  @override
  String type = 'BodyNav';

  BodyNavStatePattern(
      {required this.focusState, required this.playbackKeybindings}) {
    appState = focusState.appState;
    update = focusState.update;
    listNav = SimpleListNavigator(getLength: _getLength);

    _initHandlers();
  }

  late SimpleListNavigator listNav;

  int _getLength() {
    return appState.currMusicPage.sectionlist[0].itemlist.length;
  }

  void _initHandlers() {
    keyBindings = [
      KeyBinding(
        fullname: KA.choose.name,
        keyEvents: [KeyEventType.down],
        handler: () {
          final index = listNav.index;
          if (listNav.isInBounds(index)) {
            var section = appState.currMusicPage.sectionlist[0];
            // WARNING: only for itemslist
            onItemTapHandler(index, section.id);
          }
          return this;
        },
      ),
      KeyBinding(
        fullname: KA.focus_left_pane.name,
        keyEvents: [KeyEventType.down],
        handler: () {
          return focusState.sidebarNavState;
        },
      ),
      KeyBinding(
        fullname: KA.focus_right_pane.name,
        keyEvents: [KeyEventType.down],
        handler: () {
          bool isWideQueueOpen = config.getProperty('isWideQueueOpen') ?? true;
          if (!isWideQueueOpen) {
            return this;
          }
          return focusState.queueNavState;
        },
      ),
      KeyBinding(
        fullname: KA.to_prev_tab.name,
        keyEvents: [KeyEventType.down],
        handler: () {
          var navType = appState.currentSource.navType;
          if (navType == NavType.tabs) {
            appState.toPrevTab();
          } else if (navType == NavType.searchTabs) {
            appState.toPrevSearchTab();
          }
          return this;
        },
      ),
      KeyBinding(
        fullname: KA.to_next_tab.name,
        keyEvents: [KeyEventType.down],
        handler: () {
          var navType = appState.currentSource.navType;
          if (navType == NavType.tabs) {
            appState.toNextTab();
          } else if (navType == NavType.searchTabs) {
            appState.toNextSearchTab();
          }
          return this;
        },
      ),
      KeyBinding(
        fullname: KA.back.name,
        keyEvents: [KeyEventType.down],
        handler: () {
          if (appState.canBack()) {
            appState.back();
          }
          return this;
        },
      ),
      KeyBinding(
        fullname: KA.show_item_dialog.name,
        keyEvents: [KeyEventType.down],
        handler: () {
          // WARNING: only for itemlist
          final idx = listNav.index;
          final item = appState.currMusicPage.sectionlist[0].itemlist[idx];
          showItemDialog(idx, item, sectionIndex: 0);
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

  int calcIndex(double scrollPos) {
    if (focusState.isNewPage) {
      var newfocusPos = scrollPos;
      int idx = (newfocusPos / CONFIG.itemExtent).ceil();
      listNav.index = idx;
      focusState.isNewPage = false;
      return idx;
    }

    return listNav.index;
  }

  void putFocusInScrollU(ListNavitatorScrollProps props) {
    if (listNav.putFocusInScroll(props)) {
      update();
    }
  }
}
