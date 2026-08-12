import 'package:music_player/logger.dart';
import 'package:music_player/logic/enums.dart';
import 'package:music_player/logic/lang.dart';
import 'package:music_player/view/components/inputs.dart' show SelectInput;
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:file_picker/file_picker.dart';

import 'package:music_player/config.dart' as CONFIG;

import 'package:music_player/states/AppearanceState.dart';
import 'package:music_player/view/components/buttons.dart'
    show StandardButton, getBackBtn;
import 'package:music_player/view/snackBarFuncs.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
        leading: getBackBtn(context),
      ),
      body: const AppearanceBody(),
    );
  }
}

class AppearanceBody extends StatelessWidget {
  const AppearanceBody({super.key});

  @override
  Widget build(BuildContext context) {
    gLogger.build('AppearanceBody');
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);
    var themes = [
      CONFIG.draculaLikeThemeColors,
      CONFIG.synthwaveLikeThemeColors,
      CONFIG.ayuLikeThemeColors,
      CONFIG.darkThemeColors,
      CONFIG.lightThemeColors,
      CONFIG.gruvboxLikeThemeColors,
    ];

    final ambientModes = [
      (AmbientMode.off, lang.Off),
      (AmbientMode.playback, lang.Only_on_the_playback_page),
      (AmbientMode.all, lang.Everywhere)
    ];

    final Map<String, ColorType> buttons = {
      lang.Text: ColorType.text,
      lang.Background: ColorType.bg,
      lang.Subtitle: ColorType.subtitle,
      lang.Primary: ColorType.primary,
      lang.Accent: ColorType.accent,
    };

    final customTheme = appearanceState.getCustomTheme();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CONFIG.pagePaddingHor,
        vertical: CONFIG.pagePaddingVert,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lang.Color_Palettes),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (customTheme != null) ...[
                      GestureDetector(
                        onTap: () {
                          appearanceState.changeTheme(customTheme);
                        },
                        child: Pallete(customTheme),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 8.0),
                        child: Container(
                          color: ColorScheme.of(context).secondary,
                          width: 0.75,
                          height: double.infinity,
                        ),
                      ),
                    ],
                    for (var theme in themes)
                      GestureDetector(
                        onTap: () {
                          appearanceState.changeTheme(theme);
                        },
                        child: Pallete(theme),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(lang.Colors),
              const SizedBox(height: 5),
              for (var entry in buttons.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 5),
                      ColorExample(appearanceState.colors[entry.value]!, 20),
                      const SizedBox(width: 12),
                      StandardButton(entry.key, onTap: () {
                        showColorPicker(
                          context,
                          entry.value,
                          appearanceState,
                          (Color color) {
                            appearanceState.changeColor_n(entry.value, color);
                          },
                        );
                      }),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              StandardButton(lang.Save_palette, onTap: () {
                appearanceState.saveCustomPalette();
              }),
              const SizedBox(height: 42 - 8),
              Text(lang.Dynamic_theme),
              const SizedBox(height: 6),
              SelectInput(
                elements: ambientModes,
                initial: appearanceState.ambientMode,
                onSelect: (mode) {
                  appearanceState.onAmbientModeChange(mode!);
                },
              ),
              const SizedBox(height: 32),
              Text(lang.Custom_Font),
              const SizedBox(height: 4),
              Text(
                '${lang.Supported_formats}: ttf, otf.',
                style: TextStyle(
                    fontSize: 12, color: ColorScheme.of(context).secondary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  StandardButton(lang.Reset, onTap: () {
                    appearanceState.resetFont();
                  }),
                  const SizedBox(width: 10),
                  StandardButton(
                    lang.Choose,
                    onTap: () async {
                      var messengerFunc = getSnackBarMessangerFunc(context);
                      FilePickerResult? result =
                          await FilePicker.platform.pickFiles();

                      if (result != null) {
                        String path = result.files.single.path!;
                        gLogger.view(path);
                        String? err = await appearanceState.changeFont(path);
                        if (err != null) {
                          messengerFunc(err);
                        }
                      } else {
                        gLogger.view('Canceled choosing font');
                      }
                    },
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: SelectableText(
                      '${lang.Font}: ${appearanceState.fontPath}',
                      minLines: 1,
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 42),
              Text(lang.Thumbnail_corners),
              const SizedBox(height: 10),
              DoubleSlider(
                  initial: appearanceState.thumbnailRadius,
                  range: 18,
                  onChangeEnd: (value) {
                    appearanceState.changeThumbnailRadius(value);
                  }),
              const SizedBox(height: 20),
              Text(lang.Cover_corners),
              const SizedBox(height: 10),
              DoubleSlider(
                  initial: appearanceState.coverRadius,
                  range: 30,
                  onChangeEnd: (value) {
                    appearanceState.changeCoverRadius(value);
                  }),
              if (CONFIG.isDev()) ...[
                const SizedBox(height: 20),
                const Text(
                    'Content padding (Only wide displays) (Experimental)'),
                const SizedBox(height: 10),
                DoubleSlider(
                    initial: appearanceState.contentPaddingBaseHor,
                    range: 50,
                    onChangeEnd: (value) {
                      appearanceState.changeContentPaddingBaseHor(value);
                    }),
              ],
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  void showColorPicker(context, ColorType colorType,
      AppearanceState appearanceState, void Function(Color) onColorChanged) {
    Color pickerColor = appearanceState.colors[colorType]!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.Pick_color),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (c) => pickerColor = c,
            enableAlpha: false,
            labelTypes: const [],
          ),
        ),
        actions: <Widget>[
          StandardButton(
            lang.Save,
            onTap: () {
              onColorChanged(pickerColor);
              appearanceState.saveColors();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget itemBuilder(
      Color color, bool isCurrentColor, void Function() changeColor) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
            width: 1, color: const Color.fromARGB(255, 220, 220, 220)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: changeColor,
          borderRadius: BorderRadius.circular(50),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 110),
            opacity: isCurrentColor ? 1 : 0,
            child: Icon(Icons.done,
                color: useWhiteForeground(color) ? Colors.white : Colors.black),
          ),
        ),
      ),
    );
  }
}

