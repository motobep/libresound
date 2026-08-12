import 'package:flutter/material.dart';
import 'package:music_player/logger.dart';
import 'package:music_player/states/AppearanceState.dart';
import 'package:music_player/view/components/buttons.dart';

import 'package:provider/provider.dart';

class TopTabs extends StatefulWidget {
  const TopTabs({
    super.key,
    required this.elements,
    required this.initial,
    required this.onSelect,
    required this.mainAxisAlignment,
  });

  final List<String> elements;
  final int initial;
  final bool Function(int idx) onSelect;
  final MainAxisAlignment mainAxisAlignment;

  @override
  State<TopTabs> createState() => _TopTabsState();
}

class _TopTabsState extends State<TopTabs> {
  Duration animationDuration = const Duration(milliseconds: 100);
  final animationCurve = Curves.easeOut;

  late List<GlobalKey> keysList;
  late List<RenderBox?> widthList;
  bool isWidthsReady = false;

  void _setWidthEl(int index, RenderBox box) {
    setState(() {
      widthList[index] = box;
      if (widthList.every((el) => el != null)) {
        setState(() {
          isWidthsReady = true;
        });
      }
    });
  }

  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    keysList = widget.elements.map((_) => GlobalKey()).toList();
    widthList = List.filled(widget.elements.length, null);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant oldWidget) {
    super.didUpdateWidget(oldWidget);
    gLogger.blue('didUpdateWidget $runtimeType');

    if (oldWidget.initial != widget.initial) {
      currIdx = widget.initial;
    }
    if (oldWidget.elements != widget.elements) {
      isWidthsReady = false;
      keysList = widget.elements.map((_) => GlobalKey()).toList();
      widthList = List.filled(widget.elements.length, null);
    }
  }

  late int currIdx = widget.initial;

  @override
  Widget build(BuildContext context) {
    gLogger.build(runtimeType);

    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);

    final length = widget.elements.length;

    return Container(
      height: 33.0,
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
          width: 1,
          color: appearanceState.chosenTabColor(),
        )),
      ),
      padding: EdgeInsets.symmetric(
          horizontal: appearanceState.contentPaddingBaseHor + 10),
      child: Scrollbar(
        thickness: 2.0,
        controller: scrollController,
        child: ListView(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          children: [
            Stack(
              children: [
                isWidthsReady
                    ? AnimatedPositioned(
                        left:
                            widthList[currIdx]!.localToGlobal(Offset.zero).dx -
                                widthList[0]!.localToGlobal(Offset.zero).dx,
                        bottom: 0,
                        duration: animationDuration,
                        curve: animationCurve,
                        child: Container(
                          color: ColorScheme.of(context).primary,
                          width: widthList[currIdx]!.size.width,
                          height: 2,
                        ),
                      )
                    : const SizedBox.shrink(),
                Row(
                  mainAxisAlignment: widget.mainAxisAlignment,
                  children: [
                    for (var i = 0; i < length; i++)
                      Padding(
                        padding:
                            EdgeInsets.only(right: i != length - 1 ? 24.0 : 0),
                        child: FilterButton(
                          widget.elements[i],
                          key: keysList[i],
                          globalKey: keysList[i],
                          onTap: () async {
                            bool update = widget.onSelect(i);
                            if (update) {
                              setState(() {
                                currIdx = i;
                              });
                            }
                          },
                          setWidth: (box) {
                            _setWidthEl(i, box);
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
