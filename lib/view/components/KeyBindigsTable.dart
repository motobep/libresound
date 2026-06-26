import 'package:flutter/material.dart';
import 'package:music_player/logger.dart';
import 'package:music_player/logic/enums.dart';
import 'package:music_player/logic/lang.dart';
import 'package:music_player/states/AppearanceState.dart';
import 'package:music_player/view/App.dart' show bindingsHandler;
import 'package:music_player/view/components/buttons.dart';
import 'package:music_player/view/components/dialogs.dart';
import 'package:music_player/view/components/iconsMap.dart';
import 'package:provider/provider.dart';

Map<KeyboardAction, String> getActionToLangMap() {
  return {
    KeyboardAction.toggle_playback: lang.kb__toggle_playback,
    KeyboardAction.play_prev: lang.kb__play_prev,
    KeyboardAction.play_next: lang.kb__play_next,
    KeyboardAction.shuffle: lang.kb__shuffle,
    KeyboardAction.toggle_repeat: lang.kb__toggle_repeat,
    KeyboardAction.show_current_item_dialog: lang.kb__show_current_item_dialog,
    KeyboardAction.choose: lang.kb__choose,
    KeyboardAction.focus_up: lang.kb__focus_up,
    KeyboardAction.focus_down: lang.kb__focus_down,
    KeyboardAction.to_bottom: lang.kb__to_bottom,
    KeyboardAction.to_top: lang.kb__to_top,
    KeyboardAction.focus_left_pane: lang.kb__focus_left_pane,
    KeyboardAction.focus_right_pane: lang.kb__focus_right_pane,
    KeyboardAction.to_prev_tab: lang.kb__to_prev_tab,
    KeyboardAction.to_next_tab: lang.kb__to_next_tab,
    KeyboardAction.back: lang.kb__back,
    KeyboardAction.show_item_dialog: lang.kb__show_item_dialog,
    KeyboardAction.focus_search: lang.kb__focus_search,
    KeyboardAction.unfocus: lang.kb__unfocus,
    KeyboardAction.prev_suggestion: lang.kb__prev_suggestion,
    KeyboardAction.next_suggestion: lang.kb__next_suggestion,
  };
}

class KeyBindingsTable extends StatefulWidget {
  const KeyBindingsTable({
    super.key,
  });

  @override
  State<KeyBindingsTable> createState() => _KeyBindingsTableState();
}

class _KeyBindingsTableState extends State<KeyBindingsTable> {
  @override
  Widget build(BuildContext context) {
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);
    final headerStyle = TextStyle(color: ColorScheme.of(context).onSurface);

    final keyBindings = bindingsHandler.getUserMappings();
    final actionToLangMap = getActionToLangMap();

    return SizedBox(
      width: double.infinity,
      child: DataTable(
          border: TableBorder.symmetric(
              inside: BorderSide(
            width: 1.5,
            color: ColorScheme.of(context).secondary,
          )),
          columns: [
            DataColumn(
              label: Expanded(
                child: Text(
                  lang.Action,
                  style: headerStyle,
                ),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text(
                  lang.Keys,
                  style: headerStyle,
                ),
              ),
            ),
          ],
          rows: [
            for (var entry in keyBindings.entries)
              DataRow(
                cells: <DataCell>[
                  DataCell(Text(
                    actionToLangMap[KeyboardAction.values.byName(entry.key)]!,
                  )),
                  DataCell(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            for (var keyCodes in entry.value)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                child: KeyMappingButton(
                                  keyCodes,
                                  onTap: () async {
                                    gLogger.view('hi "${entry.key}"');
                                    final disabled = bindingsHandler.disable();

                                    String? newKeyCodes =
                                        await showDialog<String>(
                                      context: context,
                                      builder: (context) => KeyMappingDialog(
                                          mappingName: entry.key),
                                    );
                                    if (newKeyCodes != null) {
                                      gLogger.view('($keyCodes;$newKeyCodes)');
                                      bindingsHandler.changeMapping(
                                          entry.key, keyCodes, newKeyCodes);
                                      gLogger.view('Changed');

                                      setState(() {});
                                    }

                                    bindingsHandler.enable(disabled);
                                  },
                                  onCrossTap: () async {
                                    gLogger.view(' cross hi "${entry.key}"');

                                    bool? isConfirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => ConfirmDialog(
                                        heading: lang.Delete__q,
                                        confirmText: lang.Yes,
                                        cancelText: lang.No,
                                      ),
                                    );
                                    if (isConfirm != null &&
                                        isConfirm == true) {
                                      bindingsHandler.removeMapping(
                                          entry.key, keyCodes);
                                      gLogger.view('removed');

                                      setState(() {});
                                    }
                                  },
                                ),
                              ),
                          ],
                        ),
                        SizedBox(
                          width: 32.0,
                          height: 32.0,
                          child: IconButton(
                            icon: const Icon(Pit.plus),
                            iconSize: 16.0,
                            onPressed: () async {
                              gLogger.view('Add "${entry.key}"');
                              final disabled = bindingsHandler.disable();

                              String? keyCodes = await showDialog<String>(
                                context: context,
                                builder: (context) => const KeyMappingDialog(),
                              );
                              if (keyCodes != null) {
                                bindingsHandler.addMapping(entry.key, keyCodes);
                                gLogger.view('Added');

                                setState(() {});
                              }

                              bindingsHandler.enable(disabled);
                            },
                            style: ButtonStyle(
                              foregroundColor: WidgetStateColor.resolveWith(
                                  (states) =>
                                      ColorScheme.of(context).onSurface),
                              backgroundColor: WidgetStateColor.resolveWith(
                                  (states) =>
                                      appearanceState.lerpBgColor(0.04)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
          ]),
    );
  }
}
