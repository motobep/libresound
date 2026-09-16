import 'package:flutter/material.dart';
import 'package:music_player/logger.dart';

class ResizeableSeparator extends StatelessWidget {
  const ResizeableSeparator({
    super.key,
    required this.width,
    required this.height,
    required this.separatorColor,
    required this.onHorizontalDragUpdate,
    required this.onHorizontalDragEnd,
  });

  final double width;
  final double height;
  final Color separatorColor;
  final void Function(DragUpdateDetails) onHorizontalDragUpdate;
  final void Function(DragEndDetails) onHorizontalDragEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: (details) {
        onHorizontalDragUpdate(details);
      },
      onHorizontalDragEnd: (details) {
        gLogger.view('endDetails: $details');
        onHorizontalDragEnd(details);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        child: SizedBox(
          width: width,
          height: height,
          child: Center(
            child: Container(
                width: 1,
                height: height,
                decoration: BoxDecoration(
                  color: separatorColor,
                )),
          ),
        ),
      ),
    );
  }
}
