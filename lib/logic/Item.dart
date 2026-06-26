import 'package:m4a_tags_handler/Tags.dart';
import 'package:music_player/logic/KeyValue.dart';

abstract class Item {
  late String id;
  String get title;
  String? get subtitle;
  String? get thumbnailUrl;
  KeyValue? props;

  abstract PictureTag? picture;
  abstract String sourceId;

  Map toJson();
}

class IndexedItem {
  IndexedItem(this.index, this.item);
  int index;
  Item item;

  @override
  bool operator ==(Object other) {
    return other is IndexedItem && index == other.index && item == other.item;
  }

  @override
  int get hashCode => Object.hash(index, item);

  Map toJson() {
    return {
      'index': index,
      'item': item,
    };
  }
}
