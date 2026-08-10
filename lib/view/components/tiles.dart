import 'package:flutter/material.dart';
import 'package:music_player/logic/MusicItem.dart' show MusicItem;
import 'package:music_player/logic/lang.dart';
import 'package:provider/provider.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:m4a_tags_handler/Tags.dart';

import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/states/AppearanceState.dart';

import 'package:music_player/view/components/parts.dart';
import 'package:music_player/view/components/inputs.dart';

class Tile extends StatelessWidget {
  const Tile({
    required this.title,
    required this.onTap,
    required this.onAction,
    required this.onLongPress,
    this.subtitle,
    this.picture,
    this.isLoading = false,
    this.isFocused = false,
    this.isSelected = false,
    this.isShowCheckbox = false,
    this.height,
    super.key,
  });

  final String title;
  final String? subtitle;
  final PictureTag? picture;
  final void Function()? onTap;
  final void Function([Offset?])? onAction;
  final void Function()? onLongPress;
  final bool isLoading;
  final bool isFocused;
  final bool isSelected;
  final bool isShowCheckbox;
  final double? height;

  @override
  Widget build(BuildContext context) {
    Color textColor = context
        .select<AppearanceState, Color>((s) => s.colors[ColorType.text]!);

    return TileBase(
      title: title,
      subtitle: subtitle,
      picture: picture,
      trailing: SizedBox(
        width: 20 + 4,
        child: IconButton(
          icon: const Icon(PhosphorIconsRegular.dotsThreeVertical),
          onPressed: onAction,
          color: textColor,
          iconSize: 20,
          style: IconButton.styleFrom(
            minimumSize: const Size.fromRadius(0),
            padding: const EdgeInsets.symmetric(vertical: 12.0),
          ),
        ),
      ),
      onTap: onTap,
      onSecondaryTap: ([Offset? pos]) {
        onAction?.call(pos);
      },
      onLongPress: onLongPress,
      isFocused: isFocused,
      isLoading: isLoading,
      isSelected: isSelected,
      isShowCheckbox: isShowCheckbox,
      height: height,
    );
  }
}

class TileBase extends StatelessWidget {
  const TileBase({
    required this.title,
    required this.onTap,
    required this.onSecondaryTap,
    required this.onLongPress,
    required this.trailing,
    this.subtitle,
    this.picture,
    this.isLoading = false,
    this.isFocused = false,
    this.isCurrent = false,
    this.isSelected = false,
    this.isShowCheckbox = false,
    this.height,
    super.key,
  });

  final String title;
  final String? subtitle;
  final PictureTag? picture;
  final Widget trailing;
  final void Function()? onTap;
  final void Function([Offset?])? onSecondaryTap;
  final void Function()? onLongPress;
  final bool isLoading;
  final bool isFocused;
  final bool isCurrent;
  final bool isSelected;
  final bool isShowCheckbox;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final Color focusColor =
        context.select<AppearanceState, Color>((s) => s.focusColor());
    final Color selectedBgColor =
        context.select<AppearanceState, Color>((s) => s.lerpBgColor(0.04));
    Color borderColor =
        context.select<AppearanceState, Color>((s) => s.lerpBgColor(0.40));
    Color? bgColor;
    if (isFocused) {
      bgColor = focusColor;
    } else if (isCurrent) {
      bgColor = selectedBgColor;
    }
    final listTileTheme = Theme.of(context).listTileTheme;

