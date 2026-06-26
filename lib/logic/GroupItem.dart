import 'package:m4a_tags_handler/Tags.dart';
import 'package:music_player/logic/Item.dart';
import 'package:music_player/logic/KeyValue.dart';

class GroupItem implements Item {
  GroupItem(
    this.id,
    this.title, {
    this.subtitle,
    this.thumbnailUrl,
    required this.sourceId,
    this.picture,
    this.props,
  });

  @override
  String id;

  @override
  String title;

  @override
  String? subtitle;

  @override
  String? thumbnailUrl;

  @override
  KeyValue? props;

  @override
  PictureTag? picture;

  @override
  String sourceId;

  @override
  String toString() {
    return 'GroupItem: ${toJson()}';
  }

  static GroupItem fromJson(Map el, {required String sourceId}) {
    String id = el['id'];
    String title = el['title'];

    return GroupItem(
      id,
      title,
      subtitle: el['subtitle'],
      thumbnailUrl: el['thumbnailUrl'],
      props: el['props'],
      sourceId: sourceId,
    );
  }

  @override
  Map toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'thumbnailUrl': thumbnailUrl,
      'hasPicture': picture != null,
      'props': props,
    };
  }
}
