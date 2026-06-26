import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:music_player/states/AppState.dart' show AppState;

class PreloaderWrapper extends StatelessWidget {
  const PreloaderWrapper(
    this.contents, {
    super.key,
  });

  final Widget contents;

  @override
  Widget build(BuildContext context) {
    bool isShowPreloader =
        context.select<AppState, bool>((app) => app.isShowPreloader);
    return isShowPreloader
        ? const Center(
            child: SizedBox(
                width: 35,
                height: 35,
                child: CircularProgressIndicator(strokeWidth: 3)),
          )
        : contents;
  }
}