    return Container(
      color: bgColor,
      height: height,
      child: GestureDetector(
        child: ListTile(
          titleTextStyle: listTileTheme.titleTextStyle,
          subtitleTextStyle: listTileTheme.subtitleTextStyle,
          leading: ThumbnailWithLoader(
              picture: picture, size: CONFIG.smThumbnail, isLoading: isLoading),
          visualDensity:
              const VisualDensity(vertical: CONFIG.tileVisualDendity),
          title: Text(
            title == CONFIG.favouritesPlaylist ? lang.Favourites : title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(height: 1.2),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!.replaceAll(
                      '\r\n', ' '), // WARNING: crushing because of \r\n
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: isShowCheckbox
              ? CheckboxInput(
                  initial: isSelected,
                  borderColor: borderColor,
                  onSelect: (_) {
                    onLongPress?.call();
                    return false;
                  },
                )
              : trailing,
          horizontalTitleGap: 15,
          selected: isCurrent,
          onTap: onTap,
          onLongPress: () {
            onLongPress?.call();
          },
        ),
        onSecondaryTapUp: (details) {
          var pos = details.globalPosition;
          onSecondaryTap?.call(pos);
        },
      ),
    );
  }
}

class BigTile extends StatelessWidget {
  const BigTile({
    required this.title,
    required this.onTap,
    required this.onAction,
    required this.onLongPress,
    this.subtitle,
    this.picture,
    this.isLoading = false,
    this.isFocused = false,
    this.isSelected = false,
    this.isShowCheckbox = false,
    this.width,
    required this.textHeight,
    super.key,
  });

  final String title;
  final String? subtitle;
  final PictureTag? picture;
  final void Function()? onTap;
  final void Function([Offset?])? onAction;
  final void Function()? onLongPress;
  final bool isLoading;
  final bool isFocused;
  final bool isSelected;
  final bool isShowCheckbox;
  final double? width;
  final double textHeight;

