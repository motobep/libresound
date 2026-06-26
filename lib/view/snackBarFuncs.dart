import 'package:flutter/material.dart';
import 'package:music_player/logger.dart';
import 'package:music_player/view/App.dart' show navigatorKey;

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
  messenger.showSnackBar(getSnackBar(msg));
}

void showSnackBar(String msg, BuildContext context) {
  var messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(getSnackBar(msg));
}

void Function(String) getSnackBarMessangerFunc(BuildContext context) {
  var messenger = ScaffoldMessenger.of(context);
  return (String msg) {
    messenger.showSnackBar(getSnackBar(msg));
  };
}

SnackBar getSnackBar(String msg) {
  final snackBar = SnackBar(
    content: Text(msg, style: const TextStyle(color: Colors.white)),
    backgroundColor: const Color(0xff282832),
    duration: const Duration(milliseconds: 1500),
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.only(bottom: 50.0, left: 15, right: 15),
    padding: const EdgeInsets.symmetric(
      horizontal: 11.0, // Inner padding for SnackBar content.
      vertical: 11.0, // Inner padding for SnackBar content.
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
    dismissDirection: DismissDirection.horizontal,
  );
  return snackBar;
}
