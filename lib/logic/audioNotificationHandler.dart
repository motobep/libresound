import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart'
    show AudioInterruptionType, AudioSession;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:music_player/logger.dart';

import 'package:music_player/logic/MusicItem.dart';
import 'package:music_player/logic/playback/Playback.dart';
import 'package:music_player/logic/enums.dart' show PlayState;

Future<MyAudioHandler?> initAudioService() async {
  return await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'org.LibreSound.audio',
      androidNotificationChannelName: 'Music playback',
      // androidNotificationOngoing: false,
      androidStopForegroundOnPause: true,
    ),
  );
}

class MyAudioHandler extends BaseAudioHandler
    with
        QueueHandler, // mix in default queue callback implementations
        SeekHandler {
  void initAsync(Playback playback) async {
    this.playback = playback;
    playback.notifications = this;

    if (Platform.isAndroid) {
      await AudioService.androidForceEnableMediaButtons();
    }

    session = await AudioSession.instance;
    session.interruptionEventStream.listen((event) {
      print('--------------');
      logger.log(
          'interruptionEventStream event: $event, Type: ${event.type}, begin: ${event.begin}');
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            // Another app started playing audio and we should duck.
            if (playback.playState == PlayState.playing) {
              pause();
            }
            break;
          case AudioInterruptionType.pause:
            if (playback.playState == PlayState.playing) {
              pause();
            } else {
              _isIgnoreNextResume = true;
            }
          case AudioInterruptionType.unknown:
            // Another app started playing audio and we should pause.
            if (playback.playState == PlayState.playing) {
              pause();
            }
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            // The interruption ended and we should unduck.
            if (playback.playState == PlayState.pause) {
              play();
            }
            break;
          case AudioInterruptionType.pause:
            // The interruption ended and we should resume.
            if (_isIgnoreNextResume) {
              _isIgnoreNextResume = false;
            } else if (playback.playState == PlayState.pause) {
              play();
            }
            break;
          case AudioInterruptionType.unknown:
            // The interruption ended but we should not resume.
            break;
        }
      }
    });
    session.becomingNoisyEventStream.listen((_) {
      // The user unplugged the headphones, so we should pause or lower the volume.
      if (playback.playState == PlayState.playing) {
        logger.log('pause on headphones unplug');
        pause();
      }
    });
  }

  late Playback playback;
  late AudioSession session;
  bool _isIgnoreNextResume = false;

  Future<void> _setMediaAsync(MusicItem mi) async {
    File f;

    if (mi.tags.picture != null) {
      FileInfo? fInfo =
          await DefaultCacheManager().getFileFromCache('thumbnail');
      if (fInfo != null) {
        // Delete if exists
        await DefaultCacheManager().removeFile('thumbnail');
      }
      f = await DefaultCacheManager().putFile(
          'thumbnail', mi.tags.picture!.bytes,
          eTag: 'png', maxAge: const Duration(days: 1));
    } else {
      FileInfo? fInfo =
          await DefaultCacheManager().getFileFromCache('thumbnail_placeholder');
      if (fInfo != null) {
        f = fInfo.file;
      } else {
        ByteData placholderData =
            await rootBundle.load('assets/images/logo_mp_512_gaps_gray.png');
        final placholderBytes = Uint8List.view(placholderData.buffer);
        f = await DefaultCacheManager().putFile(
            'thumbnail_placeholder', placholderBytes,
            eTag: 'png', maxAge: const Duration(days: 30));
      }
    }

    final item = MediaItem(
      id: mi.id,
      album: mi.album,
      title: mi.title,
      artist: mi.artistName,
      duration: mi.duration,
      artUri: Uri.file(f.path),
    );
    mediaItem.add(item);
  }

  List<MediaControl> _getControls() {
    return _getControlsPure(
        playback.playState, playback.canPrev, playback.canNext);
  }

  Future<void> _setPlayStateAsync(
      MusicItem mi, Duration updatePosition, bool isPlaying) async {
    if (isPlaying) {
      logger.debug('isPlaying: $isPlaying');
      if (await session.setActive(isPlaying)) {
        logger.debug('Now success');
      } else {
        logger.log(
            'Failed. The request was denied and the app should not play audio');
      }
    }
    await _setMediaAsync(mi);
    var st = PlaybackState(
      controls: _getControls(),
      systemActions: const {MediaAction.seek},
      updatePosition: updatePosition,
      processingState: AudioProcessingState.ready,
      playing: isPlaying,
    );
    playbackState.add(st);
  }

  Future<void> _setIdleState() async {
    final v = await session.setActive(false);
    logger.log('_setIdleState session deactivated: $v');

    var st = PlaybackState();
    playbackState.add(st);
  }

  Future<void> _setStopState() async {
    final v = await session.setActive(false);
    logger.log('_setStopState session deactivated: $v');

    var st = PlaybackState(
      controls: _getControls(),
      updatePosition: Duration.zero,
      processingState: AudioProcessingState.completed,
      playing: false,
    );
    playbackState.add(st);
  }

  Future<void> _setLoadingState() async {
    final v = await session.setActive(false);
    logger.log('_setLoadingState session deactivated: $v');

    var st = PlaybackState(
      controls: _getControls(),
      updatePosition: Duration.zero,
      processingState: AudioProcessingState.loading,
      playing: false,
    );
    playbackState.add(st);
  }

  void updateControlsIfChanged(updatePosition) {
    var current_controls = playbackState.value.controls;
    var new_controls = _getControls();
    if (isControlsEqual(current_controls, new_controls)) {
      // logger.log('Controls equal: $current_controls');
      return;
    }

    // logger.log('Controls Not equal');
    var st = playbackState.value.copyWith(
      controls: new_controls,
      updatePosition: updatePosition,
    );
    playbackState.add(st);
  }

  Future<void> setUniversalState(
      PlayState playState, MusicItem mi, Duration updatePosition) async {
    switch (playState) {
      case PlayState.playing:
        await _setPlayStateAsync(mi, updatePosition, true);
        break;
      case PlayState.pause:
        await _setPlayStateAsync(mi, updatePosition, false);
        break;
      case PlayState.endOfQueue:
        await _setIdleState();
        break;
      case PlayState.idle:
        await _setIdleState();
        break;
      case PlayState.notReady:
        await _setStopState();
        break;
      case PlayState.loading:
        await _setLoadingState();
        break;
    }
  }

  // Methods that are called by user
  @override
  Future<void> play() async {
    logger.log('play');
    await playback.togglePlayback();
  }

  @override
  Future<void> pause() async {
    logger.log('pause');
    await playback.togglePlayback();
  }

  // FIXME: Too greedy with media buttons. After another player paused, buttons become ours.
  @override
  Future<void> click([MediaButton button = MediaButton.media]) async {
    logger.log('click');
    logger.log('button=$button');
    (switch (button) {
      MediaButton.media => await playback.togglePlayback(),
      MediaButton.next => await playback.playNext(),
      MediaButton.previous => await playback.playPrev(),
    });
  }

  @override
  Future<void> stop() async {
    logger.log('stop');
    await playback.togglePlayback();
  }

  @override
  Future<void> skipToPrevious() async {
    logger.log('playPrev');
    await playback.playPrev();
  }

  @override
  Future<void> skipToNext() async {
    logger.log('playNext');
    await playback.playNext();
  }

  @override
  Future<void> seek(Duration position) async {
    logger.log('seek position=$position');
    final r = playback.progressMilliSecsToRatio(position.inMilliseconds);
    logger.log('seek ratio=$r');
    await playback.seek(r);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    return playback.toggleRepeat();
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    return await playback.shuffle();
  }
}

