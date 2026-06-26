import 'package:m4a_tags_handler/Tags.dart';
import 'package:music_player/logic/ActionButtonDescr.dart';
import 'package:music_player/logic/Item.dart';
import 'package:music_player/logic/KeyValue.dart';
import 'package:music_player/logic/SectionDescr.dart';
import 'package:music_player/logic/enums.dart';

abstract class PageDescr with Destructable {
  PageDescr({
    required this.type,
    this.title = '',
    this.attrs,
    this.props = const {},
  });
  final PageDescrType type;
  String title;
  KeyValue? attrs;
  KeyValue props;
}

class ControlsPageDescr implements PageDescr, Destructable {
  ControlsPageDescr({
    required this.controls,
    this.title = '',
    this.attrs,
    this.props = const {},
    this.destruct,
  });
  List<dynamic> controls;

  @override
  PageDescrType type = PageDescrType.controls;
  @override
  String title;
  @override
  KeyValue? attrs;
  @override
  KeyValue props;
  @override
  void Function()? destruct;

  Map toJson() {
    return {
      'type': type.name,
      'title': title,
      'controls': controls,
      'attrs': attrs,
      'props': props,
    };
  }
}

class MusicPageDescr implements PageDescr, Destructable {
  MusicPageDescr({
    this.title = '',
    required this.sectionlist,
    this.header,
    this.actionBtn,
    this.attrs,
    this.props = const {},
    this.scrollPos = 0,
    this.isModifyPage = false,
    this.destruct,
  });

  @override
  PageDescrType type = PageDescrType.music;

  @override
  String title;
  List<SectionDescr> sectionlist;
  PageHeaderDescr? header;
  ActionBtnDescr? actionBtn;
  @override
  KeyValue? attrs;
  @override
  KeyValue props;
  @override
  void Function()? destruct;

  bool isModifyPage;
  double scrollPos;

  // Internal purpose
  int updateIdx = 0;

  @override
  String toString() {
    return '''{ title: $title, type: $type, sectionlist.length: ${sectionlist.length},
    attrs: ${attrs} }''';
  }

  Map toJson() {
    return {
      'type': type.name,
      'title': title,
      'sectionlist': sectionlist,
      'wrapper': header,
      'actionBtnDescr': actionBtn,
      'scrollPos': scrollPos,
      'attrs': attrs,
      'props': props,
    };
  }

  // Helpers

  /// Helper
  SectionDescr? findSection(int id) {
    int idx = sectionlist.indexWhere((s) => s.id == id);
    if (idx == -1) {
      return null;
    }
    return sectionlist[idx];
  }

  /// Helper
  void setFirstItemlist(List<Item> itemlist) {
    assert(sectionlist.isNotEmpty, 'Empty Sectionlist');
    sectionlist[0].itemlist = itemlist;
  }

  /// Helper
  List<Item> firstItemlistOrEmpty() {
    if (sectionlist.isEmpty) return [];
    return sectionlist[0].itemlist;
  }
}

class PageHeaderDescr {
  PageHeaderDescr({
    required this.title,
    this.subtitle,
    this.picture,
    this.actionBtn,
  });

  String title;
  String? subtitle;
  PictureTag? picture;
  ActionBtnDescr? actionBtn;

  Map toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'hasPicture': picture != null,
      'actionBtnDescr': actionBtn,
    };
  }

  PageHeaderDescr clone() {
    return PageHeaderDescr(
      title: title,
      subtitle: subtitle,
      picture: picture,
      actionBtn: actionBtn,
    );
  }
}

class WebViewPageDescr implements PageDescr, Destructable {
  WebViewPageDescr({
    this.title = '',
    this.attrs,
    this.props = const {},
    this.destruct,
  });

  @override
  PageDescrType type = PageDescrType.webView;
  @override
  String title;
  @override
  KeyValue? attrs;
  @override
  KeyValue props;

  @override
  void Function()? destruct;

  Map toJson() {
    return {
      'type': type.name,
      'title': title,
      'attrs': attrs,
      'props': props,
    };
  }
}

mixin Destructable {
  void Function()? destruct;
}
