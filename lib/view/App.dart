import 'dart:io' show Platform;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:music_player/logger.dart' show gLogger;
import 'package:music_player/states/SelectionState.dart';
import 'package:provider/provider.dart';

import 'package:music_player/states/AppState.dart';
import 'package:music_player/states/AppearanceState.dart';
import 'package:music_player/states/DownloadsState.dart';
import 'package:music_player/states/NetworkState.dart';
import 'package:music_player/states/PlaybackState.dart';
import 'package:music_player/states/FocusState.dart';

import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/main.dart' show config;
import 'package:music_player/logic/KeyboardHandler.dart';
import 'package:music_player/logic/bindings/BindingsHandler.dart';
import 'package:music_player/logic/PluginManager.dart';
import 'package:music_player/logic/audioNotificationHandler.dart';

import 'package:music_player/view/pages/HomePage.dart' show HomePage;

class App extends StatefulWidget {
  const App(this.audioHandler, {super.key});

  final MyAudioHandler? audioHandler;

  @override
  State<App> createState() => _AppState();
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FocusNode searchFocusNode = FocusNode();

final KeyboardHandler keyboardHandler = KeyboardHandler();
final BindingsHandler bindingsHandler =
    BindingsHandler(config.keyMappingsFilepath);

EdgeInsets gPadding = const EdgeInsets.only();

class _AppState extends State<App> with WidgetsBindingObserver {
  late List<ChangeNotifierProvider<ChangeNotifier>> providers;

  @override
  void initState() {
    // gLogger.log('_AppState initState');

    DownloadsState downloadsState = DownloadsState();
    PlaybackState playbackState =
        PlaybackState(widget.audioHandler, downloadsState);
    final pluginManager = PluginManager(config, downloadsState, playbackState);

    AppState appState = AppState(config, playbackState.playback, pluginManager);
    NetworkState networkState =
        NetworkState(config, reloadFsSource: appState.reloadFsSource)
          ..tryInit();

    AppearanceState appearanceState =
        AppearanceState(config, appState, playbackState.playback);

    List<ChangeNotifierProvider<ChangeNotifier>> optional = [];

    FocusManagerState focusState = FocusManagerState(
        keyboardHandler: keyboardHandler,
        appState: appState,
        playback: playbackState.playback);

    SelectionState selectionState = SelectionState();

    final isEnabled = (Platform.isLinux || Platform.isWindows);
    focusState.init(isEnabled: isEnabled);

    optional.add(
        ChangeNotifierProvider<FocusManagerState>(create: (_) => focusState));

    providers = [
          ChangeNotifierProvider<AppState>(create: (_) => appState),
          ChangeNotifierProvider<AppearanceState>(
              create: (_) => appearanceState),
          ChangeNotifierProvider<PlaybackState>(create: (_) => playbackState),
          ChangeNotifierProvider<NetworkState>(create: (_) => networkState),
          ChangeNotifierProvider<DownloadsState>(create: (_) => downloadsState),
          ChangeNotifierProvider<SelectionState>(create: (_) => selectionState),
        ] +
        optional;

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers,
      child: const MaterialAppThemed(),
    );
  }
}

