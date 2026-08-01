import 'package:flutter/material.dart';
import 'package:music_player/logger.dart';
import 'package:music_player/states/AppState.dart' show AppState;
import 'package:music_player/view/App.dart' show navigatorKey;
import 'package:provider/provider.dart' show Provider;

/// WARNING: bad behavior if used wrong across async gaps
Future<void> _showSnackBarAsBottomSheet(
    BuildContext context, String message) async {
  return await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color.fromRGBO(0, 0, 0, 0),
    builder: (BuildContext context) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        try {
          // ignore: use_build_context_synchronously
          Navigator.pop(context);
        } catch (e) {
          gLogger.error('Custom showSnackBar error: $e');
        }
      });
      return Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Container(
            color: Colors.grey.shade800,
            padding: const EdgeInsets.all(10),
            child: Text(
              message,
            )),
      );
    },
  );
}

Future<void> _showSnackBarAsBottomSheetNoContext(String message) async {
  final ctx = navigatorKey.currentState!.context;
  return await showModalBottomSheet<void>(
    context: ctx,
    backgroundColor: Colors.transparent,
    barrierColor: const Color.fromRGBO(0, 0, 0, 0),
    builder: (BuildContext context) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        try {
          if (ctx.mounted) {
            gLogger.log('showSnackBar mounted pop');
            Navigator.pop(ctx);
          } else {
            gLogger.warn('showSnackBar mounted pop');
          }
        } catch (e) {
          gLogger.error('Custom showSnackBar error: $e');
        }
      });
      return Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Container(
            color: Colors.grey.shade800,
            padding: const EdgeInsets.all(10),
            child: Text(
              message,
            )),
      );
    },
  );
}

void showSnackBarNoContext(String msg) {
  var context = navigatorKey.currentContext!;
  var messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(getSnackBar(context, msg));
}

void showSnackBar(String msg, BuildContext context) {
  var messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(getSnackBar(context, msg));
}

void Function(String) getSnackBarMessangerFunc(BuildContext context) {
  var messenger = ScaffoldMessenger.of(context);
  return (String msg) {
    messenger.showSnackBar(getSnackBar(context, msg));
  };
}

SnackBar getSnackBar(BuildContext context, String msg) {
  final cs = ColorScheme.of(context);

  AppState appState = Provider.of<AppState>(context, listen: false);

  var alignment = Alignment.center;
  var margin = const EdgeInsets.only(bottom: 50.0, left: 15, right: 15);
  if (appState.isWide) {
    margin = const EdgeInsets.only(bottom: 90.0, left: 25, right: 25);
  }

  final snackBar = SnackBar(
    content: Align(
      alignment: alignment,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border.all(color: cs.primary, width: 1.0),
          borderRadius: BorderRadius.circular(2.0),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 11.0,
          vertical: 11.0,
        ),
        child: Text(msg, style: TextStyle(color: cs.onSurface)),
      ),
    ),
    elevation: 0,
    backgroundColor: Colors.transparent,
    padding: const EdgeInsets.only(),
    duration: const Duration(milliseconds: 1500),
    behavior: SnackBarBehavior.floating,
    margin: margin,
    dismissDirection: DismissDirection.horizontal,
  );
  return snackBar;
}
