import 'dart:io';
import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart'
    show
        Brightness,
        ChangeNotifier,
        Color,
        ColorScheme,
        Colors,
        DynamicSchemeVariant,
        Image;
import 'package:m4a_tags_handler/Tags.dart';

import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logger.dart';
import 'package:music_player/logic/Config.dart';
import 'package:music_player/logic/Debouncer.dart';
import 'package:music_player/logic/EventRegistrar.dart';
import 'package:music_player/logic/enums.dart';
import 'package:music_player/logic/playback/Playback.dart';
import 'package:music_player/logic/utils.dart' as utils;
import 'package:music_player/logic/lang.dart' as language;
import 'package:music_player/states/AppState.dart';

enum ColorType {
  bg,
  primary,
  text,
  subtitle,
  accent,
}

class AppearanceState extends ChangeNotifier {
  Config config;

  Map<ColorType, Color> colors = {
    ColorType.bg: Color(CONFIG.defaultTheme.bg),
    ColorType.primary: Color(CONFIG.defaultTheme.primary),
    ColorType.text: Color(CONFIG.defaultTheme.text),
    ColorType.subtitle: Color(CONFIG.defaultTheme.subtitle),
    ColorType.accent: Color(CONFIG.defaultTheme.accent),
  };
  AmbientMode ambientMode = AmbientMode.off;
  String fontPath = CONFIG.fontFamilyDefault;
  double thumbnailRadius = 4;
  double coverRadius = 10;
  double contentPaddingBaseHor = CONFIG.defaultContentPaddingBaseHor;

  final AppState appState;
  final Playback playback;

  language.Lang get lang {
    return language.lang;
  }

  /// Notifies
  AppearanceState(this.config, this.appState, this.playback) : super() {
    // Change ambient on music item change
    playback.queue.onCurrIdxChange = onMusicItemChange;
    appState.onSheetControlsToggle = onSheetControlsToggle;

    setColors();
    _setLang();
    var ambientModeJson = config.getProperty('ambientMode');
    if (ambientModeJson != null) {
      ambientMode = AmbientMode.fromJson(ambientModeJson);
    }
    thumbnailRadius = _getPropWithWarn('thumbnailRadius') ?? thumbnailRadius;
    coverRadius = _getPropWithWarn('coverRadius') ?? coverRadius;
    contentPaddingBaseHor =
        _getPropWithWarn('contentPaddingBaseHor') ?? contentPaddingBaseHor;
    loadFont();

    // TODO: think about content padding
    /* if (CONFIG.isDev()) {
      appState.addListener(() {
        logger.debug('appState update');
        if (appState.isWide) {
          contentPaddingBaseHor = _getPropWithWarn('contentPaddingBaseHor') ??
              contentPaddingBaseHor;
        } else {
          contentPaddingBaseHor = 0;
        }
      });
    } */
  }

  void setColors() {
    var json_colors = config.getProperty('colors');
    if (json_colors == null) return;

    try {
      colors = _colorsFromJson(json_colors);
    } catch (e) {
      logger.warn('AppearanceState Error: $e');
    }
  }

  /// Notifies
  void setLang(language.Lang lang) {
    language.lang = lang;
    config.saveProperty('language', lang.type_);
    notifyListeners();
  }

  void _setLang() {
    String? langProp = config.getProperty('language');
    logger.debug('langProp: $langProp');
    if (langProp != null) {
      if (langProp == 'russian') {
        language.lang = language.RuLang();
      } else if (langProp == 'english') {
        language.lang = language.EnLang();
      }
    } else {
      final String defaultLocale = Platform.localeName;
      logger.warn('defaultLocale: $defaultLocale');
      if (defaultLocale.startsWith('ru')) {
        language.lang = language.RuLang();
      }
    }
  }

  /// Notifies
  Future<String?> loadFont() async {
    var prop = config.getProperty('fontPath');
    if (prop == null) {
      var err = 'Using default font: "$fontPath"';
      logger.debug(err, 'yellow');
      return err;
    }
    fontPath = prop;
    return changeFont(fontPath);
  }

