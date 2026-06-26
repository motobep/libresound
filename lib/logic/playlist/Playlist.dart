import 'package:music_player/logic/Item.dart';

class Playlist {
  Playlist(this.name, this.items);

  String name;
  List<Item> items;

  int get length {
    return items.length;
  }

  Item operator [](int index) => items[index];

  void addItemList(List<Item> other) {
    items.addAll(other);
  }

  void deleteItem(int index) {
    items.removeAt(index);
  }

  void moveItem(oldIndex, newIndex) {
    final el = items.removeAt(oldIndex);
    items.insert(newIndex, el);
  }
}
