import 'package:flutter/material.dart' show ScrollController;
import 'package:music_player/logger.dart';
import 'package:music_player/logic/bindings/BindingsHandler.dart';
import 'package:music_player/logic/enums.dart';

typedef _KA = KeyboardAction;

class SimpleListNavigator {
  int Function() getLength;
  int index = 0;

  SimpleListNavigator({required this.getLength});

  void _setCurrIndex(int index) {
    assert(isInBounds(index), 'Index is out of bounds');
    this.index = index;
  }

  bool isInBounds(int index) {
    bool v = 0 <= index && index < getLength();
    if (!v) {
      gLogger.warn(
          'WARNING: Index is out of bounds - index=$index, length=${getLength()}');
    }
    return v;
  }

  bool focus_up() {
    if (!isInBounds(index)) {
      index = getLength() - 1;
      return true;
    }

    if (isInBounds(index - 1)) {
      _setCurrIndex(index - 1);
      if (getScrollProps != null) _putScrollInFocusAuto();
      return true;
    }
    return false;
  }

  bool focus_down() {
    if (!isInBounds(index)) {
      index = getLength() - 1;
      return true;
    }

    if (isInBounds(index + 1)) {
      _setCurrIndex(index + 1);
      if (getScrollProps != null) _putScrollInFocusAuto();
      return true;
    }
    return false;
  }

  bool to_bottom() {
    if (!isInBounds(index)) {
      index = getLength() - 1;
      return true;
    }

    int v = getLength() - 1;
    if (isInBounds(v)) {
      _setCurrIndex(v);
      if (getScrollProps != null) _putScrollInFocusAuto();
      return true;
    }
    return false;
  }

  bool to_top() {
    if (!isInBounds(index)) {
      index = getLength() - 1;
      return true;
    }

    if (isInBounds(0)) {
      _setCurrIndex(0);
      if (getScrollProps != null) _putScrollInFocusAuto();
      return true;
    }
    return false;
  }

  (ListNavitatorScrollProps, ScrollController) Function()? getScrollProps;

  void _putScrollInFocusAuto() {
    var (props, scrollController) = getScrollProps!();
    gLogger.log('ListNavitatorScrollProps: ${props}');
    if (!scrollController.hasClients) return;
    _putScrollInFocus(props, scrollController);
  }

  // TODO later: prohibit to left/right pane where there is only one pane (listView)
  // Proposal: may be improved to calculate more accurate position
  void _putScrollInFocus(
      ListNavitatorScrollProps props, ScrollController scrollController) {
    gLogger.log('put Scroll -> focus');

    var focusPos = _getFocusPos(props.itemHeight);
    if (focusPos > props.scrollPos + (props.insetHeight - props.itemHeight)) {
      var sp = focusPos - (props.insetHeight - props.itemHeight);
      scrollController.jumpTo(sp);
    } else if (focusPos < props.scrollPos) {
      var sp = focusPos;
      scrollController.jumpTo(sp);
    }
  }

  bool putFocusInScroll(ListNavitatorScrollProps props) {
    var focusPos = _getFocusPos(props.itemHeight);
    if (focusPos > props.scrollPos + (props.insetHeight - props.itemHeight)) {
      var newFocusPos =
          props.scrollPos + (props.insetHeight - props.itemHeight);
      int idx = newFocusPos ~/ props.itemHeight;
      if (!isInBounds(idx)) {
        gLogger.warn('bottom setting to 0');
        _setCurrIndex(0);
      } else {
        _setCurrIndex(idx);
      }

      return true;
    } else if (focusPos < props.scrollPos) {
      var newFocusPos = props.scrollPos;
      int idx = newFocusPos ~/ props.itemHeight + 1;
      if (!isInBounds(idx)) {
        // FIXME: don't use it. Calc pos properly
        _setCurrIndex(getLength() - 1);
      } else {
        _setCurrIndex(idx);
      }

      return true;
    }
    return false;
  }

  double _getFocusPos(double height) {
    return index * height;
  }

  static List<KeyBinding> getKeybindings(
      SimpleListNavigator listNavigator, void Function() update) {
    return [
      KeyBinding(
        fullname: _KA.focus_up.name,
        keyEvents: [KeyEventType.down, KeyEventType.repeat],
        handler: () {
          if (listNavigator.focus_up()) update();
          return null;
        },
      ),
      KeyBinding(
        fullname: _KA.focus_down.name,
        keyEvents: [KeyEventType.down, KeyEventType.repeat],
        handler: () {
          if (listNavigator.focus_down()) update();
          return null;
        },
      ),
      KeyBinding(
        fullname: _KA.to_bottom.name,
        keyEvents: [KeyEventType.down],
        handler: () {
          if (listNavigator.to_bottom()) update();
          return null;
        },
      ),
      KeyBinding(
        fullname: _KA.to_top.name,
        keyEvents: [KeyEventType.down],
        handler: () {
          if (listNavigator.to_top()) update();
          return null;
        },
      ),
    ];
  }
}

class ListNavitatorScrollProps {
  double itemHeight;
  double scrollPos;
  double insetHeight;
  ListNavitatorScrollProps({
    required this.itemHeight,
    required this.insetHeight,
    required this.scrollPos,
  });
}
