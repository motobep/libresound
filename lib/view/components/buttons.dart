// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';
import 'package:music_player/logger.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:file_picker/file_picker.dart';

import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logic/enums.dart';
import 'package:music_player/logic/playback/Playback.dart';
import 'package:music_player/logic/ActionButtonDescr.dart';

import 'package:music_player/states/AppState.dart' show AppState;
import 'package:music_player/states/PlaybackState.dart';
import 'package:music_player/states/AppearanceState.dart';

import 'package:music_player/view/snackBarFuncs.dart';
import 'package:music_player/view/components/iconsMap.dart';

void chooseMusicDir(BuildContext context) async {
  String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
  if (selectedDirectory == null) {
    gLogger.view('Canceled picker');
    return;
  }

  if (context.mounted) {
    await loadMusicDir(context, selectedDirectory);
  }
}

Future<void> loadMusicDir(BuildContext context, String dirPath) async {
  gLogger.view('selectedDirectory: $dirPath');

  var messengerFunc = getSnackBarMessangerFunc(context);
  AppState appState = Provider.of<AppState>(context, listen: false);
  Playback playback =
      Provider.of<PlaybackState>(context, listen: false).playback;

  bool ok = await appState.loadFromDirectoryAsync(dirPath);
  if (!ok) {
    var msg = 'Failed to load folder';
    gLogger.warn(msg);
    messengerFunc(msg);
  } else {
    playback.removeSourceItemsFromQueue(CONFIG.fsSourceId);
  }
}

class ListButton extends StatelessWidget {
  const ListButton(
    this.text, {
    super.key,
    required this.onTap,
    this.icon,
    this.isFocused = false,
    this.endWidget,
  });
  final String text;
  final PhosphorIconData? icon;
  final void Function()? onTap;
  final bool isFocused;
  final Widget? endWidget;

  @override
  Widget build(BuildContext context) {
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);
    Color focusColor =
        context.select<AppearanceState, Color>((s) => s.focusColor());

    List<InlineSpan> children = [
      const TextSpan(text: '   '),
      TextSpan(text: text),
    ];
    if (icon != null) {
      children.insert(
          0,
          WidgetSpan(
              child: Icon(icon), alignment: PlaceholderAlignment.middle));
    }

    return SizedBox(
      width: double.infinity,
      child: TextButton(
          onPressed: onTap,
          style: ButtonStyle(
              backgroundColor: isFocused
                  ? WidgetStateColor.resolveWith((states) => focusColor)
                  : null,
              alignment: Alignment.centerLeft,
              foregroundColor: WidgetStateColor.resolveWith(
                  (states) => ColorScheme.of(context).primary),
              overlayColor: WidgetStateColor.resolveWith(
                  (states) => appearanceState.hoverColor()),
              padding:
                  const WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.symmetric(
                horizontal: 25.0,
                vertical: 25.0,
              ))),
          child: Row(
            children: [
              Text.rich(
                TextSpan(
                  children: children,
                ),
              ),
              if (endWidget != null) endWidget!,
            ],
          )),
    );
  }
}

class TabButton extends StatelessWidget {
  const TabButton(this.text,
      {super.key, required this.onTap, this.isActive = false, this.iconName});

  final String text;
  final void Function()? onTap;
  final bool isActive;
  final IconName? iconName;

  @override
  Widget build(BuildContext context) {
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);
    Color _fgColor = ColorScheme.of(context).primary;
    Color _bgColor = isActive
        ? appearanceState.chosenTabColor()
        : ColorScheme.of(context).surface;
    final icon = iconsMap[iconName]?.call(PhosphorIconsStyle.thin);

    return TextButton(
      onPressed: onTap,
      style: ButtonStyle(
          overlayColor:
              WidgetStateColor.resolveWith((_) => appearanceState.hoverColor()),
          foregroundColor: WidgetStateColor.resolveWith((_) => _fgColor),
          backgroundColor: WidgetStateColor.resolveWith((states) => _bgColor),
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
          )),
          padding:
              const WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 10.0,
          ))),
      // child: Text(text),
      child: Column(
        children: [
          Icon(icon, color: _fgColor, weight: 10),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

class StandardButton extends StatelessWidget {
  const StandardButton(this.text,
      {super.key, required this.onTap, this.bgColor, this.fgColor});

  final String text;
  final void Function()? onTap;
  final Color? bgColor;
  final Color? fgColor;

  @override
  Widget build(BuildContext context) {
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);
    Color _bgColor = bgColor ?? appearanceState.buttonColor();
    Color _fgColor = fgColor ?? ColorScheme.of(context).primary;

    return TextButton(
      onPressed: onTap,
      style: ButtonStyle(
          overlayColor:
              WidgetStateColor.resolveWith((_) => appearanceState.hoverColor()),
          foregroundColor: WidgetStateColor.resolveWith((_) => _fgColor),
          backgroundColor: WidgetStateColor.resolveWith((states) => _bgColor),
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          )),
          padding:
              const WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.symmetric(
            horizontal: 14.0,
            vertical: 15.0,
          ))),
      // child: Text(text),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.normal)),
    );
  }
}

