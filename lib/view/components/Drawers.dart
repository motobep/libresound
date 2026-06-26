import 'package:flutter/material.dart';
import 'package:music_player/logger.dart';

import 'package:music_player/states/AppState.dart';

const double drawerRatio = 0.85;
const double endDrawerRatio = 1.0;

class Drawers extends StatefulWidget {
  const Drawers({
    super.key,
    required this.child,
    required this.drawer,
    required this.endDrawer,
    required this.onDrawerStatusChanged,
    required this.onEndDrawerStatusChanged,
    required this.appState,
    this.enableDrag = true,
  });

  final Widget child;
  final Widget drawer;
  final Widget endDrawer;
  final void Function(AnimationStatus) onDrawerStatusChanged;
  final void Function(AnimationStatus) onEndDrawerStatusChanged;
  final AppState appState;
  final bool enableDrag;

  @override
  State<Drawers> createState() => DrawersState();

  static DrawersState of(BuildContext context) {
    final DrawersState? result =
        context.findAncestorStateOfType<DrawersState>();
    if (result != null) {
      return result;
    }
    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary(
          '_Drawers.of() called with a context that does not contain a _Drawers.'),
      ErrorDescription(
        'No _Drawers ancestor could be found starting from the context that was passed to _Drawers.of(). '
        'This usually happens when the context provided is from the same StatefulWidget as that '
        'whose build function actually creates the _Drawers widget being sought.',
      ),
      ErrorHint(
          'There are several ways to avoid this problem. The simplest is to use a Builder to get a '
          'context that is "under" the _Drawers.'),
      ErrorHint(
        'A more efficient solution is to split your build function into several widgets. This '
        'introduces a new context from which you can obtain the _Drawers. In this solution, '
        'you would have an outer widget that creates the _Drawers populated by instances of '
        'your new inner widgets, and then in these inner widgets you would use _Drawers.of().\n'
        'A less elegant but more expedient solution is assign a GlobalKey to the _Drawers, '
        'then use the key.currentState property to obtain the _DrawersState rather than '
        'using the _Drawers.of() function.',
      ),
      context.describeElement('The context used was'),
    ]);
  }
}

class DrawersState extends State<Drawers> with TickerProviderStateMixin {
  static const animationDuration = Duration(milliseconds: 200);

  late final _leftCntlr = AnimationController(
    value: 0,
    duration: animationDuration,
    vsync: this,
  );
  late final Animation<Offset> _leftAnimation = Tween<Offset>(
    begin: const Offset(-1, 0),
    end: const Offset(0, 0),
  ).animate(CurvedAnimation(parent: _leftCntlr, curve: Curves.linear));

  late final _rightCntlr = AnimationController(
    value: 0,
    duration: animationDuration,
    vsync: this,
  );
  late final Animation<Offset> _rightAnimation = Tween<Offset>(
    begin: const Offset(1, 0),
    end: const Offset(0, 0),
  ).animate(CurvedAnimation(parent: _rightCntlr, curve: Curves.linear));

  @override
  void initState() {
    widget.appState.closeDrawer = closeDrawer;
    widget.appState.closeEndDrawer = closeEndDrawer;
    _leftCntlr.addStatusListener(_onDrawerStatus);
    _rightCntlr.addStatusListener(_onDrawerStatus);
    _leftCntlr.addStatusListener(widget.onDrawerStatusChanged);
    _rightCntlr.addStatusListener(widget.onEndDrawerStatusChanged);
    super.initState();
  }

  @override
  void dispose() {
    _leftCntlr.removeStatusListener(_onDrawerStatus);
    _rightCntlr.removeStatusListener(_onDrawerStatus);
    _leftCntlr.removeStatusListener(widget.onDrawerStatusChanged);
    _rightCntlr.removeStatusListener(widget.onEndDrawerStatusChanged);
    super.dispose();
  }

  void _onDrawerStatus(AnimationStatus status) {
    if (!status.isDismissed) {
      if (!isShowBackground) {
        isShowBackground = true;
        setState(() {});
      }
    } else {
      if (isShowBackground) {
        isShowBackground = false;
        setState(() {});
      }
    }
  }

  bool isShowBackground = false;

  Offset? _startPosition;

  late double _leftCntlrOffset;
  late double _rightCntlrOffset;

  void openDrawer() {
    _leftCntlr.forward();
  }

  void closeDrawer() {
    _leftCntlr.reverse();
  }

  void openEndDrawer() {
    _rightCntlr.forward();
  }

  void closeEndDrawer() {
    _rightCntlr.reverse();
  }

  void _handler(
    bool isOpening,
    double value, {
    required void Function() open,
    required void Function() close,
  }) {
    if (isOpening) {
      if (value >= 0.1) {
        open();
      } else {
        close();
      }
    } else {
      if (value <= 0.8) {
        close();
      } else {
        open();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return GestureDetector(
      onHorizontalDragStart: (DragStartDetails details) {
        if (!widget.enableDrag) return;
        // gLogger.blue('Drag start');
        _startPosition = details.globalPosition;
        _leftCntlrOffset = _leftCntlr.value;
        _rightCntlrOffset = _rightCntlr.value;
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        if (!widget.enableDrag) return;
        // gLogger.blue('Drag update. details=$details');

        final w = MediaQuery.of(context).size.width;
        var pos = details.globalPosition;
        // gLogger.blue('pos=$pos');

        final dx = (pos - _startPosition!).dx;
        // gLogger.blue('diff=$dx');
        if (!_leftCntlr.isDismissed) {
          _leftCntlr.value = _leftCntlrOffset + dx / (w * drawerRatio);
          return;
        }
        if (!_rightCntlr.isDismissed) {
          _rightCntlr.value =
              _rightCntlrOffset + dx / (w * endDrawerRatio) * -1;
          return;
        }

        if (dx > 0) {
          _leftCntlr.value = _leftCntlrOffset + dx / (w * drawerRatio);
        } else {
          _rightCntlr.value =
              _rightCntlrOffset + dx / (w * endDrawerRatio) * -1;
        }
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        if (!widget.enableDrag) return;
        var pos = details.globalPosition;
        var direction = (pos - _startPosition!).dx;
        // gLogger.blue('Drag end. direction=$direction');

        if (_rightCntlr.isDismissed) {
          // gLogger.blue('isLeftDrawer opening');
          _handler(direction > 0, _leftCntlr.value,
              open: openDrawer, close: closeDrawer);
        }

        if (_leftCntlr.isDismissed) {
          // gLogger.blue('isRightDrawer opening');
          _handler(direction < 0, _rightCntlr.value,
              open: openEndDrawer, close: closeEndDrawer);
        }
      },
      onHorizontalDragCancel: () {
        // gLogger.blue('Drag cancel');
      },
      child: Stack(
        children: [
          widget.child,
          if (isShowBackground)
            Container(
              width: width,
              height: height,
              color: Colors.black26,
            ),
          Positioned(
            left: 0,
            top: 0,
            child: SlideTransition(
              position: _leftAnimation,
              child: Container(
                width: drawerRatio * width,
                height: height,
                color: Colors.transparent,
                child: widget.drawer,
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: SlideTransition(
              position: _rightAnimation,
              child: Container(
                width: endDrawerRatio * width,
                height: height,
                color: Colors.black,
                child: widget.endDrawer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
