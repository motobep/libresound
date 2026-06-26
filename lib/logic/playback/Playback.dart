import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart' show AudioEventType, Equalizer;
import 'package:music_player/logic/Source.dart' show Source;

import 'package:music_player/main.dart' show config;
import 'package:music_player/logger.dart';
import 'package:music_player/logic/fs/cache.dart' as cache;
import 'package:music_player/logic/utils.dart';
import 'package:music_player/logic/MusicItem.dart';
import 'package:music_player/logic/enums.dart';
import 'package:music_player/logic/audioNotificationHandler.dart';
import 'package:music_player/states/DownloadsState.dart';

import 'PlaybackQueue.dart' show PlaybackQueue;
import 'ProgressCounter.dart' show ProgressCounter;
import 'PlaybackPlayer.dart' show PlaybackPlayer;

class Playback {
  Playback(this.update, this.downloadsState) {
    _progressCounter = ProgressCounter();
    _progressCounter.addListener(onUpdateCallback, type: 'update');
    _progressCounter.addListener(onEndCallback, type: 'end');

    _playback.audioPlayer.eventStream.listen((state) {
      // if (state.eventType != AudioEventType.position)
      // logger.warn('eventStream: $state');
      if (state.eventType == AudioEventType.seekComplete) {
        logger.warn('seekComplete="$state"');
      }
      if (state.eventType == AudioEventType.log &&
          Platform.isLinux &&
          state.logMessage != null &&
          state.logMessage!.contains('Could not set playback to position')) {
        logger.warn('Bad seek: ${state}');

        final pattern = RegExp(r'\((-?\d+)\)');
        final match = pattern.firstMatch(state.logMessage!);
        int fromMs = int.parse(match!.group(1)!);
        if (fromMs < 0) return;

        logger.warn('Reverting counter to ($fromMs)');
        setPosition(fromMs);

        update();
        _updateNotificationsState();
      }
    });

    // _playback.audioPlayer.onPlayerStateChanged.listen((state) {
    //   logger.warn('PlayerState: $state');
    // });
  }

  void onUpdateCallback(int ms) {
    update();
    notifications.updateControlsIfChanged(
        Duration(milliseconds: _progressCounter.currMillisecs));
  }

  void onEndCallback(int ms) {
    _proceed();
  }

  late MyAudioHandler notifications;

  final PlaybackPlayer _playback = PlaybackPlayer();

  void Function() update;
  late Source Function(MusicItem mi) getSourceByMi;
  DownloadsState downloadsState;
  PlaybackQueue queue = PlaybackQueue();

  // States
  PlayState get playState {
    return _playback.playState;
  }

  late ProgressCounter _progressCounter;
  bool _canSelfPlay() {
    return _progressCounter.currMillisecs > 5000;
  }

  RepeatState get repeatState {
    return queue.repeatState;
  }

  // Getters
  double get volume => _playback.audioPlayer.volume;

  Equalizer get equalizer {
    return _playback.audioPlayer.equalizer;
  }

  ProgressCounter get progressCounter {
    return _progressCounter;
  }

  double get progressRatio {
    return _progressCounter.getProgressRatio();
  }

  bool get canPrev {
    return playState != PlayState.idle && (queue.canPrev() || _canSelfPlay());
  }

  bool get canNext {
    return playState != PlayState.idle && queue.canNext();
  }

  String get progressFormatted {
    return formatDuration(
        Duration(milliseconds: _progressCounter.currMillisecs));
  }

  int durationUpdatedIdx = 0;

  // Predicates
  bool isIdle() {
    return playState == PlayState.idle;
  }

  // No-side effects
  MusicItem getCurrentMusicItem() {
    if (!queue.hasValidIndex) {
      return MusicItem.dummy();
    }
    return queue.getCurrentMusicItem();
  }

  MusicItem? findMusicItem(String id) {
    return queue.findMusicItem(id);
  }

  double progressMilliSecsToRatio(int milliSecs) {
    return _progressCounter.toRatio(milliSecs);
  }

  void setPosition(int ms) {
    logger.debug('setPosition: $ms');
    if (_progressCounter.isActive) {
      _progressCounter.tickFrom(ms);
    } else {
      _progressCounter.currMillisecs = ms;
    }
  }