class MaterialAppThemed extends StatelessWidget {
  const MaterialAppThemed({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    gLogger.build(runtimeType);
    AppearanceState appearanceState = context.watch<AppearanceState>();
    var colors = appearanceState.colors;
    var textTheme = TextTheme(
      titleLarge: TextStyle(color: colors[ColorType.text]),
      titleMedium: TextStyle(color: colors[ColorType.text]),
      titleSmall: TextStyle(color: colors[ColorType.subtitle]),
      bodyLarge: TextStyle(color: colors[ColorType.text]),
      bodyMedium: TextStyle(color: colors[ColorType.text]),
      bodySmall: TextStyle(color: colors[ColorType.subtitle]),
    );

    Color primary = context.select<AppearanceState, Color>(
        (appearanceState) => colors[ColorType.primary]!);
    Color inactive = context.select<AppearanceState, Color>(
        (appearanceState) => appearanceState.inactiveTrackColor());

    final shortcuts = {...WidgetsApp.defaultShortcuts};
    shortcuts.remove(const SingleActivator(LogicalKeyboardKey.tab));
    shortcuts
        .remove(const SingleActivator(LogicalKeyboardKey.tab, shift: true));
    shortcuts.remove(const SingleActivator(LogicalKeyboardKey.arrowLeft));
    shortcuts.remove(const SingleActivator(LogicalKeyboardKey.arrowRight));
    shortcuts.remove(const SingleActivator(LogicalKeyboardKey.arrowDown));
    shortcuts.remove(const SingleActivator(LogicalKeyboardKey.arrowUp));

    return MaterialApp(
      title: 'LibreSound',
      shortcuts: shortcuts,
      scrollBehavior: CONFIG.isDev()
          ? const MaterialScrollBehavior()
              .copyWith(dragDevices: PointerDeviceKind.values.toSet())
          : null,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        visualDensity: const VisualDensity(),
      ),
      themeAnimationDuration: const Duration(seconds: 0),
      darkTheme: ThemeData(
        fontFamily: appearanceState.fontPath,
        fontFamilyFallback: const [CONFIG.fontFamilyDefault, 'Lato', 'Arial'],
        scrollbarTheme: ScrollbarThemeData(
            thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.dragged)) {
            return appearanceState.inactiveTrackColor();
          }
          return appearanceState.chosenTabColor();
        })),
        primaryColor: primary,
        hoverColor: appearanceState.hoverColor(),
        highlightColor: appearanceState.focusColor(),
        focusColor: appearanceState.focusColor(),
        listTileTheme: ListTileThemeData(
          // selectedColor: Colors.redAccent,
          // selectedTileColor: Colors.redAccent,
          titleTextStyle: TextStyle(
            color: colors[ColorType.text]!,
            fontSize: 16,
            fontFamily: appearanceState.fontPath,
          ),
          subtitleTextStyle: TextStyle(
            color: colors[ColorType.subtitle]!,
            fontFamily: appearanceState.fontPath,
            height: 1.35,
          ),
        ),
        dialogTheme: DialogTheme.of(context).copyWith(
          titleTextStyle: TextStyle(
            color: colors[ColorType.text]!,
            fontFamily: appearanceState.fontPath,
            fontSize: 20,
          ),
          backgroundColor: colors[ColorType.bg],
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(5.0))),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: TextButton.styleFrom(
            overlayColor: WidgetStateColor.resolveWith(
                (_) => appearanceState.hoverColor()),
            enabledMouseCursor: SystemMouseCursors.click,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            iconColor: colors[ColorType.primary],
            foregroundColor: colors[ColorType.primary],
            overlayColor: WidgetStateColor.resolveWith(
                (_) => appearanceState.hoverColor()),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            enabledMouseCursor: SystemMouseCursors.click,
          ),
        ),
        sliderTheme: SliderTheme.of(context).copyWith(
          thumbColor: primary,
          activeTrackColor: primary,
          activeTickMarkColor: primary,
          secondaryActiveTrackColor: primary,
          inactiveTrackColor: inactive,
          inactiveTickMarkColor: inactive,
          trackShape: const RectangularSliderTrackShape(),
          trackHeight: 2.0,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 0.0),
        ),
        checkboxTheme: CheckboxTheme.of(context).copyWith(
          checkColor: WidgetStateProperty.all(primary),
          fillColor: WidgetStateProperty.all(Colors.transparent),
          side: WidgetStateBorderSide.resolveWith((Set<WidgetState> states) {
            return BorderSide(
              color: colors[ColorType.text]!,
              width: 1.0,
            );
          }),
        ),
        textTheme: textTheme,
        iconTheme: IconThemeData(
          color: colors[ColorType.primary],
        ),
        colorScheme: ColorScheme.dark(
          primary: primary,
          onSurface: colors[ColorType.text]!,
          secondary: colors[ColorType.subtitle]!,
          surface: colors[ColorType.bg]!,
          tertiary: colors[ColorType.accent]!,
        ),
        brightness: Brightness.dark,
        scaffoldBackgroundColor: colors[ColorType.bg],
        cardColor: colors[ColorType.bg],
        appBarTheme: AppBarTheme(
          backgroundColor: colors[ColorType.bg],
          foregroundColor: colors[ColorType.primary],
          toolbarHeight: 54,
          scrolledUnderElevation: 0,
        ),
        visualDensity: VisualDensity.compact,
      ),
      themeMode: ThemeMode.dark,
      home: const HomePage(),
      navigatorKey: navigatorKey,
    );
  }
}
