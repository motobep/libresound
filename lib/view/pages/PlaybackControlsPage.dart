import 'dart:async';
import 'dart:math' as math;

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:music_player/logger.dart';
import 'package:music_player/states/SelectionState.dart';
import 'package:provider/provider.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:music_player/states/AppState.dart';
import 'package:music_player/states/AppearanceState.dart';
import 'package:music_player/states/DownloadsState.dart';
import 'package:music_player/states/PlaybackState.dart';

import 'package:music_player/consts.dart' as CONSTS;
import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logic/tapHandlers.dart';
import 'package:music_player/logic/MusicItem.dart' show MusicItem;
import 'package:music_player/logic/playback/Playback.dart' show Playback;
import 'package:music_player/logic/enums.dart';

import 'package:music_player/view/components/parts.dart';
import 'package:music_player/view/components/getIconFuncs.dart'
    show getPlayFillIcon, getRepeatIcon;
import 'package:music_player/view/pages/DraggableQueue.dart';

const double minSheetSizePercent = 0.085;

const double mainHorPad = 10;
const double innerHorPad = 24;

const double iconLgSize = 36; // was 34
const double iconMdSize = 32; // was 30
const double iconSmSize = 26; // was 24

class PlaybackControlsBody extends StatelessWidget {
  const PlaybackControlsBody({super.key, required this.onCloseTap});

  final void Function() onCloseTap;

  static _MyCarouselSliderController myCarouselCtrlr =
      _MyCarouselSliderController();