class OutlinedStandardButton extends StatelessWidget {
  const OutlinedStandardButton(this.text,
      {super.key,
      required this.onTap,
      this.fgColor,
      this.borderColor,
      this.borderWidth = 1});

  final String text;
  final void Function()? onTap;
  final Color? fgColor;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);
    Color _fgColor = fgColor ?? ColorScheme.of(context).primary;
    Color _borderColor = borderColor ?? ColorScheme.of(context).primary;

    return TextButton(
      onPressed: onTap,
      style: ButtonStyle(
          overlayColor:
              WidgetStateColor.resolveWith((_) => appearanceState.hoverColor()),
          foregroundColor: WidgetStateColor.resolveWith((_) => _fgColor),
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
            side: BorderSide(width: borderWidth, color: _borderColor),
            borderRadius: BorderRadius.circular(18.0),
          )),
          padding:
              const WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.symmetric(
            horizontal: 14.0,
            vertical: 15.0,
          ))),
      child: Text(text,
          style:
              const TextStyle(fontSize: 12.0, fontWeight: FontWeight.normal)),
    );
  }
}

class AllOutlinedStandardButton extends StatelessWidget {
  const AllOutlinedStandardButton(
    this.widget, {
    super.key,
    required this.onTap,
    this.fgColor,
    this.borderColor,
    this.borderWidth = 1,
    this.padding = const EdgeInsets.symmetric(
      horizontal: 14.0,
      vertical: 15.0,
    ),
  });

  final Widget widget;
  final void Function()? onTap;
  final Color? fgColor;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);
    Color _fgColor = fgColor ?? ColorScheme.of(context).primary;
    Color _borderColor = borderColor ?? ColorScheme.of(context).primary;

    return TextButton(
      onPressed: onTap,
      style: ButtonStyle(
          overlayColor:
              WidgetStateColor.resolveWith((_) => appearanceState.hoverColor()),
          foregroundColor: WidgetStateColor.resolveWith((_) => _fgColor),
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
            side: BorderSide(width: borderWidth, color: _borderColor),
            borderRadius: BorderRadius.circular(18.0),
          )),
          padding: WidgetStatePropertyAll<EdgeInsets>(padding)),
      child: widget,
    );
  }
}

class FilterButton extends StatefulWidget {
  const FilterButton(
    this.text, {
    super.key,
    required this.globalKey,
    required this.onTap,
    required this.setWidth,
    this.textColor,
  });

  final GlobalKey globalKey;
  final String text;
  final void Function()? onTap;
  final void Function(RenderBox) setWidth;
  final Color? textColor;

  @override
  State<FilterButton> createState() => _FilterButtonState();
}

class _FilterButtonState extends State<FilterButton> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      var box = getBoxSize(widget.globalKey.currentContext!);
      widget.setWidth(box);
    });
    super.initState();
  }

  RenderBox getBoxSize(BuildContext context) {
    return context.findRenderObject() as RenderBox;
  }

  @override
  Widget build(BuildContext context) {
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);
    Color _foregroundColor = widget.textColor == null
        ? ColorScheme.of(context).onSurface
        : widget.textColor!;

    return TextButton(
      onPressed: widget.onTap,
      style: TextButton.styleFrom(
        overlayColor: appearanceState.hoverColor(),
        foregroundColor: _foregroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.0),
        ),
      ),
      child: Center(
        child: Text(
          widget.text,
        ),
      ),
    );
  }
}

class LinkButton extends StatelessWidget {
  const LinkButton({
    required this.child,
    required this.onTap,
    super.key,
  });

  final Widget child;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: ButtonStyle(
        textStyle: WidgetStateProperty.resolveWith<TextStyle>(
            (states) => const TextStyle(decoration: TextDecoration.underline)),
        backgroundColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            return Colors.transparent;
          },
        ),
        foregroundColor: WidgetStateColor.resolveWith((states) => Colors.white),
      ),
      onPressed: onTap,
      child: child,
    );
  }
}

class CustomActionButton extends StatelessWidget {
  const CustomActionButton({
    super.key,
    required this.iconName,
    this.text = '',
    required this.onTap,
  });

  static CustomActionButton fromDescr(ActionBtnDescr btnDescr) {
    return CustomActionButton(
      iconName: iconsMap[btnDescr.icon]!(PhosphorIconsStyle.thin),
      text: btnDescr.text,
      onTap: btnDescr.onTap,
    );
  }

  final IconData iconName;
  final String text;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = ColorScheme.of(context).primary;