  // With-side effects
  Future<void> setVolume(double volume) async {
    assert(0 <= volume && volume <= 1, 'setVolume($volume) out of range');
    await _playback.audioPlayer.setVolume(volume);
  }

  void load(List<MusicItem> items) {
    queue.load(items);
  }

  void addItemToQueue(MusicItem item) {
    queue.addAll([item]);
    update();
    _updateNotificationsState();
  }

  Future<bool> removeItemsFromQueue(List<int> indicesDecending) async {
    logger.log('Remove item from queue');
    bool currentTrackRemove = indicesDecending.contains(queue.currentIdx);

    // Is processing
    if (_isProcessing && currentTrackRemove) {
      assert(false, 'removeItemFromQueue(): isProcessing');
      logger.error('removeItemFromQueue(): isProcessing');
      return false;
    }

    // Removing
    for (var idx in indicesDecending) {
      logger.warn('idx="${idx}"');
      queue.removeAt(idx);
    }
    queue.updateIdx++;

    if (queue.isEmpty) {
      downloadsState.removeAndAbortByType_n(DownloadType.play);
      await stopWith_n(PlayState.idle);
      return false;
    }

    if (currentTrackRemove) {
      await _playCurrentTrack_n();
      return true;
    }

    update();
    _updateNotificationsState();
    return true;
  }

  Future<void> removeSourceItemsFromQueue(String sourceId) async {
    logger.log('removeSourceItemsFromQueue');
    if (queue.isEmpty) {
      return;
    }
    var currMi = queue.getCurrentMusicItem();
    if (_isProcessing && currMi.sourceId == sourceId) {
      assert(false, 'removeSourceItemsFromQueue(): isProcessing');
      logger.error('removeSourceItemsFromQueue(): isProcessing');
      return;
    }
    queue.removeSourceItems(sourceId);
    if (queue.isEmpty) {
      downloadsState.removeAndAbortByType_n(DownloadType.play);
      await stopWith_n(PlayState.idle);
      return;
    }
    if (currMi.sourceId == sourceId) {
      bool wasPaused = _playback.playState == PlayState.pause;
      await _playCurrentTrack_n();
      if (wasPaused) {
        await _pause();
      }
    }
  }

  void addAll_n(List<MusicItem> items) {
    queue.addAll(items);
    update();
  }

  void addAllNext_n(List<MusicItem> items) {
    queue.addAllNext(items);
    update();
  }

  void clearQueue_n() {
    queue.clear();
    update();
  }

  Future<void> deleteQueue() async {
    logger.log('Delete Queue');
    queue.deleteQueue();
    downloadsState.removeAndAbortByType_n(DownloadType.play);
    await stopWith_n(PlayState.idle);
  }

  /// Throws
  Future<void> seek(double from) async {
    // FIXME later: changing track if prev_track.time_pos > curr_track.time_pos (probably only on linux)
    logger.log('seek from: $from');

    if (!(playState == PlayState.playing || playState == PlayState.pause)) {
      logger.warn('Bad playState for seeking: ${playState}');
      return;
    }

    if (from < 0 || 1 < from) {
      assert(false, 'from=$from out of range [0, 1]');
      return;
    }

    // Prohibit seek if duration is not positive
    final realDuration = await _playback.audioPlayer.getDuration();
    logger.log('seek realDuration: $realDuration');
    if (
        // realDuration == null ||
        realDuration == const Duration(milliseconds: 0)) {
      // TODO: move to a function
      logger.warn('Prohibit seek. Bad realDuration: $realDuration');
      update();
      return;
    }

    // Seek at the end of range
    if (from == 1) {
      _proceed();
      return;
    }

    final seekToMs = _progressCounter.toMilliSecs(from);

    try {
      bool ret = await getSourceByMi(getCurrentMusicItem()).seekAsync(seekToMs);
      if (ret) {
        logger.blue('overriden seekAsync');
        return;
      }
    } catch (e, s) {
      logger.exception('in seekAsync().', e, s);
      return;
    }

    // Don't seek on pause
    try {
      final seekTo = Duration(milliseconds: seekToMs);
      logger.log('Actual seek to: $seekTo');
      await _playback.seek(seekTo);
      // TODO: Check for successful seek properly
    } catch (e) {
      logger.log('Excetption in playback.seek(): $e');
      rethrow;
    }
    setPosition(seekToMs);

    update();
    _updateNotificationsState();
  }

