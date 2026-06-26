import 'package:music_player/logic/KeyValue.dart';

typedef EventListeners = List<void Function(KeyValue)>;

class EventRegistrar {
  EventRegistrar();

  final EventListeners musicSourceContentsScrollEndListeners = [];
  final EventListeners musicItemChangeListeners = [];
  void register(
      EventListeners arr, void Function(KeyValue) fn) {
    arr.add(fn);
  }
}

final eventRegistrar = EventRegistrar();
