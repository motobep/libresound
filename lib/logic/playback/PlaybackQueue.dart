import 'package:music_player/logger.dart';
import 'package:music_player/logic/MusicItem.dart';

import 'package:music_player/logic/enums.dart' show RepeatState;

// TODO: make as proper state
class PlaybackQueue {
  // Attributes
  List<MusicItem> queue = [];
  int get currentIdx => _currentIdx;
  int _currentIdx = -1;

  // State
  RepeatState repeatState = RepeatState.norepeat;

  int updateIdx = 0;

  void Function(int index)? onCurrIdxChange;
  // End Attributes

  // No_side_effects_funcs
  MusicItem getMusicItem(int index) {
    assert(_checkIndexInBounds(index), 'Track index is out of bounds');
    return queue[index];
  }

  MusicItem getCurrentMusicItem() {
    return getMusicItem(_currentIdx);
  }

  MusicItem? findMusicItem(String id) {
    int idx = queue.indexWhere((mi) => mi.id == id);
    if (idx == -1) {
      return null;
    }
    return queue[idx];
  }

  // Getters
  int get length {
    return queue.length;
  }

  bool get isEmpty {
    return queue.isEmpty;
  }

  bool get isNotEmpty {
    return queue.isNotEmpty;
  }

  bool get hasValidIndex {
    return _checkIndexInBounds(_currentIdx);
  }

  bool get isAtHead {
    return _currentIdx == 0;
  }

  bool get isAtTail {
    return _currentIdx == (queue.length - 1);
  }

  // Predicates
  bool canPrev() {
    return _checkIndexInBounds(_currentIdx - 1) ||
        repeatState == RepeatState.repeatAll;
  }

  bool canNext() {
    return _checkIndexInBounds(_currentIdx + 1) ||
        repeatState == RepeatState.repeatAll;
  }

  bool _checkIndexInBounds(int index) {
    return (0 <= index && index < queue.length);
  }
  // End No_side_effects_funcs

  void load(List<MusicItem> queueList) {
    queue = queueList;
  }

  void addAll(List<MusicItem> queueList) {
    queue.addAll(queueList);
    updateIdx++;
  }

  void addAllNext(List<MusicItem> queueList) {
    assert(-1 <= _currentIdx && _currentIdx < queue.length,
        'queue._currentIdx is out of bounds');
    queue.insertAll(_currentIdx + 1, queueList);
    updateIdx++;
  }

  void insertAll(int index, List<MusicItem> queueList) {
    assert(-1 <= index && index < queue.length,
        'queue._currentIdx is out of bounds');
    queue.insertAll(index, queueList);
    updateIdx++;
  }

  void setAt(int index, MusicItem mi) {
    assert(0 <= index && index < queue.length,
        'queue._currentIdx is out of bounds');
    queue[index].set(mi);
    updateIdx++;
  }

  // void replaceAt(int index, MusicItem mi) {
  //   assert(0 <= index && index < queue.length,
  //       'queue._currentIdx is out of bounds');
  //   queue[index] = mi;
  //   updateIdx++;
  // }

  void clear() {
    if (_currentIdx == -1) {
      queue = [];
    } else {
      queue.removeRange(_currentIdx + 1, queue.length);
      queue.removeRange(0, _currentIdx);
      setCurrIdx(0);
    }
    updateIdx++;
  }

  void removeSourceItems(String sourceId) {
    // Iterating backwards because list is changing
    for (int i = queue.length - 1; i >= 0; i--) {
      if (queue[i].sourceId == sourceId) {
        removeAt(i);
      }
    }
    updateIdx++;
  }

  // For js
  void removeRange(int start, int end) {
    queue.removeRange(start, end);
  }

  void removeAt(int idx) {
    assert(_checkIndexInBounds(idx), 'Index is out of bounds');
    if (idx < _currentIdx) {
      // Top elements
      setCurrIdx(_currentIdx - 1);
    }
    // Self
    if (idx == _currentIdx && isAtTail && length != 1) {
      // Play track before last
      setCurrIdx(_currentIdx - 1);
    }
    // Bottom elements
    // Nothing changes
    queue.removeAt(idx);
  }

  void deleteQueue() {
    queue = [];
    _invalidateCurrIdx();
  }

  void setCurrIdx(int index) {
    assert(_checkIndexInBounds(index), 'Index is out of bounds');
    _currentIdx = index;
    onCurrIdxChange?.call(_currentIdx);
  }

  void _invalidateCurrIdx() {
    _currentIdx = -1;
    onCurrIdxChange?.call(_currentIdx);
  }

  void shuffle() {
    setCurrIdx(0);
    queue.shuffle();
    updateIdx++;
  }

  void moveElement(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final el = queue.removeAt(oldIndex);
    queue.insert(newIndex, el);

    if (_currentIdx == oldIndex) {
      // self move
      setCurrIdx(newIndex);
    } else if (_currentIdx < oldIndex && _currentIdx >= newIndex) {
      // bottom-up move
      setCurrIdx(_currentIdx + 1);
    } else if (_currentIdx > oldIndex && _currentIdx <= newIndex) {
      // up-bottom move
      setCurrIdx(_currentIdx - 1);
    }
    updateIdx++;
  }

  void toggleRepeat() {
    switch (repeatState) {
      case RepeatState.norepeat:
        repeatState = RepeatState.repeatAll;
        break;
      case RepeatState.repeatAll:
        repeatState = RepeatState.repeatOne;
        break;
      case RepeatState.repeatOne:
        repeatState = RepeatState.norepeat;
        break;
    }
  }

  bool prev() {
    if (!canPrev()) {
      return false;
    }

    switch (repeatState) {
      case RepeatState.norepeat:
      case RepeatState.repeatOne:
        _prevItem();
        break;
      case RepeatState.repeatAll:
        if (isAtHead) {
          setCurrIdx(queue.length - 1);
        } else {
          _prevItem();
        }
        break;
    }
    return true;
  }

  bool next() {
    if (!canNext()) {
      return false;
    }

    switch (repeatState) {
      case RepeatState.norepeat:
      case RepeatState.repeatOne:
        _nextItem();
        break;
      case RepeatState.repeatAll:
        if (isAtTail) {
          setCurrIdx(0);
        } else {
          _nextItem();
        }
        break;
    }
    return true;
  }

  bool proceed() {
    if (repeatState == RepeatState.repeatOne) {
      // Do nothing
      return true;
    }
    return next();
  }

  void _prevItem() {
    setCurrIdx(_currentIdx - 1);
  }

  void _nextItem() {
    setCurrIdx(_currentIdx + 1);
  }
}
