import 'package:music_player/states/PlaybackState.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:music_player/logger.dart';
import 'package:music_player/logic/playback/Playback.dart' show Playback;
import 'package:music_player/main.dart' show config;

class VolumeControls extends StatefulWidget {
  const VolumeControls({super.key, this.isAlwaysVisible = false});
  final bool isAlwaysVisible;

  @override
  State<VolumeControls> createState() => VolumeControlsState();
}

class VolumeControlsState extends State<VolumeControls> {
  bool isVisible = false;
  bool isMuted = false;

  late Playback playback =
      Provider.of<PlaybackState>(context, listen: false).playback;

  @override
  void initState() {
    // gLogger.view('_VolumeControlsState init');

    // TODO: do on playbck init
    isMuted = config.getProperty('isMuted') ?? isMuted;
    if (isMuted) {
      playback.setVolume(0);
    } else {
      // TODO: make default value for properties
      final double vol = config.getProperty('volume') ?? 1.0;
      playback.setVolume(vol);
    }
    // todo end
    super.initState();
  }

  void setIsMuted(val) {
    isMuted = val;
    config.saveProperty('isMuted', val);
  }

  @override
  Widget build(BuildContext context) {
    var iconData = PhosphorIconsThin.speakerSlash;
    double volume =
        context.select<PlaybackState, double>((s) => s.playback.volume);
    if (!isMuted) {
      if (volume == 0) {
        iconData = PhosphorIconsThin.speakerSimpleNone;
      } else {
        iconData = PhosphorIconsThin.speakerHigh;
      }
    }
    return MouseRegion(
      onEnter: (event) {
        setState(() {
          isVisible = true;
        });
      },
      onExit: (event) {
        setState(() {
          isVisible = false;
        });
      },
      child: Row(
        children: [
          Visibility.maintain(
            visible: widget.isAlwaysVisible || isVisible,
            child: SizedBox(
              width: 130,
              child: _VolumeSlider(
                  initial: config.getProperty('volume') ?? 1.0,
                  onChangeEnd: (val) async {
                    await playback.setVolume(val);
                    config.saveProperty('volume', val);
                    setState(() => setIsMuted(false));
                  }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0, right: 12),
            child: InkWell(
              onTap: () {
                if (!isMuted) {
                  playback.setVolume(0);
                } else {
                  playback.setVolume(config.getProperty('volume'));
                }
                setState(() => setIsMuted(!isMuted));
              },
              child: Icon(iconData, size: 22.0),
            ),
          ),
        ],
      ),
    );
  }
}

class _VolumeSlider extends StatefulWidget {
  const _VolumeSlider({
    required this.initial,
    required this.onChangeEnd,
  });

  final double initial;
  final void Function(double)? onChangeEnd;

  @override
  State<_VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<_VolumeSlider> {
  double value = 0;

  @override
  void initState() {
    super.initState();
    value = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
      ),
      child: Slider(
        value: value,
        divisions: 50,
        onChanged: (value) {
          setState(() {
            this.value = value;
          });
        },
        onChangeEnd: widget.onChangeEnd,
      ),
    );
  }
}
