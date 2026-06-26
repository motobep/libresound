import 'package:music_player/logic/DialogDescr.dart';
import 'package:music_player/logic/bindings/BindingsHandler.dart';
import 'package:music_player/logic/enums.dart';
import 'package:music_player/states/FocusState.dart';
import 'package:music_player/states/focus_states/FocusStateInterface.dart';
import 'package:music_player/states/focus_states/SimpleListNavigator.dart'
    show SimpleListNavigator;

typedef KA = KeyboardAction;

class ActionsStatePattern extends KeyboardStateBase {
  FocusManagerState focusState;

  late KeyboardStateBase prevState;

  @override
  String type = 'Actions';

  List<ItemAction> actions = [];
  late DialogFuncs dialogFuncs;
  void Function()? onExit;

  ActionsStatePattern({required this.focusState}) {
    listNav = SimpleListNavigator(getLength: _getLength);

    _initHandlers();
  }

  void update({
    required List<ItemAction> actions,
    required DialogFuncs dialogFuncs,
    required void Function()? onExit,
  }) {
    this.actions = actions;
    this.dialogFuncs = dialogFuncs;
    this.onExit = onExit;

    listNav.index = 0;
  }

  late SimpleListNavigator listNav;

  int _getLength() {
    return actions.length;
  }

  @override
  void enter(KeyboardStateBase prevState) {
    this.prevState = prevState;
  }

  @override
  void exit() {
    onExit?.call();
  }

  void _initHandlers() {
    keyBindings = [
      KeyBinding(
        fullname: KA.choose.name,
        keyEvents: [KeyEventType.down],
        handler: () {
          final a = actions[listNav.index];
          a.callback(dialogFuncs);
          return null;
        },
      ),
    ];
    keyBindings
        .addAll(SimpleListNavigator.getKeybindings(listNav, focusState.update));
    namespaceKeyBindingsNames();
  }
}
