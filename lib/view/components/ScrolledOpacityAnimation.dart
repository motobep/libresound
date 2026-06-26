import 'package:flutter/material.dart';
import 'package:music_player/logger.dart';

class ScrolledOpacityAnimation extends StatefulWidget {
  const ScrolledOpacityAnimation({
    required this.sheetController,
    required this.child,
    required this.fadeInPercent,
    required this.fadeOutPercent,
    super.key,
  });

  final DraggableScrollableController sheetController;
  final Widget child;
  final double fadeInPercent;
  final double fadeOutPercent;

  @override
  State<ScrolledOpacityAnimation> createState() =>
      _ScrolledOpacityAnimationState();
}

class _ScrolledOpacityAnimationState extends State<ScrolledOpacityAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    value: 1,
    vsync: this,
    duration: const Duration(seconds: 0),
  );
  late final CurvedAnimation _animation =
      CurvedAnimation(parent: _controller, curve: Curves.easeIn);

  bool isShowWidget = true;

  @override
  void initState() {
    widget.sheetController.addListener(listener);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fadeInPercent != oldWidget.fadeInPercent) {
      listener();
    }
  }

  @override
  void dispose() {
    widget.sheetController.removeListener(listener);
    super.dispose();
  }

  void listener() {
    if (!widget.sheetController.isAttached) return;

    var size = widget.sheetController.size;
    // gLogger.blue('size=$size');

    final fadeInPercent = widget.fadeInPercent;
    final fadeOutPercent = widget.fadeOutPercent;
    final aLen = fadeOutPercent - fadeInPercent;
    const bLen = 1 - 0.0;
    final k = aLen / bLen;

    final norm = (size - fadeInPercent) / k;

    if (size >= fadeOutPercent) {
      if (isShowWidget == true)
        setState(() {
          isShowWidget = false;
        });
    } else {
      _controller.animateTo(1 - norm);
      if (isShowWidget == false)
        setState(() {
          isShowWidget = true;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: isShowWidget ? widget.child : Container(),
    );
  }
}