  /// Notifies
  void changeTheme(CONFIG.ThemeColors theme) {
    colors = {
      ColorType.bg: Color(theme.bg),
      ColorType.primary: Color(theme.primary),
      ColorType.text: Color(theme.text),
      ColorType.subtitle: Color(theme.subtitle),
      ColorType.accent: Color(theme.accent),
    };
    notifyListeners();

    saveColors();
  }

  Color queueBtnColor() {
    return lerpBgColor(0.04);
  }

  Color inactiveTrackColor() {
    return lerpBgColor(0.15);
  }

  Color chosenTabColor() {
    return lerpBgColor(0.05);
  }

  Color separatorColor() {
    return lerpBgColor(0.1);
  }

  Color buttonColor() {
    return lerpBgColor(0.08);
  }

  Color lerpBgColor(double val) {
    return Color.lerp(colors[ColorType.bg], _getReverseThemeColor(), val)!;
  }

  Color _getReverseThemeColor() {
    if (_idDarkBg()) {
      return Colors.white;
    } else {
      return Colors.black;
    }
  }

  bool _idDarkBg() {
    return isDark(colors[ColorType.bg]!);
  }

  Color hoverColor() {
    if (_idDarkBg()) {
      return const Color(0x09ffffff);
    } else {
      return const Color(0x09000000);
    }
  }

  Color focusColor() {
    return lerpBgColor(0.08);
  }

  Color focusSuggestionColor() {
    return lerpBgColor(0.12);
  }

  /// Notifies
  void changeColor_n(ColorType ct, Color color) {
    changeColor(ct, color);
    notifyListeners();
  }

  void changeColor(ColorType ct, Color color) {
    // logger.log('color $ct: $color');
    colors[ct] = color;
  }

  bool saveColors() {
    Map<String, int> clrs =
        // ignore: deprecated_member_use
        colors.map((key, value) => MapEntry(key.name, value.value));
    return config.saveProperty('colors', clrs);
  }

  CONFIG.CustomThemeColors? getCustomTheme() {
    var json = config.getProperty('custom_palette');
    if (json == null) return null;

    Map<String, int> clrs = Map<String, int>.from(json);
    return CONFIG.CustomThemeColors(
      bg: clrs[ColorType.bg.name]!,
      primary: clrs[ColorType.primary.name]!,
      text: clrs[ColorType.text.name]!,
      subtitle: clrs[ColorType.subtitle.name]!,
      accent: clrs[ColorType.accent.name]!,
    );
  }

  bool saveCustomPalette() {
    Map<String, int> clrs =
        // ignore: deprecated_member_use
        colors.map((key, value) => MapEntry(key.name, value.value));
    bool ok = config.saveProperty('custom_palette', clrs);
    notifyListeners();
    return ok;
  }

  // Fonts

  /// Notifies
  Future<String?> changeFont(String fontPath) async {
    var err = await utils.loadFont(fontPath, fontPath);
    if (err == null) {
      this.fontPath = fontPath;
      notifyListeners();

      config.saveProperty('fontPath', fontPath);
    }

    return err;
  }

  /// Notifies
  void resetFont() {
    fontPath = CONFIG.fontFamilyDefault;
    config.saveProperty('fontPath', null);
    notifyListeners();
  }

  // Image radius

  /// Notifies
  void changeThumbnailRadius(double radius) {
    thumbnailRadius = radius;
    notifyListeners();
    config.saveProperty('thumbnailRadius', thumbnailRadius);
  }

  void changeCoverRadius(double radius) {
    coverRadius = radius;
    notifyListeners();
    config.saveProperty('coverRadius', coverRadius);
  }

  void changeContentPaddingBaseHor(double v) {
    contentPaddingBaseHor = v;
    notifyListeners();
    config.saveProperty('contentPaddingBaseHor', contentPaddingBaseHor);
  }

