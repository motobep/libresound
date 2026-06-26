import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logger.dart';
import 'package:music_player/logic/playback/ProgressCounter.dart';
import 'package:music_player/states/AppearanceState.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

final secondaryColor = Colors.grey[500];

TextStyle styleDefault = TextStyle(
  color: secondaryColor,
  fontSize: 20,
  fontWeight: FontWeight.w400,
  letterSpacing: 0.5,
);

const double maxWidth = 400;
const addHeight = 10;

const double lineHeight = 40;
const double topPadding = 80;
const double paddingHor = 18.0;

const _scrollDelay = Duration(seconds: 3);

class LyricsObj {
  LyricsObj({
    required this.text,
    required this.isSynced,
    this.descr,
  });

  String text;
  final bool isSynced;
  final String? descr;

  @override
  bool operator ==(Object other) {
    return other is LyricsObj &&
        text == other.text &&
        isSynced == other.isSynced &&
        descr == other.descr;
  }

  @override
  int get hashCode => Object.hash(text, isSynced, descr);
}

List<LyricsLine> parseLyrics(String text, double width, TextStyle style) {
  gLogger.blue('parseLyrics');
  List<String> lines = text.split('\n');
  return lines
      .map((l) => LyricsLine.lyricsLineOrNull(l, width, style))
      .whereType<LyricsLine>()
      .toList();
}

class LyricsLine {
  Duration time;
  String line;
  double height;

  LyricsLine(this.time, this.line, this.height);

  static LyricsLine? lyricsLineOrNull(
      String string, double width, TextStyle style) {
    // RegExp exp = RegExp(r'\[([\d:\.]*)\](.*)');
    RegExp exp = RegExp(r'\[(\d*):(\d*)\.(\d*)\](.*)');

    Match? m = exp.firstMatch(string);
    if (m != null && m.groupCount == 4) {
      var d = Duration(
          minutes: int.parse(m.group(1)!),
          seconds: int.parse(m.group(2)!),
          milliseconds: int.parse(m.group(3)!) * 10);
      var line = m.group(4)!;
      line = line.trim();

      // Calc height
      double height = lineHeight;
      if (line != '') {
        TextPainter textPainter = TextPainter(
          text: TextSpan(text: line, style: style),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(maxWidth: width);
        height = textPainter.height + addHeight;
      }

      return LyricsLine(d, line, height);
    }
    return null;
  }
}

class Lrc extends StatefulWidget {
  const Lrc({
    super.key,
    required this.lyricsObj,
    required this.ticker,
    required this.jumpTo,
    required this.width,
  });

  final LyricsObj lyricsObj;
  final ProgressCounter ticker;
  final void Function(int ms) jumpTo;
  final double width;

  @override
  State<Lrc> createState() => _LrcState();
}

class _LrcState extends State<Lrc> {
  List<LyricsLine> lyrics = [];
  bool isChanging = false;
  double changingValue = 0;
  void update(int ms) {
    int idx = _getCurrLyricsLineIdx(widget.ticker.currMillisecs);
    if (lastIdx != idx) {
      lastIdx = idx;
      setState(() {});
    }
  }

  final _scrollController = ScrollController();

  final ProgressCounter animationTicker = ProgressCounter();
  void _animate(int ms) {
    _shouldAnimate = true;
  }

  void _userScroll() {
    // When user scrolls, stop animation for a bit
    if (_scrollController.position.userScrollDirection !=
        ScrollDirection.idle) {
      _shouldAnimate = false;
      animationTicker.tickTillMs(_scrollDelay.inMilliseconds);
    }
  }

  late TextStyle textStyle;

  @override
  void initState() {
    super.initState();

    var appearanceState = Provider.of<AppearanceState>(context, listen: false);
    textStyle = styleDefault.copyWith(fontFamily: appearanceState.fontPath);

    gLogger.blue('initState Lyrics');
    if (widget.lyricsObj.isSynced) {
      lyrics = parseLyrics(
          widget.lyricsObj.text, widget.width - paddingHor * 2, textStyle);
      widget.ticker.addListener(update, type: 'update');
    } else {
      lyrics = [];
    }

    animationTicker.addListener(_animate, type: 'end');
    _scrollController.addListener(_userScroll);
  }

