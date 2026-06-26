import 'package:flutter/material.dart' show ChangeNotifier;

import 'package:music_player/consts.dart' as CONSTS;
import 'package:music_player/logger.dart';
import 'package:music_player/logic/Item.dart';
import 'package:music_player/logic/MusicItem.dart';
import 'package:music_player/logic/tapHandlers.dart' show showMultiActions;

class SelectionState extends ChangeNotifier {
  SelectionState() : super() {
    final s = SelectionSet(this);
    mapOfSets['${CONSTS.queueSectionIdx}'] = s;
  }

  // TODO: Add global queue set
  Map<String, SelectionSet> mapOfSets = {};

  int length = 0;
  bool isOnlySource = true;

  bool get isEmpty => length == 0;
  bool get isNotEmpty => length != 0;

  void updateSelection([IndexedItem? indexedItem]) {
    logger.debug('update');

    int acc = 0;
    Set<String> sourcesIds = {};
    for (var v in mapOfSets.values) {
      // logger.log('v.length="${v.length}"');
      acc += v.length;

      sourcesIds.addAll(v.getSourcesNames());
    }
    length = acc;
    // logger.log('length="${length}"');

    isOnlySource = sourcesIds.length == 1;

    notifyListeners();
  }

  void act() {
    logger.debug('act');
    showMultiActions(getSortedMap(), unselectAll);
  }

  Map<String, List<IndexedItem>> getSortedMap() {
    Map<String, List<IndexedItem>> m = {};
    for (var e in mapOfSets.entries) {
      m[e.key] = e.value.selectedItems.toList()
        ..sort((a, b) => a.index.compareTo(b.index));
    }
    return m;
  }

  void unselectAll() {
    for (var s in mapOfSets.values) {
      s.unselectAll();
    }
    updateSelection();
  }

  SelectionSet makeSet(
      int sectionIdx, void Function(void Function()) setState) {
    final s = SelectionSet(this, () {
      setState(() {});
      logger.debug('update()');
    });
    mapOfSets['$sectionIdx'] = s;
    return s;
  }

  void removeSet(SelectionSet s) {
    mapOfSets.removeWhere((_, value) => value == s);
    updateSelection();
  }

  static List<MusicItem> flattenMap(
      Map<String, List<IndexedItem>> indexedItemMap) {
    List<MusicItem> items = [];
    for (var e in indexedItemMap.entries) {
      for (var el in e.value) {
        items.add(el.item as MusicItem);
      }
    }
    return items;
  }

  // void update() => notifyListeners();
}

class SelectionSet {
  SelectionSet(this.state, [this.setState]) : super();
  SelectionState state;
  void Function()? setState;

  Set<IndexedItem> selectedItems = {};

  bool contains(IndexedItem el) => selectedItems.contains(el);
  bool get isNotEmpty => selectedItems.isNotEmpty;
  int get length => selectedItems.length;

  Set<String> getSourcesNames() {
    Set<String> set = {};
    for (var idxItem in selectedItems) {
      var item = idxItem.item;
      set.add(item.sourceId);
    }
    return set;
  }

  void selectItem(IndexedItem indexedItem) {
    if (selectedItems.contains(indexedItem)) {
      logger.debug('true');
      selectedItems.remove(indexedItem);
    } else {
      logger.debug('false');
      selectedItems.add(indexedItem);
    }
    logger.debug('notify');
    setState?.call();
    state.updateSelection(indexedItem);
  }

  void unselectAll() {
    selectedItems = {};
  }

  void removeSelf() {
    state.removeSet(this);
  }
}

final Logger logger = Logger(prefix: 'SelectionState: ');
