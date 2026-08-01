import 'dart:math';

import 'package:m4a_tags_handler/Tags.dart';
import 'package:music_player/logic/enums.dart';
import 'package:music_player/states/AppState.dart';
import 'package:music_player/states/AppearanceState.dart';
import 'package:music_player/states/DownloadsState.dart';

import 'package:flutter/material.dart';
import 'package:music_player/states/PlaybackState.dart' show PlaybackState;
import 'package:music_player/view/components/dialogs.dart' show CoverDialog;
import 'package:phosphor_flutter/phosphor_flutter.dart'
    show PhosphorIconsRegular;
import 'package:provider/provider.dart';

import 'package:music_player/logic/MusicItem.dart';

class TrackDescription extends StatelessWidget {
  const TrackDescription({
    super.key,
    required this.imgSize,
    required this.musicItem,
  });

  final double imgSize;
  final MusicItem musicItem;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);

    var progressFormatted = context
        .select<PlaybackState, String>((s) => s.playback.progressFormatted);

    String subtitle = appState.isWide
        ? '${progressFormatted} / ${musicItem.time} · ${musicItem.subtitle}'
        : musicItem.subtitle;

    return Row(
      children: [
        InkWell(
          onTap: appState.isWide
              ? () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return const CoverDialog();
                      });
                }
              : null,
          child: Container(
            width: imgSize,
            height: imgSize,
            margin: const EdgeInsets.only(right: 10),
            child: CoverGuarded(
              musicItem: musicItem,
              imgSize: imgSize,
              imgRadius: appearanceState.thumbnailRadius,
              loaderSize: 25,
              loaderStrokeWidth: 3,
              imageBrokenSize: imgSize * 0.6,
            ),
          ),
        ),
        Expanded(
          child: _TrackDescriptionText(
            title: musicItem.title,
            subtitle: subtitle,
          ),
        ),
      ],
    );
  }
}

class _TrackDescriptionText extends StatelessWidget {
  const _TrackDescriptionText({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    Color secondaryText = ColorScheme.of(context).secondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          overflow: TextOverflow.ellipsis,
        ),
        const Padding(padding: EdgeInsets.only(top: 8)),
        Text(
          subtitle,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: secondaryText),
        ),
      ],
    );
  }
}

class CoverGuarded extends StatelessWidget {
  const CoverGuarded({
    super.key,
    required this.musicItem,
    required this.imgSize,
    required this.imgRadius,
    required this.loaderSize,
    required this.loaderStrokeWidth,
    required this.imageBrokenSize,
  });

  final MusicItem musicItem;
  final double imgSize;
  final double imgRadius;
  final double loaderSize;
  final double loaderStrokeWidth;
  final double imageBrokenSize;

  @override
  Widget build(BuildContext context) {
    bool isLoading = context.select<DownloadsState, bool>((downloadsState) =>
        downloadsState.hasPlayId(musicItem.sourceId, musicItem.id));
    final playState =
        context.select<PlaybackState, PlayState>((s) => s.playback.playState);
    bool isLoadingPlayState = playState == PlayState.loading;

    bool isShowLoader = isLoading || isLoadingPlayState;
    bool isShowBroken = !isShowLoader && (playState == PlayState.notReady);

    return Stack(alignment: Alignment.center, children: <Widget>[
      SizedBox(
        width: imgSize,
        child: Cover(
          picture: musicItem.tags.picture,
          radius: imgRadius,
        ),
      ),
      if (isShowBroken)
        Container(
          color: const Color(0x32000000),
          width: imgSize,
          height: imgSize,
          child: Center(
            child: Icon(PhosphorIconsRegular.imageBroken,
                size: imageBrokenSize, color: Colors.red),
          ),
        ),
      if (isShowLoader)
        Container(
          color: const Color(0x32000000),
          width: imgSize,
          height: imgSize,
          child: Center(
            child: SizedBox(
              width: loaderSize,
              height: loaderSize,
              child: CircularProgressIndicator(strokeWidth: loaderStrokeWidth),
            ),
          ),
        ),
    ]);
  }
}

class ThumbnailWithLoader extends StatelessWidget {
  const ThumbnailWithLoader({
    super.key,
    required this.picture,
    required this.size,
    required this.isLoading,
  });

  final PictureTag? picture;
  final double size;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: <Widget>[
      Thumbnail(picture: picture, size: size),
      isLoading
          ? Container(
              color: const Color(0x32000000),
              width: size,
              height: size,
              child: const Center(
                child: SizedBox(
                  width: 25,
                  height: 25,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
            )
          : const SizedBox.shrink(),
    ]);
  }
}

class Thumbnail extends StatelessWidget {
  const Thumbnail({
    super.key,
    this.picture,
    this.size = 50,
  });

  final PictureTag? picture;
  final double size;

  @override
  Widget build(BuildContext context) {
    double radius = context.select<AppearanceState, double>(
        (appearanceState) => appearanceState.thumbnailRadius);
    return _CustomPicture(
      picture: picture,
      sideSize: size,
      picSize: max(size.toInt(), 100),
      radius: radius,
    );
  }
}

typedef Cover = _CustomPicture;

class _CustomPicture extends StatelessWidget {
  const _CustomPicture({
    this.picture,
    this.sideSize,
    this.picSize,
    this.radius = 0.0,
  });

  final PictureTag? picture;
  final double? sideSize;
  final int? picSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: getContent(),
    );
  }

  Widget getContent() {
    if (picture != null) {
      /* if (sideSize != null) {
    // final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
        return Image.memory(
          picture!.bytes,
          fit: BoxFit.contain,
          width: sideSize,
          height: sideSize,
          cacheWidth: (sideSize! * devicePixelRatio).round(),
          cacheHeight: (sideSize! * devicePixelRatio).round(),
        );
      } */
      return Image.memory(
        picture!.bytes,
        fit: BoxFit.contain,
        width: sideSize,
        height: sideSize,
      );
    }

    var imgPlaceholder = Image.asset(
      'assets/images/logo_mp_512_gaps_gray.png',
      fit: BoxFit.contain,
      width: sideSize,
      height: sideSize,
    );
    return imgPlaceholder;
  }
}