  @override
  Widget build(BuildContext context) {
    gLogger.build('PlaybackControlsPage');

    AppState appState = Provider.of<AppState>(context, listen: false);
    String fontPath =
        context.select<AppearanceState, String>((s) => s.fontPath);

    Playback playback =
        Provider.of<PlaybackState>(context, listen: false).playback;
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    MusicItem musicItem = context.select<PlaybackState, MusicItem>(
        (s) => s.playback.getCurrentMusicItem());

    bool playback_canNext =
        context.select<PlaybackState, bool>((s) => s.playback.canNext);
    bool playback_canPrev =
        context.select<PlaybackState, bool>((s) => s.playback.canPrev);
    PlayState playback_playState =
        context.select<PlaybackState, PlayState>((s) => s.playback.playState);
    RepeatState playback_repeatState = context
        .select<PlaybackState, RepeatState>((s) => s.playback.repeatState);

    IconData playIcon = getPlayFillIcon(playback_playState);
    IconData repeatIcon = getRepeatIcon(playback_repeatState);

    double picMaxWidth = width - (mainHorPad + innerHorPad) * 2;
    double picMaxWidthViaHeight = height * 0.4;

    double imgSize = math.min(picMaxWidth, picMaxWidthViaHeight);

    final double maxTextWidth = width - (mainHorPad + innerHorPad) * 2;

    // Put Carousel in position
    final currTrackIdx =
        context.select<PlaybackState, int>((s) => s.playback.queue.currentIdx);
    if (myCarouselCtrlr.ready) {
      if (currTrackIdx != myCarouselCtrlr.pageIdx) {
        if ((currTrackIdx - myCarouselCtrlr.pageIdx!).abs() == 1) {
          gLogger.view('animateToPage ready');
          myCarouselCtrlr.animateToPage(
            currTrackIdx,
            duration: CONFIG.carouselAnimationDuration,
            curve: Curves.easeOutCubic,
          );
        } else {
          gLogger.view('jumpToPage ready');
          myCarouselCtrlr.jumpToPage(currTrackIdx);
        }
      }
    } else {
      myCarouselCtrlr.pageIdx = currTrackIdx;
    }

    bool isSelectionHidden =
        context.select<SelectionState, bool>((s) => s.isEmpty);

    return Container(
      color: ColorScheme.of(context).surface,
      child: Stack(
        children: [
          Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Padding(
              padding: const EdgeInsets.only(
                  top: 8.0, left: mainHorPad, right: mainHorPad),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      onCloseTap();
                    },
                    icon: const Icon(PhosphorIconsLight.caretDown),
                    iconSize: iconSmSize,
                  ),
                  IconButton(
                    onPressed: isSelectionHidden
                        ? () {
                            showCurrItemDialog(musicItem,
                                sectionIndex: CONSTS.queueSectionIdx);
                          }
                        : null,
                    icon: const Icon(PhosphorIconsRegular.dotsThreeVertical),
                    iconSize: iconSmSize,
                  ),
                ],
              ),
            ),
            _ImagesCarousel(
              imgSize: imgSize,
              myCarouselCtrlr: myCarouselCtrlr,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: innerHorPad),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: SizedBox(
                      height: 32,
                      child: _getTextOrScrolling(
                        musicItem.title,
                        TextStyle(
                          fontFamily: fontPath,
                          fontSize: 22,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w600,
                        ),
                        maxTextWidth,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: () async {
                      onCloseTap();
                      appState.triggerSourceEvent(musicItem.sourceId,
                          'TapArtistTitle', {'musicItem': musicItem});
                    },
                    child: SizedBox(
                      height: 24,
                      child: _getTextOrScrolling(
                        musicItem.artistName,
                        TextStyle(
                          fontFamily: fontPath,
                          fontSize: 16,
                          letterSpacing: 0.5,
                          color: ColorScheme.of(context).secondary,
                        ),
                        maxTextWidth,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: PlaybackSlider(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 10.0),
                            child: Builder(builder: (ctx) {
                              var progressFormatted =
                                  ctx.select<PlaybackState, String>(
                                      (s) => s.playback.progressFormatted);
                              return Text(progressFormatted);
                            }),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: Text(musicItem.time),
                          ),
                        ],
                      )
                    ],
                  ), // Range,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          playback.shuffle();
                        },
                        icon: const Icon(PhosphorIconsLight.shuffle),
                        iconSize: iconSmSize,
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: playback_canPrev
                            ? () {
                                playback.playPrev();

                                final mi = playback.queue.getCurrentMusicItem();
                                appState.triggerSourceEvent(mi.sourceId,
                                    'OpenedPlaybackPlayPrev', mi.toJson());
                              }
                            : null,
                        icon: const Icon(PhosphorIconsLight.skipBack),
                        disabledColor: Colors.white38,
                        iconSize: iconMdSize,
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () async {
                          await playback.togglePlayback();
                        },
                        icon: Container(
                            padding: const EdgeInsets.all(18.0),
                            decoration: BoxDecoration(
                              color: ColorScheme.of(context).primary,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(80)),
                            ),
                            child: Icon(
                              playIcon,
                              color: ColorScheme.of(context).surface,
                            )),
                        iconSize: iconLgSize,
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: playback_canNext
                            ? () {
                                playback.playNext();

                                final mi = playback.queue.getCurrentMusicItem();
                                appState.triggerSourceEvent(mi.sourceId,
                                    'OpenedPlaybackPlayNext', mi.toJson());
                              }
                            : null,
                        icon: const Icon(PhosphorIconsLight.skipForward),
                        disabledColor: Colors.white38,
                        iconSize: iconMdSize,
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: () {
                          playback.toggleRepeat();
                        },
                        icon: Icon(repeatIcon),
                        iconSize: iconSmSize,
                      ),
                    ],
                  ), // Controls,
                  // const SizedBox(height: 12),
                ],
              ),
            ),
            SizedBox(
              height: height * minSheetSizePercent,
            ),
          ]),
          DraggableQueue(width: width),
        ],
      ),
    );
  }
}

class _MyCarouselSliderController extends CarouselSliderControllerImpl {
  int? pageIdx;

  @override
  void jumpToPage(int page) {
    pageIdx = page;
    super.jumpToPage(page);
  }