  void toggleRepeat() {
    queue.toggleRepeat();

    update();
    _updateNotificationsState();
  }

  /// Throws
  Future<void> _resume() async {
    assert(playState == PlayState.pause);
    try {
      await getSourceByMi(getCurrentMusicItem())
          .triggerEventAsync('BeforeResumeAsync', {});
    } catch (e, s) {
      logger.exception('in onBeforeResumeAsync(). Aborting _resume()', e, s);
      return;
    }

    try {
      _progressCounter.resume();
      await _playback.resume();
    } catch (e) {
      logger.log('Exception while resuming: $e');
    }

    logger.log('resume(): state $playState');
    update();
    _updateNotificationsState();
  }

  Future<void> _pause() async {
    try {
      await getSourceByMi(getCurrentMusicItem())
          .triggerEventAsync('BeforePauseAsync', {});
    } catch (e, s) {
      logger.exception('in onBeforePauseAsync()', e, s);
    }
    _progressCounter.cancel();
    await _playback.pause();

    logger.log('pause(): state $playState');
    update();
    _updateNotificationsState();
  }

  Future<void> stopWith_n(PlayState state) async {
    _progressCounter.cancel();
    await _playback.stopWith(state);

    logger.log('_stopWith(): playState=$playState');
    update();
    _updateNotificationsState();
  }

  Future<void> dispose() async {
    await _playback.dispose();
  }

  // For the future
  // Future<void> setVolume(double volume) async {
  //   await _playback.setVolume(volume);
  // }

  // New methods
  /// Complex control of playback.
  /// Uses DownloadsState.
  /// Notifies
  Future<void> playByIdx_n(int index) async {
    if (_isProcessing) {
      logger.error('isProcessing');
      return;
    }
    queue.setCurrIdx(index);
    MusicItem mi = getCurrentMusicItem();
    logger.log('Playing "${mi.title}", id="${mi.id}"');

    // Delegate play to source
    _isProcessing = true;
    try {
      logger.debug('setPlaybackSourceAsync');
      await getSourceByMi(mi).setPlaybackSourceAsync(mi);
      logger.debug('_playMusicItem');
      await _playMusicItem(mi);
    } catch (e, s) {
      logger.exception('trying to play. Aborting play', e, s);
      stopWith_n(PlayState.notReady);
      await getSourceByMi(getCurrentMusicItem())
          .triggerEventAsync('PlayFailure', {});
      return;
    } finally {
      _isProcessing = false;
    }

    // Update
    logger.log('playByIdx_n(): state $playState');
    update();
    // FIXME: add to isProcessing to fix bug with the wrong cover in notifications?
    await _updateNotificationsState();
  }

  List<int> byteStream = [];

  /// Throws (maybe)
  Future<void> setByteStreamSourceAsync(MusicItem mi) async {
    Duration? realDuration = await _playback.setByteStream();
    logger.log('playFromByteStreamAsync() real duration: $realDuration');
    if (realDuration != null && realDuration.inSeconds > 0) {
      mi.duration = realDuration;
      durationUpdatedIdx++;
    }
  }

  Future<int> pushBufferAsync(List<int> buffer) async {
    return await _playback.pushBuffer(buffer);
  }

  Future<void> flushBuffersAsync() async {
    return await _playback.flushBuffers();
  }

  Future<void> setHttpProxy(String http_proxy) async {
    return await _playback.setHttpProxy(http_proxy);
  }

  /// Throws (maybe)
  Future<void> setUrlSourceAsync(MusicItem mi) async {
    assert(mi.url != null, 'MusicItem.url == null');
    Duration? realDuration = await _playback.setUrl(mi.url!);
    logger.log('playFromUrlAsync() real duration: $realDuration');
    if (realDuration != null && realDuration.inSeconds > 0) {
      mi.duration = realDuration;
      durationUpdatedIdx++;
    }
  }

