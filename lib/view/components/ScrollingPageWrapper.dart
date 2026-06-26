import 'package:flutter/material.dart';
import 'package:music_player/config.dart' as CONFIG;

import 'package:music_player/logger.dart';

class ScrollingPageWrapper extends StatelessWidget {
  const ScrollingPageWrapper(
    this.ws, {
    super.key,
  });

  final List<Widget> ws;

  @override
  Widget build(BuildContext context) {
    gLogger.build(runtimeType);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CONFIG.pagePaddingHor,
        vertical: CONFIG.pagePaddingVert,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: ws,
        ),
      ),
    );
  }
}