  @override
  Future<void> animateToPage(int page,
      {Duration? duration = CONFIG.carouselAnimationDuration,
      Curve? curve = Curves.linear}) {
    pageIdx = page;
    return super.animateToPage(page, duration: duration, curve: curve);
  }
}

class _ImagesCarousel extends StatelessWidget {
  const _ImagesCarousel({
    required this.imgSize,
    required this.myCarouselCtrlr,
  });

  final double imgSize;
  final _MyCarouselSliderController myCarouselCtrlr;

  @override
  Widget build(BuildContext context) {
    gLogger.build(runtimeType);
    AppState appState = Provider.of<AppState>(context, listen: false);
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);
    Playback playback =
        Provider.of<PlaybackState>(context, listen: false).playback;

    MusicItem musicItem = context.select<PlaybackState, MusicItem>(
        (s) => s.playback.getCurrentMusicItem());
    bool isLoading = context.select<DownloadsState, bool>((downloadsState) =>
        downloadsState.hasPlayId(musicItem.sourceId, musicItem.id));

    final playState =
        context.select<PlaybackState, PlayState>((s) => s.playback.playState);
    bool isLoadingPlayState = playState == PlayState.loading;

    double width = MediaQuery.of(context).size.width;

    bool isPlaybackControlsOpened = context.select<AppState, bool>(
        (s) => s.controlsSheetOpenDegree == OpenDegree.opened);
    if (isPlaybackControlsOpened) {
      context.select<PlaybackState, int>((s) => s.playback.queue.updateIdx);
    }

    return SizedBox(
      width: width,
      child: CarouselSlider.builder(
          itemCount: playback.queue.length,
          carouselController: myCarouselCtrlr,
          options: CarouselOptions(
            initialPage: playback.queue.currentIdx,
            viewportFraction: 1.0,
            enableInfiniteScroll: false,
            enlargeCenterPage: false,
            height: imgSize,
            onScrolled: (pos) {
              // gLogger.view('pos=$pos');
              final int currIdx = myCarouselCtrlr.pageIdx!;
              if (currIdx - 1 == pos!.ceil()) {
                gLogger.view('jumpToPage left before');
                myCarouselCtrlr.jumpToPage(currIdx - 1);

                playback.playByIdx_n(currIdx - 1);

                final mi = playback.queue.getCurrentMusicItem();
                appState.triggerSourceEvent(
                    mi.sourceId, 'OpenedPlaybackPlayPrev', mi.toJson());
              }
              if (currIdx + 1 == pos.toInt()) {
                gLogger.view('jumpToPage right before');
                myCarouselCtrlr.jumpToPage(currIdx + 1);

                playback.playByIdx_n(currIdx + 1);

                final mi = playback.queue.getCurrentMusicItem();
                appState.triggerSourceEvent(
                    mi.sourceId, 'OpenedPlaybackPlayNext', mi.toJson());
              }
            },
          ),
          itemBuilder: (ctx, index, realIdx) {
            var el = playback.queue.getMusicItem(index);
            return Stack(alignment: Alignment.center, children: <Widget>[
              SizedBox(
                width: imgSize,
                child: Cover(
                  picture: el.picture,
                  radius: appearanceState.coverRadius,
                ),
              ),
              isLoading || isLoadingPlayState
                  ? Container(
                      color: const Color(0x32000000),
                      width: imgSize,
                      height: imgSize,
                      child: const Center(
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(strokeWidth: 4),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ]);
          }),
    );
  }
}

class PlaybackSlider extends StatefulWidget {
  const PlaybackSlider({
    this.thumbRadius = 6.0,
    this.activeThumbRadius = 8.0,
    super.key,
  });

  final double thumbRadius;
  final double activeThumbRadius;

  @override
  State<PlaybackSlider> createState() => _PlaybackSliderState();
}

class _PlaybackSliderState extends State<PlaybackSlider> {
  double thumbRadius = 6.0;

  @override
  void initState() {
    thumbRadius = widget.thumbRadius;
    super.initState();
  }

  bool isChanging = false;
  double changingValue = 0;

