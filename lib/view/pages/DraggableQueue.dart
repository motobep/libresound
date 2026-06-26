import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:music_player/logger.dart';
import 'package:music_player/states/AppState.dart';
import 'package:music_player/view/App.dart' show gPadding;
import 'package:music_player/view/components/QueueOrLyrics.dart';
import 'package:music_player/view/components/SelectionInfo.dart';
import 'package:provider/provider.dart';

import 'package:music_player/logic/lang.dart';
import 'package:music_player/states/AppearanceState.dart';

const double minQueueSheetChildSize = 0.085;
const double maxQueuePercent = 1.0;
double maxQueueChildSize = -1.0;

final queueSheetController = DraggableScrollableController();

void queueSheetController_animateToZero() {
  queueSheetController.animateTo(0,
      duration: const Duration(milliseconds: 200), curve: Curves.easeOutBack);
}

void queueSheetController_animateToMax() {
  queueSheetController.animateTo(maxQueuePercent,
      duration: const Duration(milliseconds: 200), curve: Curves.easeOutBack);
}

class DraggableQueue extends StatelessWidget {
  const DraggableQueue({
    super.key,
    required this.width,
  });

  final double width;

  @override
  Widget build(BuildContext context) {
    gLogger.build(runtimeType);
    var appState = Provider.of<AppState>(context, listen: false);
    bool hasLyrics = context.select<AppState, bool>((s) => s.hasLyrics);
    bool isShowLyrics = context.select<AppState, bool>((s) => s.isShowLyrics);
    bool isQueueSheetOpened =
        context.select<AppState, bool>((s) => s.isQueueSheetOpened);

    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);

    double height = MediaQuery.of(context).size.height;
    double top = math.max(gPadding.top, EdgeInsets.zero.top);

    maxQueueChildSize = 1.0 - top / height;
    // gLogger.log('maxQueueChildSize=$maxQueueChildSize');

    var secondaryColor = ColorScheme.of(context).secondary;

    return DraggableScrollableSheet(
        snapAnimationDuration: const Duration(milliseconds: 180),
        snap: true,
        minChildSize: minQueueSheetChildSize,
        initialChildSize: minQueueSheetChildSize,
        maxChildSize: maxQueuePercent,
        controller: queueSheetController,
        builder: (BuildContext context, ScrollController scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: GestureDetector(
                child: Container(
                  width: width,
                  decoration: BoxDecoration(
                    color: appearanceState.queueBtnColor(),
                    borderRadius: const BorderRadius.vertical(
                      // top: Radius.elliptical(15, 12),
                      top: Radius.elliptical(15, 10),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        children: [
                          SizedBox(
                            height: height * minQueueSheetChildSize,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                InkWell(
                                  onTap: hasLyrics
                                      ? () {
                                          if (!isQueueSheetOpened) {
                                            gLogger.log('animateTo max');
                                            queueSheetController_animateToMax();
                                          } else {
                                            if (!isShowLyrics) {
                                              gLogger.log('animateTo min');
                                              queueSheetController_animateToZero();
                                            }
                                          }
                                          appState.isLyricsSelected = false;
                                          appState.update();
                                        }
                                      : null,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32.0),
                                    alignment: Alignment.center,
                                    child: Text(
                                      lang.Queue,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isShowLyrics
                                            ? secondaryColor
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                                if (hasLyrics)
                                  InkWell(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 32.0),
                                      alignment: Alignment.center,
                                      child: Text(
                                        lang.Lyrics,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: !isShowLyrics
                                              ? secondaryColor
                                              : null,
                                        ),
                                      ),
                                    ),
                                    onTap: () {
                                      if (!isQueueSheetOpened) {
                                        gLogger.log('animateTo max');
                                        queueSheetController_animateToMax();
                                      } else {
                                        if (isShowLyrics) {
                                          gLogger.log('animateTo min');
                                          queueSheetController_animateToZero();
                                        }
                                      }
                                      appState.isLyricsSelected = true;
                                      appState.update();
                                    },
                                  ),
                              ],
                            ),
                          ),
                          QueueOrLyrics(
                            width: width,
                            height: height *
                                (maxQueueChildSize - minQueueSheetChildSize),
                            shouldPop: true,
                            isInSheet: true,
                          ),
                        ],
                      ),
                      const Positioned(bottom: 30, child: SelectionInfo())
                    ],
                  ),
                ),
                onTap: () {
                  var target = queueSheetController.size <= 0.5
                      ? maxQueuePercent
                      : minQueueSheetChildSize;
                  queueSheetController.animateTo(target,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack);
                }),
          );
        });
  }
}