  // Ambient
  void onMusicItemChange(int index) {
    logger.log('onMusicItemChange');
    if (ambientMode == AmbientMode.all ||
        ambientMode == AmbientMode.playback &&
            appState.controlsSheetOpenDegree == OpenDegree.opened) {
      final mi = playback.getCurrentMusicItem();
      _debouncer.run(() => _setAmbientTheme_n(mi.tags.picture));
    }
    for (var l in eventRegistrar.musicItemChangeListeners) {
      l({'index': index});
    }
  }

  void onSheetControlsToggle(OpenDegree degree) {
    logger.debug('onSheetControlsToggle');
    if (ambientMode == AmbientMode.playback) {
      if (degree == OpenDegree.opened) {
        logger.log('opened');
        final mi = playback.getCurrentMusicItem();
        _setAmbientTheme_n(mi.tags.picture);
      } else if (degree == OpenDegree.closed) {
        logger.log('closed');
        if (_shouldResetColors()) {
          setColors();
          update();
        }
      }
    }
  }

  void onAmbientModeChange(AmbientMode mode) {
    ambientMode = mode;
    if (mode == AmbientMode.all ||
        mode == AmbientMode.playback &&
            appState.controlsSheetOpenDegree == OpenDegree.opened) {
      final mi = playback.getCurrentMusicItem();
      _setAmbientTheme_n(mi.tags.picture);
    } else if (mode == AmbientMode.off ||
        mode == AmbientMode.playback &&
            appState.controlsSheetOpenDegree != OpenDegree.opened) {
      if (_shouldResetColors()) {
        setColors();
      }
      update();
    }
    config.saveProperty('ambientMode', ambientMode.toJson());
  }

  bool _shouldResetColors() {
    var json_colors = config.getProperty('colors');
    if (json_colors == null) return false;
    var configColors = _colorsFromJson(json_colors);
    return !mapEquals(colors, configColors);
  }

  Future<void> _setAmbientTheme_n(PictureTag? picture) async {
    var (primary, bg) = await _getPrimaryAndBackgroundColors(picture);
    if (colors[ColorType.bg] != bg || colors[ColorType.primary] != primary) {
      logger.log('_setAmbientColors');

      changeColor(ColorType.bg, bg);
      changeColor(ColorType.primary, primary);

      // After bg and primary change, check for text and subtitle
      if (isDark(colors[ColorType.text]!)) {
        const text = Color(0xFFffffff);
        changeColor(ColorType.text, text);
      }
      if (isDark(colors[ColorType.subtitle]!)) {
        const subtitle = Color(0xFFbbbbbb);
        changeColor(ColorType.subtitle, subtitle);
      }

      logger.log('_setAmbientTheme_n update');
      update();
    }
  }

  Future<(Color, Color)> _getPrimaryAndBackgroundColors(
      PictureTag? picture) async {
    if (picture != null) {
      final img = Image.memory(picture.bytes);
      final v = await ColorScheme.fromImageProvider(
        contrastLevel: CONFIG.dynamicThemeContrastLevel,
        provider: img.image,
        brightness: Brightness.dark,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      );
      return (v.secondary, v.onSecondary);
    } else {
      return (Colors.white, Colors.grey[850]!);
    }
  }

  static final _debouncer = Debouncer(delay: CONFIG.carouselAnimationDuration);

  void update() {
    notifyListeners();
  }

  dynamic _getPropWithWarn(String key) {
    var prop = config.getProperty(key);
    if (prop == null) logger.warn('No $key in config');
    return prop;
  }

  static final Logger logger = Logger(prefix: '🌺 AppearanceState: ');
}

bool isDark(Color color) {
  double grayscale =
      // ignore: deprecated_member_use
      (0.299 * color.red) + (0.587 * color.green) + (0.114 * color.blue);
  return grayscale < 128;
}

Map<ColorType, Color> _colorsFromJson(Map json_colors) {
  Map<String, int> clrs = Map<String, int>.from(json_colors);
  return clrs.map(
      (key, value) => MapEntry(ColorType.values.byName(key), Color(value)));
}
