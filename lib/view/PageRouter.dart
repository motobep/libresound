// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';

import 'package:music_player/view/App.dart' show navigatorKey;

class PageRouter {
  static void back<T extends Object?>(BuildContext context, [T? result]) {
    Navigator.of(context).pop(result);
  }

  static void backNoCtx<T extends Object?>([T? result]) {
    navigatorKey.currentState!.pop(result);
  }

  static void toPage<T>(Widget widget) {
    navigatorKey.currentState!.push<T>(
      PageRouteBuilder(
        pageBuilder: (BuildContext context, Animation<double> _animation1,
            Animation<double> _animation2) {
          return widget;
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
}