  @override
  void didUpdateWidget(covariant oldWidget) {
    gLogger.blue('didUpdateWidget');
    super.didUpdateWidget(oldWidget);

    if (widget.lyricsObj != oldWidget.lyricsObj) {
      gLogger.blue('update Lyrics');
      if (widget.lyricsObj.isSynced) {
        lyrics = parseLyrics(
            widget.lyricsObj.text, widget.width - paddingHor * 2, textStyle);
      } else {
        gLogger.blue('set null');
        lyrics = [];
      }

      if (_scrollController.hasClients) {
        gLogger.view('lyrics to zero');
        _scrollController.animateTo(0,
            duration: CONFIG.scrollAnimationDuration, curve: Curves.easeOutCubic);
      }
      setState(() {});
    }

    if (widget.width != oldWidget.width && widget.lyricsObj.isSynced) {
      lyrics = parseLyrics(
          widget.lyricsObj.text, widget.width - paddingHor * 2, textStyle);
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.ticker.removeListener(update, type: 'update');

    animationTicker.removeListener(_animate, type: 'end');
    _scrollController.removeListener(_userScroll);
    super.dispose();
  }

  bool _shouldAnimate = true;

  int _getCurrLyricsLineIdx(int ms) {
    if (lyrics.isEmpty) return -1;
    if (lyrics.length < 2) return -1;

    final d = Duration(milliseconds: ms);
    for (var i = 0; i < lyrics.length - 1; i++) {
      final dLeft = lyrics[i].time;
      final dRight = lyrics[i + 1].time;
      if (dLeft <= d && d < dRight) {
        return i;
      }
    }
    final lastIdx = lyrics.length - 1;
    if (lyrics[lastIdx].time <= d) {
      return lastIdx;
    }
    return -1;
  }

  int _getLyricsLineMs(int idx) {
    assert(0 <= idx && idx < lyrics.length,
        'Idx=$idx out of [0; ${lyrics.length})');
    return lyrics[idx].time.inMilliseconds;
  }

  int lastIdx = 0;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.of(context);

    final Color textColor = colorScheme.onSurface;
    final Color subtitleColor = colorScheme.secondary;
    final style = styleDefault.copyWith(color: subtitleColor);

    late Widget w;
    if (widget.lyricsObj.isSynced == false) {
      // gLogger.blue('isSynced false');
      w = SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12.0),
            Text(widget.lyricsObj.text, style: style),
            if (widget.lyricsObj.descr != null) ...[
              const SizedBox(height: 16.0),
              Text(widget.lyricsObj.descr!,
                  style: style.copyWith(fontSize: 18.0)),
            ],
            const SizedBox(height: 12.0),
          ],
        ),
      );
    } else {
      // gLogger.blue('isSynced true');
      LyricsLine? currLyricsLine;
      int idx = lastIdx;
      if (idx != -1) {
        currLyricsLine = lyrics[idx];

        double accHeight = 0;
        for (var (i, l) in lyrics.indexed) {
          if (i == idx) {
            if (idx == 1) {
              accHeight -= lyrics[idx - 1].height;
            } else if (idx >= 2) {
              accHeight -= lyrics[idx - 2].height + lyrics[idx - 1].height;
            }
            break;
          }
          accHeight += l.height;
        }
        double offset = accHeight;
        if (_scrollController.hasClients &&
            _shouldAnimate &&
            offset != _scrollController.offset) {
          if (offset > _scrollController.position.maxScrollExtent) {
            offset = _scrollController.position.maxScrollExtent;
          }
          _scrollController.animateTo(
            offset,
            duration: CONFIG.scrollAnimationDuration,
            curve: Curves.easeOutCubic,
          );
        }
      }

      // var ff = Theme.of(context).textTheme.titleMedium!.fontFamily;
      // CustomPaint(
      //   size: Size(widget.width, 50),
      //   painter: MyPainter(lyrics, ff),
      // ),

      w = SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12.0),
            for (var (i, l) in lyrics.indexed)
              InkWell(
                onTap: () {
                  gLogger.log('tap [$i]');
                  _shouldAnimate = true;
                  int ms = _getLyricsLineMs(i);
                  widget.jumpTo(ms);
                },
                child: Container(
                  // color: l == currLyricsLine ? Colors.red : Colors.blue,
                  alignment: Alignment.centerLeft,
                  height: l.height,
                  width: widget.width,
                  child: (l.line != '')
                      ? Text(
                          textAlign: TextAlign.left,
                          '${l.line}\n',
                          style: l == currLyricsLine
                              ? styleDefault.copyWith(color: textColor)
                              : style,
                        )
                      : Icon(
                          PhosphorIconsRegular.tilde,
                          color:
                              l == currLyricsLine ? textColor : subtitleColor,
                          size: 20,
                        ),
                ),
              ),
            if (widget.lyricsObj.descr != null) ...[
              const SizedBox(height: 16.0),
              Text(widget.lyricsObj.descr!,
                  style: style.copyWith(fontSize: 18.0)),
            ],
            const SizedBox(height: 12.0),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: paddingHor),
      child: w,
    );
  }
}

class MyPainter extends CustomPainter {
  MyPainter(this.lyrics, this.fontFamily, {super.repaint});
  List<LyricsLine> lyrics;
  String? fontFamily;

  @override
  void paint(Canvas canvas, Size size) {
    var lyr = lyrics[6];
    TextPainter textPainter = TextPainter(
      text: TextSpan(
          text: lyr.line, style: styleDefault.copyWith(fontFamily: fontFamily)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: size.width);

    Offset offset = Offset(
      0, // Align to the left
      (size.height - textPainter.height) / 2, // Center vertically
    );
    textPainter.paint(canvas, offset);
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
