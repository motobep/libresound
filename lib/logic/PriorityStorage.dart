import 'package:music_player/logic/Config.dart';

class PriorityStorage {
  final Config config;
  String name;
  int maxLength;
  List<String> value = [];

  PriorityStorage(this.name, this.maxLength, this.config);

  void load() {
    value = config.getProperty(name)?.cast<String>() ?? [];
  }

  void addAndSave(String v) {
    add(v);
    save(value);
  }

  void add(String v) {
    value.removeWhere((el) => el == v);
    value.insert(0, v);
    if (value.length > maxLength) {
      value = value.take(maxLength).toList();
    }
  }

  void save(List<String> playlists) {
    config.saveProperty(name, value);
  }
}
