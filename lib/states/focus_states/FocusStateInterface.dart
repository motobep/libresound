import 'package:music_player/logic/bindings/BindingsHandler.dart';

abstract class KeyboardStateBase {
  abstract String type;

  List<KeyBinding> keyBindings = const [];

  void enter(KeyboardStateBase prevState) {}
  void exit() {}

  void namespaceKeyBindingsNames() {
    for (var kb in keyBindings) {
      kb.fullname = '$type.${kb.fullname}';
    }
  }
}