    return Positioned(
        bottom: 120.0,
        right: 42.0,
        child: TextButton(
          onPressed: onTap,
          style: ButtonStyle(
            backgroundColor: WidgetStateColor.resolveWith((states) => bgColor),
            minimumSize: WidgetStateProperty.all(Size.zero),
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40.0),
            )),
            padding:
                const WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.symmetric(
              horizontal: 0.0,
              vertical: .0,
            )),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 48.0,
                height: 48.0,
                child: Icon(
                  iconName,
                  color: ColorScheme.of(context).surface,
                  size: 26,
                ),
              ),
              if (text != '')
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Text(
                    text,
                    // 'text',
                    style: TextStyle(
                        fontSize: 16.0, color: ColorScheme.of(context).surface),
                  ),
                ),
            ],
          ),
        ));
  }
}

IconButton getBackBtn(BuildContext context) {
  return IconButton(
    icon: const Icon(PhosphorIconsThin.arrowLeft),
    onPressed: () => Navigator.of(context).pop(),
  );
}

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
    this.isFocused = false,
  });

  final String text;
  final IconData icon;
  final void Function() onTap;
  final bool isFocused;

  @override
  Widget build(BuildContext context) {
    Color focusColor =
        context.select<AppearanceState, Color>((s) => s.focusColor());
    return TextButton.icon(
      onPressed: () {
        onTap();
      },
      icon: Icon(icon),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.normal),
        ),
      ),
      style: ButtonStyle(
        backgroundColor: isFocused
            ? WidgetStateColor.resolveWith((states) => focusColor)
            : null,
      ),
    );
  }
}

class KeyMappingButton extends StatelessWidget {
  const KeyMappingButton(this.text,
      {super.key, required this.onTap, required this.onCrossTap});

  final String text;
  final void Function()? onTap;
  final void Function()? onCrossTap;

  @override
  Widget build(BuildContext context) {
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);
    Color fgColor = ColorScheme.of(context).onSurface;
    Color bgColor = appearanceState.lerpBgColor(0.04);

    return Container(
      height: 32.0,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.all(Radius.circular(5.0)),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: onTap,
            style: ButtonStyle(
                foregroundColor:
                    WidgetStateColor.resolveWith((states) => fgColor),
                backgroundColor:
                    WidgetStateColor.resolveWith((states) => bgColor),
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                )),
                padding:
                    const WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.only(
                  left: 12.0,
                  right: 12.0,
                ))),
            child: Text(text,
                style: const TextStyle(fontWeight: FontWeight.normal)),
          ),
          IconButton(
            iconSize: 14.0,
            onPressed: onCrossTap,
            icon: const Icon(Pit.x),
            style: ButtonStyle(
              foregroundColor:
                  WidgetStateColor.resolveWith((states) => fgColor),
              backgroundColor: WidgetStateColor.resolveWith(
                  (states) => appearanceState.lerpBgColor(0.07)),
              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              )),
            ),
          ),
        ],
      ),
    );
  }
}

class ScrollButton extends StatelessWidget {
  const ScrollButton({
    super.key,
    required this.icon,
    required this.iconSize,
    required this.iconButtonSize,
    required this.textColor,
    this.onTap,
  });

  final IconData icon;
  final double iconSize;
  final double iconButtonSize;
  final Color textColor;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    Color disabledColor =
        context.select<AppearanceState, Color>((s) => s.lerpBgColor(0.4));

    return IconButton(
      color: textColor,
      disabledColor: disabledColor,
      iconSize: iconSize,
      style: ButtonStyle(
        fixedSize: WidgetStateProperty.all(Size.fromRadius(iconButtonSize)),
        minimumSize: WidgetStateProperty.all(const Size.fromRadius(0)),
        side: WidgetStateProperty.all(
          BorderSide(
              width: 0.5, color: onTap != null ? textColor : disabledColor),
        ),
      ),
      icon: Icon(
        icon,
      ),
      onPressed: onTap,
    );
  }
}

class ToPageButton extends StatelessWidget {
  final String text;
  final void Function() onTap;
  final EdgeInsets? padding;

  const ToPageButton(this.text, {required this.onTap, super.key, this.padding});

  @override
  Widget build(BuildContext context) {
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);
    Color fgColor = ColorScheme.of(context).onSurface;

    return TextButton.icon(
      onPressed: onTap,
      style: ButtonStyle(
          overlayColor:
              WidgetStateColor.resolveWith((_) => appearanceState.hoverColor()),
          foregroundColor: WidgetStateColor.resolveWith((_) => fgColor),
          iconColor: WidgetStateColor.resolveWith((_) => fgColor),
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
            side:
                BorderSide(width: 0.8, color: ColorScheme.of(context).primary),
            borderRadius: BorderRadius.circular(4.0),
          )),
          padding: WidgetStatePropertyAll<EdgeInsets>(padding ??
              const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 16.0,
              ))),
      icon: const Icon(PhosphorIconsRegular.arrowRight),
      iconAlignment: IconAlignment.end,
      label: Text(text,
          style:
              const TextStyle(fontWeight: FontWeight.normal, fontSize: 14.0)),
    );
  }
}
