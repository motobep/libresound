import 'package:flutter/material.dart';
import 'package:music_player/logger.dart';
import 'package:music_player/logic/MusicItem.dart';
import 'package:music_player/logic/playback/Playback.dart';
import 'package:music_player/states/AppState.dart';
import 'package:music_player/states/PlaybackState.dart';
import 'package:music_player/view/components/Lrc.dart';
import 'package:music_player/view/components/Queue.dart';
import 'package:provider/provider.dart';

class QueueOrLyrics extends StatelessWidget {
  const QueueOrLyrics({
    super.key,
    required this.width,
    required this.height,
    this.shouldPop = false,
    this.isInSheet = false,
  });

  final double width;
  final double height;
  final bool shouldPop;
  final bool isInSheet;

  @override
  Widget build(BuildContext context) {
    gLogger.build(runtimeType);
    var playback = Provider.of<PlaybackState>(context, listen: false).playback;
    MusicItem mi = context.select<PlaybackState, MusicItem>(
        (s) => s.playback.getCurrentMusicItem());

    bool isShowLyrics = context.select<AppState, bool>((s) => s.isShowLyrics);

    if (isShowLyrics)
      return _LyricsQueue(
          width: width, height: height, mi: mi, playback: playback);
    else
      return Queue(
        width: width,
        height: height,
        shouldPop: shouldPop,
        isInSheet: isInSheet,
      );
  }
}

class _LyricsQueue extends StatefulWidget {
  const _LyricsQueue({
    required this.width,
    required this.height,
    required this.mi,
    required this.playback,
  });

  final double width;
  final double height;
  final MusicItem mi;
  final Playback playback;

  @override
  State<_LyricsQueue> createState() => _LyricsQueueState();
}

class _LyricsQueueState extends State<_LyricsQueue> {
  LyricsObj? lyricsObj;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadLyrics();
  }

  void loadLyrics() async {
    var appState = Provider.of<AppState>(context, listen: false);
    var pluginManager = appState.pluginManager;
    var p = pluginManager.lyrics[pluginManager.getLyricsPluginId()];
    if (p == null) {
      lyricsObj = null;
      setState(() {});
      return;
    }

    var mi = widget.mi;
    isLoading = true;
    setState(() {});
    try {
      lyricsObj = await p.getLyricsAsync(mi);
    } catch (e) {
      gLogger.warn('Lyrics exception: ${e}');
    }
    isLoading = false;
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mi != oldWidget.mi) {
      lyricsObj = null;
      setState(() {});
      loadLyrics();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget w;
    if (isLoading) {
      w = const Center(
        child: SizedBox(
          width: 35,
          height: 35,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      );
    } else {
      w = (lyricsObj == null)
          ? const SizedBox.shrink()
          : Lrc(
              lyricsObj: lyricsObj!,
              ticker: widget.playback.progressCounter,
              jumpTo: (int ms) {
                double ratio = widget.playback.progressCounter.toRatio(ms);
                widget.playback.seek(ratio);
              },
              width: widget.width,
            );
    }
    return SizedBox(width: widget.width, height: widget.height, child: w);
  }
}
