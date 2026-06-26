import 'package:flutter/material.dart' show ChangeNotifier;

import 'package:music_player/logger.dart';
import 'package:music_player/logic/enums.dart';

class DownloadObj {
  /// Title to display in downloads list
  String title;

  /// Whether it can be removed in GUI
  bool isRemovable;

  /// Function to call when this item is being freed
  void Function()? abort;

  DownloadObj({
    required this.title,
    required this.isRemovable,
    this.abort,
  });
}

class DownloadsState extends ChangeNotifier {
  DownloadsState() : super();

  Map<String, DownloadObj> downloads = {};

  Future<T?> download<T>({
    required String id,
    required String text,
    required bool isRemovable,
    required Future<T> Function() fetch,
    required void Function() abort,
  }) async {
    T? ret;
    _add_n(
        id, DownloadObj(title: text, isRemovable: isRemovable, abort: abort));
    try {
      ret = await fetch();
      if (ret == null) {
        logger.warn('bad ret: $ret');
      }
    } catch (e) {
      logger.error('Aborted or errored: $e');
    }
    _remove(id);
    notifyListeners();
    return ret;
  }

  /// Aborts download and removes from downloadsState by type
  void removeAndAbortByType_n(DownloadType type) {
    logger.trace('removeAndAbortByType_n: $downloads');
    String typeStr = type.name;
    List<String> toRemove = [];
    for (var el in downloads.entries) {
      if (el.key.startsWith('[$typeStr]')) {
        toRemove.add(el.key);
      }
    }
    for (var el in toRemove) {
      _removeAndSafeAbort(el);
    }
    notifyListeners();
  }

  void removeAndSafeAbort_n(String key) {
    _removeAndSafeAbort(key);
    notifyListeners();
  }

  bool has(String key) {
    return downloads.containsKey(key);
  }

  bool hasPlayId(String sourceId, String id) {
    final key = DownloadsState.fmt(DownloadType.play, sourceId, id);
    return downloads.containsKey(key);
  }

  void _add_n(String key, DownloadObj downloadObj) {
    assert(downloads.containsKey(key) == false);
    logger.trace('Adding: "$key"');
    downloads[key] = downloadObj;
    notifyListeners();
  }

  /// Gets element, that must be in the map
  DownloadObj _get(String key) {
    assert(has(key) == true, 'Element must be in DownloadsState');
    return downloads[key]!;
  }

  /// Removes from downloadsState and aborts downloadObj
  void _removeAndSafeAbort(String key) {
    var obj = _get(key);
    _remove(key);
    obj.abort?.call();
  }

  /// Removes object from downloadsState
  void _remove(String key) {
    assert(has(key) == true, 'Element must be in DownloadsState');
    logger.trace('Calling downloads._remove(): "$key"');
    downloads.remove(key);
    assert(has(key) == false, 'Should be removed here');
  }

  static String fmt(DownloadType type, String sourceId, String id) {
    return '[${type.name}](${sourceId}):${id}';
  }
}

final Logger logger = Logger(prefix: 'DownloadsState: ');
