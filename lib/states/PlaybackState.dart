import 'package:flutter/material.dart';
import 'package:music_player/logic/audioNotificationHandler.dart';

import 'package:music_player/logic/playback/Playback.dart';
import 'package:music_player/states/DownloadsState.dart';

class PlaybackState extends ChangeNotifier {
  PlaybackState(this.audioHandler, DownloadsState downloadsState) : super() {
    playback = Playback(update, downloadsState);
    audioHandler?.initAsync(playback);
  }

  late Playback playback;
  late MyAudioHandler? audioHandler;

  void update() {
    notifyListeners();
  }
}