  @override
  Widget build(BuildContext context) {
    Color focusColor =
        context.select<AppearanceState, Color>((s) => s.focusColor());
    Color textColor = context
        .select<AppearanceState, Color>((s) => s.colors[ColorType.text]!);
    Color subtitleColor = context
        .select<AppearanceState, Color>((s) => s.colors[ColorType.subtitle]!);
    Color borderColor =
        context.select<AppearanceState, Color>((s) => s.lerpBgColor(0.40));

    const double iconSize = 20;
    const double iconHorPadding = 1.0;

    const double textGap = 10;
    const double subtitleGap = 4;
    const double padding = 6;
    double thumbnailSize = width! - padding * 2;

    return InkWell(
      onTap: onTap,
      onLongPress: () {
        onLongPress?.call();
      },
      onSecondaryTapUp: (details) {
        var pos = details.globalPosition;
        onAction?.call(pos);
      },
      mouseCursor: SystemMouseCursors.click,
      child: Container(
        color: isFocused ? focusColor : null,
        width: width,
        child: Padding(
          padding: const EdgeInsets.all(padding),
          child: Column(
            children: [
              ThumbnailWithLoader(
                  picture: picture, size: thumbnailSize, isLoading: isLoading),
              SizedBox(
                width: thumbnailSize,
                height: textHeight,
                child: Padding(
                  padding: const EdgeInsets.only(top: textGap),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width:
                            thumbnailSize - (iconSize + iconHorPadding * 2 + 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title == CONFIG.favouritesPlaylist
                                  ? lang.Favourites
                                  : title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(height: 1.4),
                            ),
                            const SizedBox(height: subtitleGap),
                            subtitle != null
                                ? Text(
                                    subtitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: subtitleColor),
                                  )
                                : const SizedBox.shrink(),
                          ],
                        ),
                      ),
                      isShowCheckbox
                          ? CheckboxInput(
                              initial: isSelected,
                              borderColor: borderColor,
                              onSelect: (_) {
                                onLongPress?.call();
                                return false;
                              },
                            )
                          : SizedBox(
                              width: iconSize + iconHorPadding * 2,
                              height: iconSize + 16.0,
                              child: IconButton(
                                color: textColor,
                                iconSize: iconSize,
                                style: IconButton.styleFrom(
                                  minimumSize: const Size.fromRadius(0),
                                  padding: const EdgeInsets.only(
                                    left: iconHorPadding,
                                    right: iconHorPadding,
                                    top: 1,
                                    bottom: 15,
                                  ),
                                ),
                                icon: const Icon(
                                    PhosphorIconsRegular.dotsThreeVertical),
                                onPressed: onAction,
                              ),
                            ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class WideMiTile extends StatefulWidget {
  const WideMiTile({
    required this.mi,
    required this.onTap,
    required this.onAction,
    required this.onLongPress,
    this.isLoading = false,
    this.isFocused = false,
    this.isSelected = false,
    this.isShowCheckbox = false,
    this.height,
    super.key,
  });

  final MusicItem mi;

  final void Function()? onTap;
  final void Function([Offset?])? onAction;
  final void Function()? onLongPress;
  final bool isLoading;
  final bool isFocused;
  final bool isSelected;
  final bool isShowCheckbox;
  final double? height;

  @override
  State<WideMiTile> createState() => _WideMiTileState();
}

class _WideMiTileState extends State<WideMiTile> {
  late Widget trailing;

  @override
  void initState() {
    super.initState();
    _setTrailing();
  }

  @override
  void didUpdateWidget(covariant WideMiTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isShowCheckbox != widget.isShowCheckbox ||
        oldWidget.isSelected != widget.isSelected) {
      _setTrailing();
    }
  }

  void _setTrailing() {
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);
    Color borderColor = appearanceState.lerpBgColor(0.40);

    if (widget.isShowCheckbox) {
      trailing = Align(
        alignment: Alignment.centerRight,
        child: CheckboxInput(
          initial: widget.isSelected,
          borderColor: borderColor,
          onSelect: (_) {
            widget.onLongPress?.call();
            return false;
          },
        ),
      );
    } else {
      trailing = _getTimeText();
    }
  }

  Widget _getTimeText() {
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);
    Color subtitleColor = appearanceState.colors[ColorType.subtitle]!;
    return Text(
      widget.mi.durationInSeconds > 0 ? widget.mi.time : '',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.right,
      style: TextStyle(color: subtitleColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color focusColor =
        context.select<AppearanceState, Color>((s) => s.focusColor());
    Color textColor = context
        .select<AppearanceState, Color>((s) => s.colors[ColorType.text]!);
    Color subtitleColor = context
        .select<AppearanceState, Color>((s) => s.colors[ColorType.subtitle]!);

    const textStyle = TextStyle(
      fontSize: 15.0,
    );

    final grayTextStyle = TextStyle(
      color: subtitleColor,
    );

    return InkWell(
      onTap: widget.onTap,
      onLongPress: () {
        widget.onLongPress?.call();
      },
      onSecondaryTapUp: (details) {
        var pos = details.globalPosition;
        widget.onAction?.call(pos);
      },
      onHover: (isHover) {
        if (widget.isShowCheckbox) return;
        if (isHover) {
          trailing = Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 20 + 4,
              child: IconButton(
                icon: const Icon(PhosphorIconsRegular.dotsThreeVertical),
                onPressed: widget.onAction,
                color: textColor,
                iconSize: 20,
                style: IconButton.styleFrom(
                  minimumSize: const Size.fromRadius(0),
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
              ),
            ),
          );
        } else {
          trailing = _getTimeText();
        }
        setState(() {});
      },
      mouseCursor: SystemMouseCursors.click,
      child: Container(
        height: widget.height,
        padding: const EdgeInsets.only(left: 16.0, right: 18.0),
        color: widget.isFocused ? focusColor : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 0, right: 15.0),
              child: ThumbnailWithLoader(
                  picture: widget.mi.picture,
                  size: CONFIG.smThumbnail,
                  isLoading: widget.isLoading),
            ),
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.only(right: 24.0),
                child: Text(
                  widget.mi.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.only(right: 24.0),
                child: (widget.mi.tags.artist != null)
                    ? Text(
                        widget.mi.artistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: grayTextStyle,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            Expanded(
              flex: 5,
              child: (widget.mi.tags.album != null)
                  ? Text(
                      widget.mi.album,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: grayTextStyle,
                    )
                  : const SizedBox.shrink(),
            ),
            SizedBox(
              width: 48,
              child: trailing,
            ),
          ],
        ),
      ),
    );
  }
}
