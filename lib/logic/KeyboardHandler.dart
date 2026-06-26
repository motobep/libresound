import 'package:flutter/services.dart'
    show HardwareKeyboard, KeyDownEvent, KeyEvent, KeyUpEvent;
import 'package:music_player/logger.dart';
import 'package:music_player/logic/enums.dart';

extension KeyEventString on String {
  KeyEventType toKeyEvent() {
    return switch (this) {
      'KeyDownEvent' => KeyEventType.down,
      'KeyUpEvent' => KeyEventType.up,
      'KeyRepeatEvent' => KeyEventType.repeat,
      _ => throw 'wrong string enum',
    };
  }
}

class KeyboardHandler {
  KeyboardHandler();

  bool isEnabled = true;

  // many keybinings <---> one event
  Map<String, void Function()> keyCodeHandlersMap = {};

  String lastKeyCodes = '';
  String _downKeyCodes = '';

  bool keyboardHandle(KeyEvent event) {
    if (!isEnabled) return false;

    final key = event.logicalKey.keyLabel;

    var kb = HardwareKeyboard.instance;
    String keyCodes = buildKeyCode(
      key,
      isCtrl: kb.isControlPressed,
      isShift: kb.isShiftPressed,
      keyEventType: event.runtimeType.toString().toKeyEvent(),
    );

    // log('KeyCodes: $keyCodes');
    var f = keyCodeHandlersMap[keyCodes];
    if (!keyCodeHandlersMap.containsKey(keyCodes)) {
      // log('No handler for: $keyCodes');
    }
    f?.call();

    return false;
  }

  void Function(String)? lastCodesListener;

  bool lastKeyCodesNotifier(KeyEvent event) {
    if (!isEnabled) return false;

    final key = event.logicalKey.keyLabel;
    var kb = HardwareKeyboard.instance;
    String keyCodes = buildKeyCode(
      key,
      isCtrl: kb.isControlPressed,
      isShift: kb.isShiftPressed,
      isAlt: kb.isAltPressed,
      keyEventType: event.runtimeType.toString().toKeyEvent(),
    );
    if (event is KeyDownEvent) {
      _downKeyCodes = keyCodes;
    }
    if (event is KeyUpEvent) {
      // if (kb.isControlPressed || kb.isShiftPressed) return false;
      if (kb.logicalKeysPressed.isNotEmpty) return false;

      lastKeyCodes = _downKeyCodes;
      logger.debug('lastKeyCodes: $lastKeyCodes');

      lastCodesListener?.call(lastKeyCodes);
    }
    return false;
  }

  static buildKeyCode(
    String key, {
    bool isCtrl = false,
    bool isShift = false,
    bool isAlt = false,
    KeyEventType keyEventType = KeyEventType.down,
  }) {
    String keyCodes = switch (keyEventType) {
      KeyEventType.down => '[down] ',
      KeyEventType.up => '[up] ',
      KeyEventType.repeat => '[repeat] ',
    };
    if (isCtrl) {
      keyCodes += '<Ctrl>-';
    }
    if (isShift) {
      keyCodes += '<Shift>-';
    }
    if (isAlt) {
      keyCodes += '<Alt>-';
    }
    if (key == ' ') {
      key = 'Space';
    }
    keyCodes += key;

    return keyCodes;
  }

  void register(String keyCodes, void Function() func) {
    keyCodeHandlersMap[keyCodes] = func;
  }

  void unregister(String keyCodes) {
    keyCodeHandlersMap.removeWhere((key, value) => key == keyCodes);
  }

  void registerAll(Bindings bindings) {
    keyCodeHandlersMap.addAll(bindings);
  }

  static final Logger logger =
      Logger(prefix: '🔮 KeyboardHandler: ');
}
