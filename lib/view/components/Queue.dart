import 'package:flutter/material.dart';
import 'package:music_player/logger.dart';
import 'package:music_player/logic/Debouncer.dart';
import 'package:music_player/logic/Item.dart';
import 'package:music_player/logic/enums.dart' show OpenDegree;
import 'package:music_player/states/focus_states/SimpleListNavigator.dart';
import 'package:music_player/view/components/Autoplay.dart';
import 'package:provider/provider.dart';

import 'package:music_player/consts.dart' as CONSTS;
import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logic/MusicItem.dart';
import 'package:music_player/logic/playback/Playback.dart';
import 'package:music_player/logic/playback/PlaybackQueue.dart';
import 'package:music_player/logic/lang.dart';
import 'package:music_player/logic/tapHandlers.dart';

import 'package:music_player/states/AppState.dart' show AppState;
import 'package:music_player/states/PlaybackState.dart';
import 'package:music_player/states/AppearanceState.dart';
import 'package:music_player/states/DownloadsState.dart';
import 'package:music_player/states/FocusState.dart';
import 'package:music_player/states/SelectionState.dart';

import 'package:music_player/view/components/tiles.dart';
import 'package:music_player/view/components/parts.dart';

class Queue extends StatefulWidget {
  const Queue({
    super.key,
    required this.width,
    required this.height,
    this.shouldPop = false,
    this.isInSheet = false,
    this.direction = DismissDirection.horizontal,
  });

  final double width;
  final double height;
  final bool shouldPop;
  final bool isInSheet;
  final DismissDirection direction;

  static const double tileHeight = CONFIG.itemExtent;

  @override
  State<Queue> createState() => _QueueState();
}

class _QueueState extends State<Queue> {
  ScrollController? _scrollController;
  late SelectionSet selectionSet =
      Provider.of<SelectionState>(context, listen: false)
          .mapOfSets['${CONSTS.queueSectionIdx}']!;

  static final _debouncer = Debouncer(delay: CONFIG.queueAutoFocusDelay);

  @override
  void initState() {
    super.initState();
    // gLogger.view('initState');
  }

