import 'package:flutter/material.dart';
import 'package:music_player/logger.dart';
import 'package:music_player/logic/EqPresets.dart';
import 'package:music_player/logic/lang.dart';
import 'package:music_player/main.dart' show config;
import 'package:music_player/states/AppState.dart';
import 'package:music_player/view/components/inputs.dart';
import 'package:provider/provider.dart';

import 'package:audioplayers/audioplayers.dart' show Equalizer;

import 'package:music_player/states/AppearanceState.dart';

class EqualizerWidget extends StatelessWidget {
  final Equalizer equalizer;

  const EqualizerWidget({
    super.key,
    required this.equalizer,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final settings = appState.eqSettings;

    if (settings.isEmpty) {
      return const Text('Equalizer widget errored');
    }

    return _EqControls(
        isEnabled: settings['isEnabled'] as bool,
        setIsEnabled: (bool v) {
          settings['isEnabled'] = v;
          equalizer.setEnabled(v);
          config.saveProperty('isEqEnabled', v);
        },
        equalizer: equalizer,
        bands: settings['bands'] as List,
        limits: settings['limits'] as Map);
  }
}

class _EqControls extends StatefulWidget {
  const _EqControls({
    required this.isEnabled,
    required this.setIsEnabled,
    required this.equalizer,
    required this.bands,
    required this.limits,
  });

  final bool isEnabled;
  final void Function(bool) setIsEnabled;
  final Equalizer equalizer;
  final List<dynamic> bands;
  final Map<dynamic, dynamic> limits;

  @override
  State<_EqControls> createState() => _EqControlsState();
}

class _EqControlsState extends State<_EqControls> {
  List<dynamic> bands = [];

  @override
  void initState() {
    super.initState();
    bands = widget.bands;
  }

  @override
  Widget build(BuildContext context) {
    final equalizer = widget.equalizer;

    final presets = [
      (EqPreset.custom, lang.eq__Custom),
      (EqPreset.classical, lang.eq__Classical),
      (EqPreset.club, lang.eq__Club),
      (EqPreset.dance, lang.eq__Dance),
      (EqPreset.enhanced_bass, lang.eq__Enhanced_bass),
      (EqPreset.enhanced_bass_and_tremble, lang.eq__Enhanced_bass_and_tremble),
      (EqPreset.enhanced_tremble, lang.eq__Enhanced_tremble),
      (EqPreset.large_hall, lang.eq__Large_hall),
      (EqPreset.live, lang.eq__Live),
      (EqPreset.party, lang.eq__Party),
      (EqPreset.pop, lang.eq__Pop),
      (EqPreset.reggae, lang.eq__Reggae),
      (EqPreset.rock, lang.eq__Rock),
      (EqPreset.ska, lang.eq__Ska),
      (EqPreset.soft, lang.eq__Soft),
      (EqPreset.soft_rock, lang.eq__Soft_rock),
      (EqPreset.techno, lang.eq__Techno),
    ];
    final elements = presets;

    final List<double> gains = bands.map((b) => b['gain'] as double).toList();
    final EqPreset presetInitial = _findPreset(gains) ?? EqPreset.custom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(lang.Equalizer, style: const TextStyle(fontSize: 22.0)),
            const SizedBox(width: 4.0),
            CheckboxInput(
              initial: widget.isEnabled,
              onSelect: (val) {
                widget.setIsEnabled(val);
                setState(() {});
                return true;
              },
            )
          ],
        ),
        const SizedBox(height: 6.0),
        SelectInput<EqPreset>(
            elements: elements,
            initial: presetInitial,
            isCompact: true,
            onSelect: (preset) async {
              gLogger.log('eqPreset: $preset');
              if (preset == EqPreset.custom) {
                gLogger.log('\tCustom preset');
              } else {
                final List<double> gains = eqPresets_10_band[preset]!;
                assert(gains.length == bands.length, 'Bad gains length');
                for (var i = 0; i < gains.length; i++) {
                  final gain = gains[i];
                  await _setBandGain(i, gain);
                }
              }
              bands = [...bands];
              setState(() {});
            }),
        const SizedBox(height: 12.0),
        Flexible(
          child: _EqBands(
            equalizer: equalizer,
            bands: bands,
            limits: widget.limits,
            onGainChange: (i, value) async {
              await _setBandGain(i, value);
              setState(() {});
            },
          ),
        ),
      ],
    );
  }

  EqPreset? _findPreset(List<double> gains) {
    for (var p in EqPreset.values) {
      final g = eqPresets_10_band[p];
      if (g == null) continue;
      if (_compareGains(g, gains)) {
        return p;
      }
    }
    return null;
  }

  bool _compareGains(List<double> left, List<double> right) {
    assert(left.length == right.length,
        'gains.length: ${left.length} != ${right.length}');
    if (left.length != right.length) return false;

    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) {
        return false;
      }
    }
    return true;
  }

  Future<void> _setBandGain(int i, double gain) async {
    bands[i]['gain'] = gain;
    config.saveProperty('EQ.gain-$i', gain);
    await widget.equalizer.setBand(i, {'gain': gain});
  }
}

