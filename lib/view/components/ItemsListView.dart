import 'package:flutter/material.dart';
import 'package:music_player/wide_view/pages/MainPageWide.dart'
    show checkContentWide;
import 'package:provider/provider.dart';

import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logger.dart';
import 'package:music_player/logic/Item.dart' show IndexedItem;
import 'package:music_player/logic/MusicItem.dart';
import 'package:music_player/logic/tapHandlers.dart';
import 'package:music_player/logic/PageDescr.dart';

import 'package:music_player/states/PlaybackState.dart';
import 'package:music_player/states/SelectionState.dart';
import 'package:music_player/states/DownloadsState.dart';
import 'package:music_player/states/FocusState.dart';

import 'package:music_player/view/components/tiles.dart';

class ItemsListView extends StatefulWidget {
  const ItemsListView(
    this.currPage, {
    Key? key,
  }) : super(key: key);

  final MusicPageDescr currPage;

  @override
  State<ItemsListView> createState() => _ItemsListViewState();
}

class _ItemsListViewState extends State<ItemsListView> {
  late SelectionSet selectionSet;

  @override
  void initState() {
    super.initState();
    // gLogger.view('_ItemsListViewState initState');
    selectionSet = Provider.of<SelectionState>(context, listen: false)
        .makeSet(0, setState);
  }

  @override
  void dispose() {
    // gLogger.view('_ItemsListViewState dispose');
    WidgetsBinding.instance
        .addPostFrameCallback((_) => selectionSet.removeSelf());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    gLogger.build('MusicslistView');
    bool isPaneActive = context.select<FocusManagerState, bool>(
        (s) => s.focusStateI.type == 'BodyNav');

    // (Dirty) To update duration of curr item if changed
    context.select<PlaybackState, int>((s) => s.playback.durationUpdatedIdx);

    int focusIndex = isPaneActive
        ? context.select<FocusManagerState, int>(
            (s) => s.bodyNavState.calcIndex(widget.currPage.scrollPos))
        : -1;

    var sectionDescr = widget.currPage.sectionlist[0];
    var itemlist = sectionDescr.itemlist;

    var downloadsState = context.watch<DownloadsState>();

    final isShowCheckbox =
        context.select<SelectionState, bool>((s) => s.isNotEmpty);

    double width = MediaQuery.of(context).size.width;
    bool isContentWide = checkContentWide(width);

    var sl = SliverFixedExtentList.builder(
      itemExtent: CONFIG.itemExtent,
      itemCount: itemlist.length,
      itemBuilder: (BuildContext context, int index) {
        var item = itemlist[index];
        bool isLoading = downloadsState.hasPlayId(item.sourceId, item.id);
        bool isFocused = isPaneActive && focusIndex == index;
        bool isMi = item is MusicItem;

        if (isContentWide && isMi) {
          return WideMiTile(
            mi: item,
            isFocused: isFocused,
            isLoading: isLoading,
            isSelected: selectionSet.contains(IndexedItem(index, item)),
            isShowCheckbox: isShowCheckbox,
            onTap: () async {
              if (isShowCheckbox && isMi) {
                selectionSet.selectItem(IndexedItem(index, item));
                return;
              }
              onItemTapHandler(index, sectionDescr.id);
            },
            onAction: !isMi && isShowCheckbox
                ? null
                : ([Offset? offset]) {
                    if (!isShowCheckbox || !isMi) {
                      showItemDialog(index, item,
                          tapPos: offset, sectionIndex: 0);
                    }
                  },
            onLongPress: () {
              selectionSet.selectItem(IndexedItem(index, item));
            },
          );
        }

        return Tile(
          title: item.title,
          subtitle: item.subtitle ?? '',
          picture: item.picture,
          isFocused: isFocused,
          isLoading: isLoading,
          isSelected: selectionSet.contains(IndexedItem(index, item)),
          isShowCheckbox: isMi && isShowCheckbox,
          onTap: () async {
            if (isShowCheckbox && isMi) {
              selectionSet.selectItem(IndexedItem(index, item));
              return;
            }
            onItemTapHandler(index, sectionDescr.id);
          },
          onAction: !isMi && isShowCheckbox
              ? null
              : ([Offset? offset]) {
                  if (!isShowCheckbox || !isMi) {
                    showItemDialog(index, item,
                        tapPos: offset, sectionIndex: 0);
                  }
                },
          onLongPress: () {
            if (isMi) {
              selectionSet.selectItem(IndexedItem(index, item));
            }
          },
        );
      },
    );
    return sl;
  }
}
