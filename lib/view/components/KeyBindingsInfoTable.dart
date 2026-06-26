import 'package:flutter/material.dart';
import 'package:music_player/view/App.dart' show bindingsHandler;

class KeyBindingsInfoTable extends StatelessWidget {
  const KeyBindingsInfoTable({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final headerStyle = TextStyle(color: ColorScheme.of(context).onSurface);
    final textStyle = TextStyle(
      color: ColorScheme.of(context).onSurface,
    );

    final keyBindings = bindingsHandler.keyBindingsMap;
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
                  'Action name',
                  style: headerStyle,
                ),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text(
                  'Key Codes',
                  style: headerStyle,
                ),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text(
                  'Key Events',
                  style: headerStyle,
                ),
              ),
            ),
          ],
          rows: [
            for (var kb in keyBindings.values)
              DataRow(
                cells: <DataCell>[
                  DataCell(Text(
                    kb.fullname,
                    style: TextStyle(
                      color: kb.isActive
                          ? ColorScheme.of(context).primary
                          : ColorScheme.of(context).onSurface,
                    ),
                  )),
                  DataCell(Text(
                    kb.keyCodesList.join(', '),
                    style: textStyle,
                  )),
                  DataCell(Text(
                    kb.keyEvents.map((e) => e.name).join(', '),
                    style: textStyle,
                  )),
                ],
              ),
          ]),
    );
  }
}