  @override
  Widget build(BuildContext context) {
    Playback playback =
        Provider.of<PlaybackState>(context, listen: false).playback;
    bool isIdle =
        context.select<PlaybackState, bool>((s) => s.playback.isIdle());

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: thumbRadius),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 8.0),
      ),
      child: Builder(builder: (ctx) {
        var progressRatio =
            ctx.select<PlaybackState, double>((s) => s.playback.progressRatio);
        final v = isChanging ? changingValue : progressRatio;
        return Slider(
          value: v,
          onChanged: isIdle
              ? null
              : (value) {
                  gLogger.view('onChanged - $value');
                  setState(() {
                    changingValue = value;
                  });
                },
          onChangeStart: (value) {
            gLogger.view('onStart - $value');
            setState(() {
              thumbRadius = widget.activeThumbRadius;
              isChanging = true;
            });
          },
          onChangeEnd: (value) async {
            gLogger.view('onEnd - $value');
            try {
              await playback.seek(value);
            } finally {
              setState(() {
                thumbRadius = widget.thumbRadius;
                isChanging = false;
              });
            }
          },
        );
      }),
    );
  }
}

class ScrollingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double ratioOfBlankToScreen;
  final double textWidth;

  const ScrollingText(
    this.text, {
    super.key,
    required this.textWidth,
    this.style,
    this.ratioOfBlankToScreen = 0.25,
  });

  @override
  State<StatefulWidget> createState() {
    return ScrollingTextState();
  }
}

class ScrollingTextState extends State<ScrollingText>
    with SingleTickerProviderStateMixin {
  ScrollController? scrollController;
  double? screenWidth;
  double? screenHeight;
  double position = 0.0;
  Timer? timer;
  final double _moveDistance = 6.0;
  final GlobalKey _key = GlobalKey();

  static const double gapWidth = 60;
  static const double textGapWidth = 20;

  static const int _timerRest = 50;
  static const int millisecondsToWait = 2000;
  static const int ticksToWait = millisecondsToWait ~/ _timerRest;
  int restTicksToWait = ticksToWait;

  @override
  void initState() {
    restTicksToWait = ticksToWait;
    super.initState();
    scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((callback) {
      startTimer();
    });
  }

  void startTimer() {
    if (_key.currentContext != null) {
      timer = Timer.periodic(const Duration(milliseconds: _timerRest), (timer) {
        if (restTicksToWait > 0) {
          restTicksToWait--;
          return;
        }
        if (position >= widget.textWidth + gapWidth + textGapWidth) {
          position = 0;
          scrollController!.jumpTo(position);

          restTicksToWait = ticksToWait;
          return;
        }
        position += _moveDistance;
        scrollController!.animateTo(position,
            duration: const Duration(milliseconds: _timerRest),
            curve: Curves.linear);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
  }

  Widget getBothEndsChild() {
    return SizedBox(
      width: widget.textWidth + textGapWidth,
      child: Text(
        widget.text,
        style: widget.style,
        softWrap: false,
      ),
    );
  }

  Widget getCenterChild() {
    return Container(
      width: gapWidth,
    );
  }

  @override
  void dispose() {
    super.dispose();
    timer!.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(0),
      key: _key,
      scrollDirection: Axis.horizontal,
      controller: scrollController,
      physics: const NeverScrollableScrollPhysics(),
      children: <Widget>[
        getBothEndsChild(),
        getCenterChild(),
        getBothEndsChild(),
      ],
    );
  }
}

Widget _getTextOrScrolling(String title, TextStyle textStyle, double maxWidth) {
  final textSize = _textSize(title, textStyle);
  return textSize.width > maxWidth
      ? ScrollingText(title, style: textStyle, textWidth: textSize.width)
      : Text(title, style: textStyle);
}

Size _textSize(String text, TextStyle style) {
  final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr)
    ..layout(minWidth: 0, maxWidth: double.infinity);
  return textPainter.size;
}
