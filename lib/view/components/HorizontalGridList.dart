import 'package:flutter/material.dart';
import 'package:music_player/logger.dart';
import 'package:music_player/logic/MusicItem.dart';
import 'package:music_player/logic/tapHandlers.dart';
import 'package:music_player/states/SelectionState.dart';
import 'package:music_player/wide_view/pages/MainPageWide.dart'
    show checkContentWide;
import 'package:provider/provider.dart';

import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logic/Item.dart';
import 'package:music_player/logic/SectionDescr.dart';

import 'package:music_player/states/DownloadsState.dart';

import 'package:music_player/view/components/tiles.dart';

class HorizontalGridList extends StatefulWidget {
  const HorizontalGridList(
    this.sectionDescr, {
    required this.scrollController,
    required this.maxItemWidth,
    required this.isBigTile,
    required this.rowsCount,
    Key? key,
  }) : super(key: key);

  final SectionDescr sectionDescr;

  final ScrollController scrollController;
  final double maxItemWidth;
  final bool isBigTile;
  final int rowsCount;

  @override
  State<HorizontalGridList> createState() => _HorizontalGridListState();
}

class _HorizontalGridListState extends State<HorizontalGridList> {
  late SelectionSet selectionSet;

  @override
  void initState() {
    super.initState();
    gLogger.view('_HorizontalGridListState initState');
    selectionSet = Provider.of<SelectionState>(context, listen: false)
        .makeSet(widget.sectionDescr.index, setState);
  }

  @override
  void dispose() {
    gLogger.view('_HorizontalGridListState dispose');
    WidgetsBinding.instance
        .addPostFrameCallback((_) => selectionSet.removeSelf());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var itemslist = widget.sectionDescr.itemlist;

    var downloadsState = context.watch<DownloadsState>();

    var crossAxisCount = widget.rowsCount;
    int colLength = (itemslist.length / crossAxisCount).ceil();
    int remainder = itemslist.length % crossAxisCount;

    double itemWidth;
    double textHeight = CONFIG.itemExtent;
    double colHeight = crossAxisCount * CONFIG.itemExtent;
    if (widget.isBigTile) {
      itemWidth = widget.maxItemWidth * 0.9 / 2;
      // itemWidth = 480 * 0.9 / 2;
      textHeight = 78;
      colHeight = crossAxisCount * (itemWidth + textHeight);
    } else {
      if (colLength == 1) {
        itemWidth = widget.maxItemWidth;
      } else {
        itemWidth = widget.maxItemWidth * 0.9;
      }
    }

    final isShowCheckbox =
        context.select<SelectionState, bool>((s) => s.isNotEmpty);

    return SizedBox(
      height: colHeight,
      child: Scrollbar(
        controller: widget.scrollController,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          // key: Key(sectionDescr.hashCode.toString()),
          cacheExtent: CONFIG.itemExtent * 40,
          controller: widget.scrollController,
          itemExtent: itemWidth,
          itemCount: colLength,
          itemBuilder: (BuildContext context, int colIdx) {
            List<Widget> children = [];
            int from = colIdx * crossAxisCount;
            int to = from + crossAxisCount;
            if (colIdx == colLength - 1 && remainder != 0) {
              to = from + remainder;
            }

            for (int index = from; index < to; index++) {
              Item item = itemslist[index];
              bool isLoading = downloadsState.hasPlayId(item.sourceId, item.id);
              bool isMi = item is MusicItem;

              Widget el;
              if (widget.isBigTile) {
                el = BigTile(
                  width: itemWidth,
                  textHeight: textHeight,
                  title: item.title,
                  subtitle: item.subtitle ?? '',
                  picture: item.picture,
                  isLoading: isLoading,
                  isSelected: selectionSet.contains(IndexedItem(index, item)),
                  isShowCheckbox: isMi && isShowCheckbox,
                  onTap: () {
                    if (isShowCheckbox && isMi) {
                      selectionSet.selectItem(IndexedItem(index, item));
                      return;
                    }
                    onItemTapHandler(index, widget.sectionDescr.id);
                  },
                  onAction: !isMi && isShowCheckbox
                      ? null
                      : ([Offset? offset]) {
                          if (!isShowCheckbox || !isMi) {
                            showItemDialog(index, item,
                                tapPos: offset,
                                sectionIndex: widget.sectionDescr.index);
                          }
                        },
                  onLongPress: () {
                    if (isMi) {
                      selectionSet.selectItem(IndexedItem(index, item));
                    }
                  },
                );
              } else {
                double width = MediaQuery.of(context).size.width;
                bool isContentWide = checkContentWide(width);
                if (colLength == 1 && isContentWide && isMi) {
                  el = WideMiTile(
                    mi: item,
                    height: CONFIG.itemExtent,
                    isLoading: isLoading,
                    isSelected: selectionSet.contains(IndexedItem(index, item)),
                    isShowCheckbox: isShowCheckbox,
                    onTap: () async {
                      if (isShowCheckbox && isMi) {
                        selectionSet.selectItem(IndexedItem(index, item));
                        return;
                      }
                      onItemTapHandler(index, widget.sectionDescr.id);
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
                } else {
                  el = Tile(
                    height: CONFIG.itemExtent,
                    title: item.title,
                    subtitle: item.subtitle ?? '',
                    picture: item.picture,
                    isLoading: isLoading,
                    isSelected: selectionSet.contains(IndexedItem(index, item)),
                    isShowCheckbox: isMi && isShowCheckbox,
                    onTap: () {
                      if (isShowCheckbox && isMi) {
                        selectionSet.selectItem(IndexedItem(index, item));
                        return;
                      }
                      onItemTapHandler(index, widget.sectionDescr.id);
                    },
                    onAction: !isMi && isShowCheckbox
                        ? null
                        : ([Offset? offset]) {
                            if (!isShowCheckbox || !isMi) {
                              showItemDialog(index, item,
                                  tapPos: offset,
                                  sectionIndex: widget.sectionDescr.index);
                            }
                          },
                    onLongPress: () {
                      if (isMi) {
                        selectionSet.selectItem(IndexedItem(index, item));
                      }
                    },
                  );
                }
              }
              children.add(el);
            }

            return Column(
              children: children,
            );
          },
        ),
      ),
    );
  }
}
