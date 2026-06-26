import 'dart:async';

import 'package:music_player/logger.dart';

const int TICK_DURATION_MS = 10;

class ProgressCounter {
  ProgressCounter();

  final Set<void Function(int ms)> _updateListeners = {};
  final Set<void Function(int ms)> _endListeners = {};

  void addListener(void Function(int ms) f, {required String type}) {
    if (type == 'update') {
      _updateListeners.add(f);
    } else if (type == 'end') {
      _endListeners.add(f);
    }
  }

  void removeListener(void Function(int ms) f, {required String type}) {
    if (type == 'update') {
      _updateListeners.remove(f);
    } else if (type == 'end') {
      _endListeners.remove(f);
    }
  }

  Timer? _timer;

  int _startTimeMs = 0;

  int _currMs = 0;
  int _endMs = 0;

  int get currMillisecs => _currMs;

  set currMillisecs(int milliseconds) {
    assert(0 <= milliseconds && milliseconds <= _endMs,
        'milliSeconds=$milliseconds out of bounds [0; $_endMs]');
    // gLogger.log('ProgressCounter: $milliseconds');
    gLogger.trace('setCurrTime=$milliseconds');
    _currMs = milliseconds;
    for (final f in _updateListeners) f(_currMs);
  }

  bool get isActive {
    if (_timer != null) return _timer!.isActive;
    return false;
  }

  void resume() {
    assert(!isActive, 'ProgressCounter must be not active to resume');
    gLogger.trace('resume ($_currMs, $_endMs)');
    tickTillMs(_endMs, _currMs);
  }

  void tickFrom(int startMs) {
    gLogger.trace('tickFrom ($startMs, $_endMs)');
    tickTillMs(_endMs, startMs);
  }

  void tickTillMs(int endMs, [int startMs = 0]) {
    gLogger.trace('start=$startMs;endMilliSecs=$endMs');
    if (endMs <= 0) {
      return;
    }
    _timer?.cancel();

    _currMs = startMs;
    _endMs = endMs;

    _startTimeMs = DateTime.now().millisecondsSinceEpoch - startMs;

    _timer =
        Timer.periodic(const Duration(milliseconds: TICK_DURATION_MS), (timer) {
      int ms = DateTime.now().millisecondsSinceEpoch - _startTimeMs;
      if (ms >= _endMs) {
        _currMs = _endMs;
        gLogger.trace('end');
        timer.cancel();
        for (final f in _endListeners) f(_currMs);
      } else {
        // gLogger.trace('set in periodic: $ms');
        _currMs = ms;
      }
      for (final f in _updateListeners) f(_currMs);
    });
  }

  void cancel() {
    gLogger.trace('cancel');
    _timer?.cancel();
  }

  // Pure funcs
  /// [0, 1]
  double getProgressRatio() => toRatio(_currMs);

  // Converters
  int toMilliSecs(double ratio) => (ratio * _endMs).toInt();
  double toRatio(int milliSecs) {
    if (_endMs == 0) return 0;
    return milliSecs / _endMs;
  }
  // Pure funcs end

  static final Logger logger = Logger(prefix: 'ProgressCounter: ');
}
