import 'package:flutter/material.dart' show FocusNode;
import 'package:music_player/logger.dart';
import 'package:music_player/logic/bindings/BindingsHandler.dart';
import 'package:music_player/logic/enums.dart';
import 'package:music_player/states/FocusState.dart';
import 'package:music_player/states/focus_states/FocusStateInterface.dart';

class InputStatePattern extends KeyboardStateBase {
  FocusManagerState focusState;

  late KeyboardStateBase prevState;
  late FocusNode focusNode;

  @override
  String type = 'Input';

  InputStatePattern({required this.focusState}) {
    _initHandlers();
  }

  @override
  void enter(KeyboardStateBase prevState) {
    this.prevState = prevState;
  }

  void _initHandlers() {
    keyBindings = [
      KeyBinding(
        fullname: KeyboardAction.unfocus.name,
        keyEvents: [KeyEventType.down],
        handler: () {
          focusNode.unfocus();
          return null;
        },
      ),
      KeyBinding(
          fullname: KeyboardAction.prev_suggestion.name,
          keyEvents: [KeyEventType.down],
          handler: () {
            gLogger.log('dummy - prev');
            return null;
          }),
      KeyBinding(
        fullname: KeyboardAction.next_suggestion.name,
        keyEvents: [KeyEventType.down],
        handler: () {
          gLogger.log('dummy - next');
          return null;
        },
      ),
    ];
    namespaceKeyBindingsNames();
  }
}
