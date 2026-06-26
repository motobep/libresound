import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:music_player/logger.dart';
import 'package:music_player/logic/Config.dart';
import 'package:music_player/logic/lang.dart';
import 'package:music_player/states/AppState.dart';
import 'package:music_player/view/components/inputs.dart';
import 'package:provider/provider.dart';

import 'package:audioplayers/audioplayers.dart' show Equalizer;

import 'package:music_player/states/AppearanceState.dart';

class EqualizerWidget extends StatelessWidget {
  final Equalizer equalizer;

  EqualizerWidget({
    super.key,
    required this.equalizer,
  });

  final ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    Config config = Provider.of<AppState>(context, listen: false).config;

    return FutureBuilder<Map<String, dynamic>>(
      future: () async {
        try {
          final numBands = (await equalizer.getNumberOfBands())!;
          final limits = await equalizer.getLimits();

          final bands = [];
          var frequencies = [
            32.0,
            64.0,
            125.0,
            250.0,
            500.0,
            1000.0,
            2000.0,
            4000.0,
            8000.0,
            16000.0
          ];

          bool? isEqEnabled = config.getProperty('isEqEnabled');
          bool isEnabled = isEqEnabled ?? false;
          await equalizer.setEnabled(isEnabled);

          for (var i = 0; i < numBands; i++) {
            if (Platform.isLinux) {
              await equalizer.setBand(i, {
                'bandwidth': frequencies[i] / 1.5,
                'frequency': frequencies[i]
              });
            }

            // Setting from config storage
            double? gainProp = config.getProperty('EQ.gain-$i');
            await equalizer.setBand(i, {
              'gain': gainProp ?? 0.0,
            });

            final el = (await equalizer.getBand(i))!;
            bands.add(el);
          }
          return {
            'isEnabled': isEnabled,
            'numBands': numBands,
            'limits': limits,
            'bands': bands,
          };
        } catch (e) {
          gLogger.error('Exception in EqualizerWidget: $e');
          rethrow;
        }
      }(),
      builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
        if (snapshot.hasError) {
          return const Text('Equalizer widget errored');
        }
        if (!snapshot.hasData) {
          return const Text('Equalizer...');
        }
        final isEnabled = snapshot.data!['isEnabled'] as bool;
        final numBands = snapshot.data!['numBands'] as int;
        final limits = snapshot.data!['limits'] as Map;
        final bands = snapshot.data!['bands'] as List;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(lang.Enabled),
                CheckboxInput(
                  initial: isEnabled,
                  onSelect: (val) {
                    equalizer.setEnabled(val!);
                    config.saveProperty('isEqEnabled', val);
                    return true;
                  },
                )
              ],
            ),
            const SizedBox(height: 8.0),
            SizedBox(
              height: 380.0,
              child: Scrollbar(
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
                            padding: const EdgeInsets.only(right: 18.0),
                            child: _EqSlider(
                              name: '${freq.toStringAsFixed(0)} Hz',
                              value: gain,
                              min: gainLimits[0] as double,
                              max: gainLimits[1] as double,
                              onChangeEnd: (value) async {
                                config.saveProperty('EQ.gain-$i', value);
                                equalizer.setBand(i, {'gain': value});
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
              ),
            ),
          ],
        );
      },
    );
  }
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
  Widget build(BuildContext context) {
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);
    var color = appearanceState.lerpBgColor(0.6);

    return Column(
      children: [
        Text('${_value.toStringAsFixed(1)} dB',
            style: TextStyle(color: color, fontSize: 13.0)),
        Expanded(
          child: RotatedBox(
            quarterTurns: -1,
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
        Text(
            '${widget.min.toStringAsFixed(0)}~${widget.max.toStringAsFixed(0)} dB',
            style: TextStyle(color: color, fontSize: 12.0)),
        const SizedBox(height: 8.0),
        Text(widget.name),
      ],
    );
  }
}
