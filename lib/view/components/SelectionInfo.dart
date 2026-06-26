import 'package:flutter/material.dart';
import 'package:music_player/states/AppearanceState.dart';
import 'package:music_player/states/PlaybackState.dart';
import 'package:music_player/states/SelectionState.dart';
import 'package:provider/provider.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

class SelectionInfo extends StatelessWidget {
  const SelectionInfo({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    int length = context.select<SelectionState, int>((s) => s.length);
    if (length == 0) return const SizedBox.shrink();

    final selectionState = Provider.of<SelectionState>(context, listen: false);
    var playback = Provider.of<PlaybackState>(context, listen: false).playback;

    bool isOnlySource =
        context.select<SelectionState, bool>((s) => s.isOnlySource);
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);

    var style = ButtonStyle(
      padding: const WidgetStatePropertyAll(EdgeInsets.all(4)),
      minimumSize: WidgetStateProperty.all(const Size.square(0)),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(
        side: BorderSide(width: 1, color: appearanceState.lerpBgColor(0.07)),
        borderRadius: BorderRadius.circular(6.0),
      )),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        // height: 40.0,
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 6.0),
        decoration: BoxDecoration(
          color: ColorScheme.of(context).surface,
          border:
              Border.all(color: appearanceState.lerpBgColor(0.07), width: 1.0),
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                selectionState.unselectAll();
              },
              icon: const Icon(PhosphorIconsThin.x),
              style: ButtonStyle(
                padding: const WidgetStatePropertyAll(EdgeInsets.all(0)),
                minimumSize: WidgetStateProperty.all(const Size.square(0)),
              ),
            ),
            const SizedBox(width: 10),
            Text('$length',
                style: TextStyle(
                  fontSize: 16,
                  color: ColorScheme.of(context).onSurface,
                  fontStyle: isOnlySource ? null : FontStyle.italic,
                )),
            const SizedBox(width: 16),
            IconButton(
              onPressed: () {
                var indexedItemMap = selectionState.getSortedMap();
                var items = SelectionState.flattenMap(indexedItemMap);

                selectionState.unselectAll();
                playback.addAll_n(items);
              },
              iconSize: 18,
              style: style,
              icon: const Icon(PhosphorIconsThin.plus),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () {
                var indexedItemMap = selectionState.getSortedMap();
                var items = SelectionState.flattenMap(indexedItemMap);

                selectionState.unselectAll();
                playback.addAllNext_n(items);
              },
              iconSize: 18,
              style: style,
              icon: const Icon(PhosphorIconsThin.caretRight),
            ),
            if (isOnlySource)
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: IconButton(
                  onPressed: () {
                    selectionState.act();
                  },
                  icon: const Icon(PhosphorIconsRegular.dotsThreeVertical),
                  style: ButtonStyle(
                    padding: const WidgetStatePropertyAll(EdgeInsets.all(0)),
                    minimumSize: WidgetStateProperty.all(const Size.square(0)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