class DoubleSlider extends StatefulWidget {
  const DoubleSlider({
    required this.initial,
    this.onChangeEnd,
    this.range = 18,
    super.key,
  });

  final double initial;
  final void Function(double)? onChangeEnd;
  final int range;

  @override
  State<DoubleSlider> createState() => _DoubleSliderState();
}

class _DoubleSliderState extends State<DoubleSlider> {
  double radius = 0;

  @override
  void initState() {
    super.initState();
    radius = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: radius,
      max: widget.range.toDouble(),
      min: 0,
      divisions: widget.range,
      label: radius.round().toString(),
      onChanged: (value) {
        setState(() {
          radius = value;
        });
      },
      onChangeEnd: widget.onChangeEnd,
    );
  }
}

class Pallete extends StatelessWidget {
  const Pallete(
    this.theme, {
    super.key,
  });

  final CONFIG.ThemeColors theme;

  @override
  Widget build(BuildContext context) {
    const width = 45.0;
    double calcLeft(fraction) {
      return (width - width * fraction) / 2;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Stack(
        children: [
          Positioned(
            child: Container(
              width: width,
              decoration: BoxDecoration(
                color: Color(theme.text),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            child: Container(
              margin: EdgeInsets.only(left: calcLeft(0.95)),
              width: width * 0.95,
              decoration: BoxDecoration(
                color: Color(theme.bg),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            child: Container(
              margin: EdgeInsets.only(left: calcLeft(0.65)),
              width: width * 0.65,
              decoration: BoxDecoration(
                color: Color(theme.subtitle),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            child: Container(
              margin: EdgeInsets.only(left: calcLeft(0.5)),
              width: width * 0.5,
              decoration: BoxDecoration(
                color: Color(theme.primary),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            child: Container(
              margin: EdgeInsets.only(left: calcLeft(0.25)),
              width: width * 0.25,
              decoration: BoxDecoration(
                color: Color(theme.accent),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Container(width: width * 0.3, color: Color(theme.bg)),
        ],
      ),
    );
  }
}

class ColorExample extends StatelessWidget {
  const ColorExample(
    this.color,
    this.radius, {
    super.key,
  });

  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    // logger.view('Color: $color');

    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white)),
    );
  }
}