class _EqBands extends StatelessWidget {
  _EqBands({
    required this.equalizer,
    required this.bands,
    required this.limits,
    required this.onGainChange,
  });

  final Equalizer equalizer;
  final List<dynamic> bands;
  final Map<dynamic, dynamic> limits;
  final Function(int i, double value) onGainChange;

  final ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    gLogger.blue('_EqBands');
    final numBands = bands.length;

    return Scrollbar(
      controller: scrollController,
      child: ListView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        children: [
          ...((List.generate(numBands, (i) => i)).map(
            (i) {
              final band = bands[i] as Map;

              final gain = band['gain'] as double;
              final freq = band['frequency'] as double;

              final gainLimits = limits['gain'] as List;

              if (gainLimits.length == 2) {
                return Padding(
                  padding: const EdgeInsets.only(right: 0.0),
                  child: _EqSlider(
                    name: _toHzString(freq),
                    value: gain,
                    min: gainLimits[0] as double,
                    max: gainLimits[1] as double,
                    onChangeEnd: (value) async {
                      onGainChange(i, value);
                    },
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ).toList()),
        ],
      ),
    );
  }
}

String _toHzString(double freq) {
  String suffix = 'Hz';
  if (freq >= 1000) {
    freq /= 1000;
    suffix = 'KHz';
  }
  return '${freq.toStringAsFixed(0)} ${suffix}';
}

class _EqSlider extends StatefulWidget {
  const _EqSlider({
    required this.onChangeEnd,
    required this.name,
    required this.value,
    required this.min,
    required this.max,
  });

  final void Function(double) onChangeEnd;
  final String name;
  final double value;
  final double min;
  final double max;

  @override
  State<_EqSlider> createState() => _EqSliderState();
}

class _EqSliderState extends State<_EqSlider> {
  late double _value;

  @override
  void initState() {
    _value = widget.value;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != oldWidget.value && widget.value != _value) {
      _value = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);
    var color = appearanceState.lerpBgColor(0.6);

    return SizedBox(
      width: 52,
      child: Column(
        children: [
          Text('${_value.toStringAsFixed(1)} dB',
              style: TextStyle(color: color, fontSize: 13.0)),
          const SizedBox(height: 6.0),
          Expanded(
            child: RotatedBox(
              quarterTurns: -1,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 5,
                ),
                child: Slider(
                  min: widget.min,
                  max: widget.max,
                  value: _value,
                  onChanged: (value) {
                    setState(() {
                      _value = value;
                    });
                  },
                  onChangeEnd: (value) {
                    widget.onChangeEnd(value);
                    setState(() {
                      _value = value;
                    });
                  },
                ),
              ),
            ),
          ),
          // Text(
          //     '${widget.min.toStringAsFixed(0)}~${widget.max.toStringAsFixed(0)} dB',
          //     style: TextStyle(color: color, fontSize: 12.0)),
          const SizedBox(height: 4.0),
          Text(widget.name),
        ],
      ),
    );
  }
}
