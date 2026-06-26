import 'package:flutter/material.dart' show ChangeNotifier, FocusNode;

import 'package:music_player/logger.dart';
import 'package:music_player/logic/KeyValue.dart';
import 'package:music_player/logic/KeyboardHandler.dart';
import 'package:music_player/logic/bindings/BindingsHandler.dart';
import 'package:music_player/logic/bindings/PlaybackKeybindings.dart';
import 'package:music_player/logic/playback/Playback.dart';

import 'package:music_player/states/AppState.dart';
import 'package:music_player/states/focus_states/ActionsStatePattern.dart';

import 'package:music_player/states/focus_states/FocusStateInterface.dart';
import 'package:music_player/states/focus_states/BodyNavState.dart';
import 'package:music_player/states/focus_states/QueueNavState.dart';
import 'package:music_player/states/focus_states/SearchState.dart';
import 'package:music_player/states/focus_states/SidebarNavState.dart';

import 'package:music_player/view/App.dart'
    show bindingsHandler, navigatorKey, searchFocusNode;
import 'package:music_player/view/PageRouter.dart';

class FocusManagerState extends ChangeNotifier {
  FocusManagerState({
    required this.keyboardHandler,
    required this.appState,
    required this.playback,
  });

  bool isEnabled = false;

  final KeyboardHandler keyboardHandler;
  AppState appState;
  Playback playback;

  late KeyboardStateBase focusStateI;

  bool isNewPage = false;

  late BodyNavStatePattern bodyNavState;
  late QueueNavStatePattern queueNavState;
  late SidebarNavStatePattern sidebarNavState;
  late InputStatePattern inputState;
  late ActionsStatePattern actionsState;

  void init({required bool isEnabled}) {
    this.isEnabled = isEnabled;

    PlaybackKeybindings playbackKeybindings =
        PlaybackKeybindings(playback: playback);

    bodyNavState = BodyNavStatePattern(
        focusState: this, playbackKeybindings: playbackKeybindings);
    queueNavState = QueueNavStatePattern(
        focusState: this, playbackKeybindings: playbackKeybindings);
    sidebarNavState = SidebarNavStatePattern(
        focusState: this, playbackKeybindings: playbackKeybindings);
    inputState = InputStatePattern(focusState: this);
    actionsState = ActionsStatePattern(focusState: this);

    if (!isEnabled) {
      focusStateI = DisabledStatePattern();
      return;
    }

    final kbs = bodyNavState.keyBindings +
        queueNavState.keyBindings +
        sidebarNavState.keyBindings +
        inputState.keyBindings +
        actionsState.keyBindings;
    _wrapAndMap(bindingsHandler.mappings, kbs);

    focusStateI = bodyNavState;
    bindingsHandler.activate(focusStateI.type);
  }

  static int focusCount = 0;

  void Function() getInputFocusListener(FocusNode focusNode) {
    final idx = ++focusCount;
    return () {
      logger.debug('focusNode "${idx}" hasFocus: ${focusNode.hasFocus}');
      if (focusNode.hasFocus) {
        logger.debug('$idx: Focus');
        _onFocusInput(focusNode);
      } else {
        logger.debug('$idx: UnFocus');
        _onUnfocusInput();
      }
    };
  }

  void _wrapAndMap(KeyValue mappings, List<KeyBinding> kbs) {
    _wrapBindings(kbs);
    bindingsHandler.addMappedBindingsByName(mappings, kbs);
  }

  void _wrapBindings(List<KeyBinding> keyBindings) {
    for (var kb in keyBindings) {
      kb.handler = _createHandler(kb.handler);
    }
  }

  Null Function() _createHandler(KeyboardStateBase? Function() handler) {
    return () {
      // log('State type: "${focusStateInterface.type}"');
      KeyboardStateBase? newState = handler();
      if (newState == null) {
        // log('newState is null');
        return;
      }

      if (newState.type != focusStateI.type) {
        _swapState(newState);
      }
    };
  }

  void _swapState(KeyboardStateBase newState) {
    logger.debug('Swap state to: "${newState.type}"');
    focusStateI.exit();
    newState.enter(focusStateI);
    bindingsHandler.deactivate(focusStateI.type);
    focusStateI = newState;
    bindingsHandler.activate(focusStateI.type);
    update();
  }

  void focusActions() {
    _swapState(actionsState);
  }

  void unfocusActions() {
    var context = navigatorKey.currentContext!;
    PageRouter.back(context);
    _swapState(actionsState.prevState);
  }

  void focusBody() {
    if (!isEnabled) {
      assert(false, 'Not enabled focus state');
      return;
    }
    _swapState(bodyNavState);
  }

  void onSidebarClick(int index) {
    if (!isEnabled) {
      appState.getSidebarButtonOnTaps()[index]();
      return;
    }

    if (focusStateI.type != sidebarNavState.type) {
      _swapState(sidebarNavState);
    }
    sidebarNavState.chooseButton(index);
  }

  void _onFocusInput(FocusNode focusNode) {
    inputState.focusNode = focusNode;
    _swapState(inputState);
  }

  void _onUnfocusInput() {
    _swapState(inputState.prevState);
  }

  void update() {
    notifyListeners();
  }
}

class DisabledStatePattern extends KeyboardStateBase {
  @override
  String type = 'Disabled';
}

void focusSearch() {
  if (!searchFocusNode.hasFocus) {
    logger.debug('focus search');
    searchFocusNode.requestFocus();
  }
}

final Logger logger = Logger(prefix: '📷 FocusState: ');
