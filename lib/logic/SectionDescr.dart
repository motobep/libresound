import 'package:music_player/logic/ActionButtonDescr.dart';
import 'package:music_player/logic/Item.dart';
import 'package:music_player/logic/KeyValue.dart';
import 'package:music_player/logic/GroupItem.dart';
import 'package:music_player/logic/enums.dart';

class SectionDescr {
  SectionDescr({
    this.header,
    this.itemlist = const [],
    this.isBigTile = false,
    required this.rowsCount,
    this.index = -1,
    this.props = const {},
  })  : id = _nextId(),
        assert(rowsCount > 0 || rowsCount == -1, 'Bad rowsCount=${rowsCount}');

  SectionDescr.indexed({
    this.header,
    this.itemlist = const [],
    this.isBigTile = false,
    required this.rowsCount,
    required this.index,
    this.props = const {},
  })  : id = _nextId(),
        assert(rowsCount > 0 || rowsCount == -1, 'Bad rowsCount=${rowsCount}');

  final SectionHeaderDescr? header;
  List<Item> itemlist;
  bool isBigTile;
  int rowsCount;

  final KeyValue props;

  final int id;
  int index;

  Map toJson() {
    return {
      'header': header,
      'listType': itemlist.isNotEmpty && itemlist[0] is GroupItem
          ? ListType.grouplist.name
          : ListType.tracklist.name,
      'itemlist': itemlist,
      'isBigTile': isBigTile,
      'rowsCount': rowsCount,
      'index': index,
      'props': props,
    };
  }

  static int _s_id = 0;
  static int _nextId() {
    return ++_s_id;
  }
}

class SectionHeaderDescr {
  SectionHeaderDescr({
    this.title,
    this.subtitle,
    this.actionBtn,
  });

  final String? title;
  final String? subtitle;
  ActionBtnDescr? actionBtn;

  Map toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'actionBtnDescr': actionBtn,
    };
  }
}
