import 'package:flutter/material.dart';
import 'package:music_player/logger.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import 'package:music_player/config.dart' as CONFIG;

import 'package:music_player/states/AppearanceState.dart';
import 'package:music_player/states/FocusState.dart';

import 'package:music_player/logic/dialogFuncs.dart';

import 'package:music_player/view/components/iconsMap.dart';
import 'package:music_player/view/components/buttons.dart';

void showActionsDialog(BuildContext context) {
  showDialog(
      context: context,
      builder: (context) {
        return const _ActionsDialog();
      });
}

void showActionsBottomSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    sheetAnimationStyle: AnimationStyle(
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 80),
    ),
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return const ActionsBottomSheet();
    },
  );
}

class ActionsBottomSheet extends StatelessWidget {
  const ActionsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    int focusIndex = context
        .select<FocusManagerState, int>((s) => s.actionsState.listNav.index);
    bool isFocusEnabled =
        context.select<FocusManagerState, bool>((s) => s.isEnabled);

    var focusState = Provider.of<FocusManagerState>(context, listen: false);
    var actions = focusState.actionsState.actions;

    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);
    final dialogFuncs = getDialogFuncs();
    final accentColor = ColorScheme.of(context).tertiary;
    return TextButtonTheme(
        data: TextButtonThemeData(
          style: TextButton.styleFrom(
            iconColor: accentColor,
            foregroundColor: accentColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            enabledMouseCursor: SystemMouseCursors.click,
          ),
        ),
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            gLogger.log('didPop: $didPop');
            if (didPop) {
              return;
            }
            focusState.unfocusActions();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            decoration: BoxDecoration(
              color: appearanceState.queueBtnColor(),
              borderRadius: const BorderRadius.all(Radius.elliptical(15, 15)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var (idx, el) in actions.indexed)
                  ActionButton(
                    text: el.text,
                    icon: iconsMap[el.icon]!(PhosphorIconsStyle.thin),
                    isFocused: isFocusEnabled && idx == focusIndex,
                    onTap: () async {
                      await el.callback(dialogFuncs);
                    },
                  )
              ],
            ),
          ),
        ));
  }
}

class _ActionsDialog extends StatelessWidget {
  const _ActionsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    int focusIndex = context
        .select<FocusManagerState, int>((s) => s.actionsState.listNav.index);
    bool isFocusEnabled =
        context.select<FocusManagerState, bool>((s) => s.isEnabled);

    var focusState = Provider.of<FocusManagerState>(context, listen: false);
    var actions = focusState.actionsState.actions;

    final dialogFuncs = getDialogFuncs();
    final accentColor = Theme.of(context).colorScheme.tertiary;
    return TextButtonTheme(
        data: TextButtonThemeData(
          style: TextButton.styleFrom(
            iconColor: accentColor,
            foregroundColor: accentColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            enabledMouseCursor: SystemMouseCursors.click,
          ),
        ),
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            gLogger.log('didPop: $didPop');
            if (didPop) {
              return;
            }
            focusState.unfocusActions();
          },
          child: AlertDialog(
            contentPadding: const EdgeInsets.all(20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var (idx, el) in actions.indexed)
                  ActionButton(
                    text: el.text,
                    icon: iconsMap[el.icon]!(PhosphorIconsStyle.thin),
                    isFocused: isFocusEnabled && idx == focusIndex,
                    onTap: () async {
                      await el.callback(dialogFuncs);
                    },
                  )
              ],
            ),
          ),
        ));
  }
}

void showActionsContextMenu(BuildContext context, Offset pos) {
  var focusState = Provider.of<FocusManagerState>(context, listen: false);
  var actions = Provider.of<FocusManagerState>(context, listen: false)
      .actionsState
      .actions;
  final appearanceState = Provider.of<AppearanceState>(context, listen: false);
  final dialogFuncs = getDialogFuncs();

  double vh = MediaQuery.of(context).size.height;
  final optionsHeight = actions.length * CONFIG.contextMenuOptionHeight;
  final top =
      pos.dy + optionsHeight + 8.0 > vh ? pos.dy - optionsHeight : pos.dy;

  showGeneralDialog(
    context: context,
    pageBuilder: (_, __, ___) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          gLogger.view('didPop: $didPop');
          if (didPop) {
            return;
          }
          focusState.unfocusActions();
        },
        child: Stack(
          children: [
            Positioned(
              left: pos.dx,
              top: top,
              child: Container(
                decoration: BoxDecoration(
                  color: ColorScheme.of(context).surface,
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x20000000),
                        blurRadius: 12.0,
                        blurStyle: BlurStyle.outer)
                  ],
                  border: Border.all(
                      color: appearanceState.lerpBgColor(0.07), width: 1.0),
                  borderRadius: BorderRadius.circular(5.0),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
                child: TextButtonTheme(
                  data: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      iconColor: ColorScheme.of(context).tertiary,
                      foregroundColor: ColorScheme.of(context).tertiary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      enabledMouseCursor: SystemMouseCursors.click,
                    ),
                  ),
                  child: IntrinsicWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var el in actions)
                          ActionButton(
                            text: el.text,
                            icon: iconsMap[el.icon]!(PhosphorIconsStyle.thin),
                            onTap: () async {
                              await el.callback(dialogFuncs);
                            },
                          )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
    // barrierColor: Colors.black12,
    barrierColor: Colors.transparent,
    barrierDismissible: true,
    barrierLabel: 'barrier_label',
  );
}
