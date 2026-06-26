import 'package:music_player/logic/DialogDescr.dart' show ItemAction;
import 'package:music_player/logic/GroupItem.dart';
import 'package:music_player/logic/Item.dart' show IndexedItem;
import 'package:music_player/logic/JsonStorage.dart';
import 'package:music_player/logic/MusicItem.dart';
import 'package:music_player/logic/PageDescr.dart';
import 'package:music_player/logic/enums.dart';

abstract class Source {
  late String sourceId;

  abstract bool isShowPreloader;

  PageDescr get currPage;
  NavType get navType;

  int get currTabIdx;
  List<(String, IconName?)> getTabs();
  Future<void> chooseTabAsync(int index);

  int get currSearchTabIdx;
  List<String> getSearchTabs();
  Future<void> chooseSearchTabAsync(int index);

  String errorMsg = '';

  Future<void> chooseSourceAsync() async {}
  Future<void> reloadAsync() async {}

  Future<void> setPlaybackSourceAsync(MusicItem musicItem);
  Future<void> chooseGroupAsync(GroupItem groupItem);

  bool back();
  bool canBack();

  /// Throws
  Future<void> searchAsync(String text);

  Future<List<String>?> getSuggestionsAsync(String text);
  late Duration debounceDelay;

  List<String> rightControls = [];
  bool get isShowSearch;
  JsonStorage get propertyStorage;

  Future<List<ItemAction>> buildActionsAsync(
      IndexedItem indexedItem, int sectionIndex);
  Future<List<ItemAction>> buildMultiActionsAsync(
      Map<String, List<IndexedItem>> indexedItemsMap, void Function() cancel);

  /// Triggers event with args in map
  Future<void> triggerEventAsync(String event, Map map);

  Future<bool> seekAsync(int milliseconds);
}