List<MediaControl> _getControlsPure(
    PlayState playState, bool canPrev, bool canNext) {
  List<MediaControl> controls = [];
  // controls.add(const MediaControl(
  //   androidIcon: 'drawable/audio_service_fast_rewind',
  //   label: 'SetShuffleMode',
  //   action: MediaAction.setShuffleMode,
  // ));
  if (canPrev) {
    controls.add(MediaControl.skipToPrevious);
  }
  switch (playState) {
    case PlayState.playing:
      controls.add(MediaControl.pause);
      break;
    case PlayState.pause:
      controls.add(MediaControl.play);
      break;
    case PlayState.endOfQueue:
      controls.add(MediaControl.play);
      break;
    case PlayState.notReady:
      controls.add(MediaControl.play);
      break;
    default:
      controls.add(MediaControl.stop);
      break;
  }
  if (canNext) {
    controls.add(MediaControl.skipToNext);
  }
  // controls.add(const MediaControl(
  //   androidIcon: 'drawable/audio_service_fast_forward',
  //   label: 'setRepeatMode',
  //   action: MediaAction.setRepeatMode,
  // ));
  return controls;
}

bool isControlsEqual(List<MediaControl> a, List<MediaControl> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

final Logger logger = Logger(prefix: '🍭 AudioNotification: ');
