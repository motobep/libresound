import 'dart:async' show Timer;

class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }
}
