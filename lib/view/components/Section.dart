import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:music_player/states/AppState.dart';
import 'package:music_player/states/PlaybackState.dart';
import 'package:provider/provider.dart';

import 'package:music_player/logic/SectionDescr.dart';
import 'package:music_player/states/AppearanceState.dart';
import 'package:music_player/view/components/HorizontalGridList.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:music_player/view/components/buttons.dart';

class Section extends StatefulWidget {
  const Section({
    super.key,
    required this.sectionDescr,
  });

  final SectionDescr sectionDescr;

  @override
  State<Section> createState() => _SectionState();
}

class _SectionState extends State<Section> {
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // (Dirty) To update duration of curr item if changed
    context.select<PlaybackState, int>((s) => s.playback.durationUpdatedIdx);

    Color textColor = context
        .select<AppearanceState, Color>((s) => s.colors[ColorType.text]!);

    var duration = const Duration(milliseconds: 500);
    var curve = Curves.easeOutCubic;

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      // logger.view('constraints=$constraints');

      var crossAxisCount = widget.sectionDescr.rowsCount;
      var itemslist = widget.sectionDescr.itemlist;
      int colLength = (itemslist.length / crossAxisCount).ceil();

      bool isBigTile = widget.sectionDescr.isBigTile;

      double width = min(constraints.maxWidth, 480.0);
      if (colLength == 1 && !isBigTile) {
        width = constraints.maxWidth;
      }

      double itemWidth = _calcItemWidth(width, isBigTile);
      double stride = itemWidth * ((constraints.maxWidth - 18) ~/ itemWidth);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: widget.sectionDescr.header?.title,
            subtitle: widget.sectionDescr.header?.subtitle,
            scrollController: scrollController,
            onLeftTap: () {
              var offset = scrollController.offset;
              scrollController.animateTo(
                offset - stride,
                duration: duration,
                curve: curve,
              );
            },
            onRightTap: () {
              var offset = scrollController.offset;
              scrollController.animateTo(
                offset + stride,
                duration: duration,
                curve: curve,
              );
            },
            button: widget.sectionDescr.header?.actionBtn != null
                ? OutlinedStandardButton(
                    widget.sectionDescr.header!.actionBtn!.text,
                    fgColor: textColor,
                    borderColor: textColor,
                    borderWidth: 0.5,
                    onTap: widget.sectionDescr.header!.actionBtn!.onTap,
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 4),
          HorizontalGridList(
            widget.sectionDescr,
            rowsCount: widget.sectionDescr.rowsCount,
            isBigTile: widget.sectionDescr.isBigTile,
            scrollController: scrollController,
            maxItemWidth: width,
          ),
        ],
      );
    });
  }
}

class _SectionHeader extends StatefulWidget {
  const _SectionHeader({
    this.title,
    this.subtitle,
    this.button,
    required this.onLeftTap,
    required this.onRightTap,
    required this.scrollController,
  });

  final String? title;
  final String? subtitle;
  final Widget? button;
  final void Function() onLeftTap;
  final void Function() onRightTap;

  final ScrollController scrollController;

  @override
  State<_SectionHeader> createState() => _SectionHeaderState();
}

class _SectionHeaderState extends State<_SectionHeader> {
  @override
  void initState() {
    widget.scrollController.addListener(buttonToggleListener);
    super.initState();
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(buttonToggleListener);
    super.dispose();
  }

  void buttonToggleListener() {
    var pos = widget.scrollController.position;

    if (shouldToggle(pos.minScrollExtent, isLeftBtbEnabled)) {
      isLeftBtbEnabled = !isLeftBtbEnabled;
      setState(() {});
    }
    if (shouldToggle(pos.maxScrollExtent, isRightBtbEnabled)) {
      isRightBtbEnabled = !isRightBtbEnabled;
      setState(() {});
    }
  }

  bool shouldToggle(double minOrMax, bool isCurrEnabled) {
    var offset = widget.scrollController.offset;
    return (minOrMax == offset) ? isCurrEnabled : !isCurrEnabled;
  }

  bool isLeftBtbEnabled = true;
  bool isRightBtbEnabled = true;

  bool isScrollable = true;

  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      buttonToggleListener();
      var pos = widget.scrollController.position;

      var prevIsScrollable = isScrollable;
      isScrollable = pos.extentTotal > pos.extentInside;
      if (prevIsScrollable != isScrollable) {
        setState(() {});
      }
    });

    Color textColor = context
        .select<AppearanceState, Color>((s) => s.colors[ColorType.text]!);
    Color subtitleColor = context
        .select<AppearanceState, Color>((s) => s.colors[ColorType.subtitle]!);

    double iconSize = 14;
    double iconButtonSize = 16;

    bool isPC = (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

    AppState appState = Provider.of<AppState>(context, listen: false);
    double fontSize = 20;
    if (appState.isWide) {
      fontSize = 28;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.title != null
                    ? Text(
                        widget.title!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w500,
                            height: 1),
                      )
                    : const SizedBox.shrink(),
                const SizedBox(height: 4),
                widget.subtitle != null
                    ? Text(
                        widget.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15, color: subtitleColor),
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
          Row(
            children: [
              widget.button ?? const SizedBox.shrink(),
              isScrollable && isPC
                  ? Row(
                      children: [
                        const SizedBox(width: 28),
                        ScrollButton(
                            icon: PhosphorIconsLight.caretLeft,
                            iconSize: iconSize,
                            iconButtonSize: iconButtonSize,
                            textColor: textColor,
                            onTap: isLeftBtbEnabled ? widget.onLeftTap : null),
                        const SizedBox(width: 14),
                        ScrollButton(
                            icon: PhosphorIconsLight.caretRight,
                            iconSize: iconSize,
                            iconButtonSize: iconButtonSize,
                            textColor: textColor,
                            onTap:
                                isRightBtbEnabled ? widget.onRightTap : null),
                      ],
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }
}

double _calcItemWidth(double width, bool isBigTile) {
  double itemWidth = width * 0.9;
  if (isBigTile) {
    itemWidth = width * 0.9 / 2;
  }
  return itemWidth;
}