  @override
  void dispose() {
    // gLogger.view('dispose');
    _scrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    gLogger.build(runtimeType);
    final lang = context.select<AppearanceState, Lang>((s) => s.lang);
    Color bgColor =
        context.select<AppearanceState, Color>((s) => s.colors[ColorType.bg]!);
    Color focusColor =
        context.select<AppearanceState, Color>((s) => s.focusColor());
    Color textColor = context
        .select<AppearanceState, Color>((s) => s.colors[ColorType.text]!);

    PlaybackState playbackState =
        Provider.of<PlaybackState>(context, listen: false);
    Playback playback = playbackState.playback;
    PlaybackQueue playbackQueue =
        context.select<PlaybackState, PlaybackQueue>((s) => s.playback.queue);

    int currentTrackIdx =
        context.select<PlaybackState, int>((s) => s.playback.queue.currentIdx);

    bool isPlaybackControlsOpened = context.select<AppState, bool>(
        (s) => s.controlsSheetOpenDegree == OpenDegree.opened);

    if (!widget.isInSheet) {
      context.select<PlaybackState, int>((s) => s.playback.queue.updateIdx);
    } else {
      if (isPlaybackControlsOpened)
        context.select<PlaybackState, int>((s) => s.playback.queue.updateIdx);
    }

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      AppState appState = Provider.of<AppState>(context, listen: false);
      double queueScrollOffset = appState.queueScrollOffset;

      double insetHeight = constraints.maxHeight;

      FocusManagerState focusState =
          Provider.of<FocusManagerState>(context, listen: false);

      // Add offset to ListView
      double scrollOffset = 0.0;
      if (queueScrollOffset != -1.0) {
        scrollOffset = queueScrollOffset;
      } else {
        gLogger.log('First queue init');
        final double initialScrollOffset =
            Queue.tileHeight * currentTrackIdx.toDouble();
        scrollOffset = initialScrollOffset;
      }

      // TODO: update when item gots duration

      // FIXME: bug. click play first item. go to queue (mobile), move item a bit down (don't scroll), the scroll sets to the moved item
      if (_scrollController != null && _scrollController!.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController!.hasClients)
            _scrollController!.jumpTo(scrollOffset);
        });
      } else {
        _scrollController = ScrollController(
          initialScrollOffset: scrollOffset,
          keepScrollOffset: true,
        );
      }

      bool isPaneActive = context.select<FocusManagerState, bool>(
          (s) => s.focusStateI.type == 'QueueNav');
      int focusIndex = isPaneActive
          ? context.select<FocusManagerState, int>(
              (s) => s.queueNavState.listNav.index)
          : -1;

      var props = ListNavitatorScrollProps(
        insetHeight: insetHeight,
        itemHeight: CONFIG.itemExtent,
        scrollPos: scrollOffset,
      );
      focusState.queueNavState.listNav.getScrollProps = () {
        return (props, _scrollController!);
      };
      if (queueScrollOffset == -1.0) {
        gLogger.log('First queue init: put focus index in scroll');
        focusState.queueNavState.listNav.putFocusInScroll(props);
      }

      final downloadsState = context.watch<DownloadsState>();

      // To update
      context.select<SelectionState, int>((s) => s.length);

      Widget w;
      if (playbackQueue.isEmpty) {
        w = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              margin: const EdgeInsets.only(bottom: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: const Thumbnail(),
              ),
            ),
            Container(
              color: isPaneActive ? focusColor : null,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                lang.Queue_is_empty,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        );
      } else {
        final isShowCheckbox =
            context.select<SelectionState, bool>((s) => s.isNotEmpty);

        final sliver = SliverReorderableList(
          itemExtent: CONFIG.itemExtent,
          onReorder: (oldIndex, newIndex) {
            playbackQueue.moveElement(oldIndex, newIndex);
            playbackState.update();
          },
          itemCount: playbackQueue.length,
          itemBuilder: (BuildContext context, int index) {
            MusicItem mi = playbackQueue.getMusicItem(index);
            bool isFocused = isPaneActive && focusIndex == index;
            bool isLoading = downloadsState.hasPlayId(mi.sourceId, mi.id);

            return Dismissible(
              key: ValueKey('${mi.id}#$index@${playbackQueue.length}'),
              direction:
                  !isShowCheckbox ? widget.direction : DismissDirection.none,
              onDismissed: (direction) async {
                bool ok = await playback.removeItemsFromQueue([index]);
                if (!ok && widget.shouldPop) {
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              child: Material(
                child: TileBase(
                  title: mi.title,
                  subtitle: mi.subtitle,
                  picture: mi.picture,
                  trailing: ReorderableDragStartListener(
                    index: index,
                    child: Icon(
                      Icons.drag_handle,
                      color: textColor,
                    ),
                  ),
                  onTap: () async {
                    if (!isShowCheckbox) {
                      await playback.playByIdx_n(index);
                    } else {
                      selectionSet.selectItem(IndexedItem(index, mi));
                    }
                  },
                  onSecondaryTap: ([Offset? offset]) {
                    if (!isShowCheckbox) {
                      showItemDialog(index, mi,
                          tapPos: offset, sectionIndex: CONSTS.queueSectionIdx);
                    }
                  },
                  onLongPress: () {
                    selectionSet.selectItem(IndexedItem(index, mi));
                  },
                  isCurrent: index == currentTrackIdx,
                  isLoading: isLoading,
                  isSelected: selectionSet.contains(IndexedItem(index, mi)),
                  isShowCheckbox: isShowCheckbox,
                  isFocused: isFocused,
                  height: Queue.tileHeight,
                ),
              ),
            );
          },
        );

        // Autoplay switch
        bool isShowAutoplay =
            context.select<AppState, bool>((s) => s.autoplaySources.isShow());

        var customScrollView = CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            sliver,
            if (isShowAutoplay)
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: CONFIG.itemExtent,
                  child: AutoplayTile(),
                ),
              ),
          ],
        );

        w = NotificationListener<ScrollEndNotification>(
          child: customScrollView,
          onNotification: (notification) {
            var pixels = notification.metrics.pixels;
            appState.queueScrollOffset = pixels;

            _debouncer.run(() {
              // FIXME: calls repeatedly when queue height is less than queue max height
              gLogger.debug('Put scroll on current mi');
              var currentItemOffset = currentTrackIdx * CONFIG.itemExtent;
              appState.queueScrollOffset = currentItemOffset;
              if (_scrollController != null && _scrollController!.hasClients) {
                _scrollController!.animateTo(
                  currentItemOffset,
                  duration: CONFIG.scrollAnimationDuration,
                  curve: Curves.easeOutCubic,
                );
              }
            });

            if (isPaneActive) {
              var props = ListNavitatorScrollProps(
                  scrollPos: pixels,
                  insetHeight: insetHeight,
                  itemHeight: CONFIG.itemExtent);
              focusState.queueNavState.putFocusInScrollU(props);
            }
            return true;
          },
        );
      }
      return Container(
        color: bgColor,
        width: widget.width,
        height: widget.height,
        child: w,
      );
    });
  }
}
