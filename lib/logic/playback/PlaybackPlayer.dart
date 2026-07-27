import 'package:audioplayers/audioplayers.dart';
import 'package:music_player/logger.dart' show gLogger;

import 'package:music_player/logic/enums.dart' show PlayState;

class PlaybackPlayer {
  PlayState playState = PlayState.idle;
  AudioPlayer audioPlayer = AudioPlayer();

  // Stream<String> get focusManagerEventStream => audioPlayer.eventStream
  //     .where((AudioEvent e) => e.eventType == AudioEventType.focusManager)
  //     .map((AudioEvent e) => e.logMessage!);

  Future<Duration?> setFilePath(String path) async {
    await audioPlayer.setSource(DeviceFileSource(path));
    return await audioPlayer.getDuration();
  }

  Future<Duration?> setUrl(String url) async {
    await audioPlayer.setSource(UrlSource(url));
    return await audioPlayer.getDuration();
  }

  Future<Duration?> setByteStream() async {
    await audioPlayer.setSource(ByteStreamSource());
    return await audioPlayer.getDuration();
  }

  Future<int> pushBuffer(List<int> buffer) async {
    return await audioPlayer.pushBuffer(buffer);
  }

  Future<void> flushBuffers() async {
    return await audioPlayer.flushBuffers();
  }

  Future<void> setHttpProxy(String http_proxy) async {
    return await audioPlayer.setHttpProxy(http_proxy);
  }

  /// Seeks. Doesn't change playState.
  Future<void> seek(Duration duration) async {
    assert([PlayState.pause, PlayState.playing, PlayState.endOfQueue]
        .contains(playState));
    gLogger.debug('_playback.seek()');
    return await audioPlayer.seek(duration);
  }

  /// Plays. Changes playState to playing.
  Future<void> play([Duration? position]) async {
    playState = PlayState.playing;
    if (position != null) {
      gLogger.debug('_playback.play .seek()');
      await audioPlayer.seek(position);
    }
    await audioPlayer.resume();
  }

  /// Resumes. Changes playState to playing.
  Future<void> resume() async {
    assert(playState == PlayState.pause || playState == PlayState.loading);
    playState = PlayState.playing;
    await audioPlayer.resume();
  }

  /// Pauses. Changes playState to pause.
  Future<void> pause() async {
    assert(playState == PlayState.playing || playState == PlayState.loading);
    await audioPlayer.pause();
    playState = PlayState.pause;
  }

  /// Stops. Sets playState.
  Future<void> stopWith(PlayState state) async {
    await audioPlayer.stop();
    playState = state;
  }

  Future<void> dispose() async {
    await audioPlayer.dispose();
    playState = PlayState.idle;
  }

  Future<void> setVolume(double volume) async {
    await audioPlayer.setVolume(volume);
  }
}