  /// Throws
  Future<void> setFileSourceAsync(MusicItem mi) async {
    var endTimeSecs = mi.durationInSeconds;
    Duration? realDuration = await _playback.setFilePath(mi.filepath!);
    logger.log('setFileSourceAsync() real duration: $realDuration');
    if (realDuration != null) {
      mi.duration = realDuration;

      // TODO: Delegate to FsSource
      if (mi.durationInSeconds != endTimeSecs && mi.durationInSeconds > 0) {
        // Update duration in gui and cache
        logger.warn('Got real duration');
        durationUpdatedIdx++;

        final sourceDirPath = config.musicSourceDir!.path;
        final ok = cache.updateCachedInfoMiDuration(mi, sourceDirPath);
        logger.warn('Is cached info updated: $ok');
      }
    }

    endTimeSecs = mi.durationInSeconds;
    if (endTimeSecs <= 0) {
      throw 'logger.error: Trying to play item with not positive duration';
    }
  }

  Future<void> _playMusicItem(MusicItem mi) async {
    assert(mi.filepath != null || mi.url != null, 'mi filepath or url is null');
    assert(mi.durationInSeconds > 0, 'bad duration');

    try {
      logger.debug('_playback.play()');
      await _playback.play(const Duration(seconds: 0));
      _progressCounter.tickTillMs(mi.durationInSeconds * 1000);
    } catch (e) {
      logger.error('Exception in ._playMusicItem():\n$e\nEnd of Exception');

      await stopWith_n(PlayState.notReady);
    }
  }

  Future<void> togglePlayback() async {
    switch (playState) {
      case PlayState.playing:
        await _pause();
        break;
      case PlayState.pause:
        await _resume();
        break;
      case PlayState.endOfQueue:
        logger.log('Toggling playback in endOfQueue PlayState');
        if (_isProcessing) {
          logger.error('togglePlayback() (endOfQueue): isProcessing');
          return;
        }
        queue.setCurrIdx(0);
        await _playCurrentTrack_n();
        break;
      case PlayState.idle:
        logger.log('Toggling playback in idle PlayState');
        assert(false, 'Toggling playback in idle PlayState');
        break;
      case PlayState.notReady:
        logger.log('Toggling playback in notReady PlayState');
        await _playCurrentTrack_n();
      case PlayState.loading:
        MusicItem mi = queue.getCurrentMusicItem();
        final dId = DownloadsState.fmt(DownloadType.play, mi.sourceId, mi.id);
        if (downloadsState.has(dId)) {
          downloadsState.removeAndSafeAbort_n(dId);
        }
        await stopWith_n(PlayState.notReady);
        break;
    }
  }

  Future<void> playPrev() async {
    if (_isProcessing) {
      logger.error('playPrev(): isProcessing');
      return;
    }
    if (_canSelfPlay()) {
      await seek(0);
      return;
    }

    bool ok = queue.prev();
    if (!ok) return;
    await _playCurrentTrack_n();
  }

  bool _isProcessing = false;

  Future<void> playNext() async {
    if (_isProcessing) {
      logger.error('playNext(): isProcessing');
      return;
    }
    bool ok = queue.next();
    if (!ok) return;
    await _playCurrentTrack_n();
  }

  Future<void> shuffle() async {
    if (_isProcessing) {
      logger.error('shuffle(): isProcessing');
      return;
    }
    queue.shuffle();
    await _playCurrentTrack_n();
  }

  Future<void> _proceed() async {
    if (_isProcessing) {
      logger.error('_proceed(): isProcessing');
      return;
    }
    bool ok = queue.proceed();
    if (ok) {
      await _playCurrentTrack_n();
    } else {
      if (queue.isAtTail) {
        await stopWith_n(PlayState.endOfQueue);
      } else {
        assert(true, 'must not be here');
      }
    }
  }

  /// Complex play.
  /// Uses playByIdx():
  Future<void> _playCurrentTrack_n() async {
    await playByIdx_n(queue.currentIdx);
  }

  Future<void> _updateNotificationsState() async {
    MusicItem mi = getCurrentMusicItem();
    await notifications.setUniversalState(
        playState, mi, Duration(milliseconds: _progressCounter.currMillisecs));
  }

  static final Logger logger = Logger(prefix: '📙 Playback: ');
}
