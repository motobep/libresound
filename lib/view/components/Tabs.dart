import 'package:flutter/material.dart';

import 'package:music_player/logic/enums.dart';
import 'package:music_player/states/AppearanceState.dart';
import 'package:music_player/view/components/buttons.dart';

import 'package:provider/provider.dart';

import 'package:music_player/states/AppState.dart' show AppState;

class Tabs extends StatelessWidget {
  const Tabs({super.key});

  @override
  Widget build(BuildContext context) {
    AppState appState = Provider.of<AppState>(context, listen: false);
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);

    int currentTabIdx =
        context.select<AppState, int>((app) => app.currentSource.currTabIdx);

    var tabs = context.select<AppState, List<(String, IconName?)>>(
        (app) => app.currentSource.getTabs());

    if (tabs.isEmpty) {
      return Container();
    }

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: appearanceState.contentPaddingBaseHor + 10, vertical: 4),
      decoration: BoxDecoration(
        color: ColorScheme.of(context).surface,
        border: Border(
            top: BorderSide(
          width: 1,
          color: appearanceState.separatorColor(),
        )),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var (idx, (name, icon)) in tabs.indexed)
            TabButton(
              name,
              iconName: icon,
              onTap: () {
                appState.chooseTabAsync(idx);
              },
              isActive: currentTabIdx == idx,
            ),
        ],
      ),
    );
  }
}
