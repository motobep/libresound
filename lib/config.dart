import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:music_player/logic/enums.dart' show LogLevel;

const String fsSourceId = 'FsSource';
const String tempFsSourceId = 'TempFsSource';

const VersionMode mode = String.fromEnvironment('build_mode') == 'prod'
    ? VersionMode.prod
    : VersionMode.dev;
const LogLevel logLevel = LogLevel.dev;
const bool isLogToFile = true;
const bool isLogDebug = false;
const bool isLogTrace = false;
const bool isLogView = false;
const bool isLogBuild = false;
const int maxLogFileSize = 50 * 1024 * 1024; // 50 mb

const bool isThrottle = false;

const version = '1.0.1';
const buildDatetime = String.fromEnvironment('datetime');
const buildMode = String.fromEnvironment('build_mode');

const String build = '$version $buildDatetime $buildMode';
const String buildVerbose =
    'Version: $version; Datetime: $buildDatetime; Mode: $buildMode.';

const String cliMusicDir = String.fromEnvironment('music_dir');

const String devIP = '192.168.0.163';
const String devBroadcastIP = '192.168.0.255';
const int udpPort = 8085;
const int wsServerPort = 8090;
const int wsClientPort = 8091;

const int udpBroadcastDelayMs = 80;
const int udpBroadcastExpirationMs = udpBroadcastDelayMs * 10;

const int udpPairRequestDelayMs = 40;
const int udpPairRequestExpirationMs = udpPairRequestDelayMs * 10;

const String multicastIp = '224.0.0.251';
// const String multicastIp = '224.0.1.42';

enum VersionMode { dev, prod }

bool isProd() {
  return mode == VersionMode.prod;
}

bool isDev() {
  return mode == VersionMode.dev;
}

bool isCacheMusic = true;
// bool isCacheMusic = false;

bool isMemoryFs = false;
final fileSystem = isMemoryFs ? MemoryFileSystem() : const LocalFileSystem();

const bool isUseWsServer = String.fromEnvironment('is_use_ws_server') == 'true';

const String fontFamilyDefault = 'Roboto';

abstract class ThemeColors {
  final int bg = 0;
  final int primary = 0;
  final int text = 0;
  final int subtitle = 0;
  final int accent = 0;
}

// ignore_for_file: annotate_overrides
class DarkThemeColors implements ThemeColors {
  const DarkThemeColors();

  final int bg = 0xFF202023;
  final int primary = 0xFFffffff; // 0xFF3388ff
  final int text = 0xFFffffff;
  final int subtitle = 0xFFbbbbbb;
  final int accent = 0xFF3390ff;
}

class DraculaLikeThemeColors implements ThemeColors {
  const DraculaLikeThemeColors();

  final int bg = 0xFF282a36;
  final int primary = 0xFF50fa7b;
  final int text = 0xFFf8f8f2;
  final int subtitle = 0xFF6272a4;
  final int accent = 0xFFbd93f9;
}

class SynthwaveLikeThemeColors implements ThemeColors {
  const SynthwaveLikeThemeColors();

  final int bg = 0xFF262335;
  final int primary = 0xFFff7edb;
  final int text = 0xFFffffff;
  final int subtitle = 0xFF848bbd;
  final int accent = 0xFFff8b39;
}

class LightThemeColors implements ThemeColors {
  const LightThemeColors();

  final int bg = 0xFFf8f8f8;
  final int primary = 0xFF202023;
  final int text = 0xFF202023;
  final int subtitle = 0xFF666666;
  final int accent = 0xFF3390ff;
}

class GruvboxLikeThemeColors implements ThemeColors {
  const GruvboxLikeThemeColors();

  final int bg = 0xFFf2e5bc;
  final int primary = 0xFFc14a4a;
  final int text = 0xFFc35e0a;
  final int subtitle = 0xFF4f3829;
  final int accent = 0xFF45707a;
}

class AyuLikeThemeColors implements ThemeColors {
  const AyuLikeThemeColors();

  final int bg = 0xFF212733;
  final int primary = 0xFFFF7733;
  final int text = 0xFFD9D7CE;
  final int subtitle = 0xFF607080;
  final int accent = 0xFFF07178;
}
// class Experimental2LikeThemeColors implements ThemeColors {
//   const Experimental2LikeThemeColors();
//
//   final int bg = 0xFF231e2d;
//   final int primary = 0xFFde4371;
//   final int text = 0xFFf8f8f2;
//   final int subtitle = 0xFFbbbbbb;
//   final int accent = 0xFFF9FC88;
// }

class CustomThemeColors implements ThemeColors {
  const CustomThemeColors(
      {required this.bg,
      required this.primary,
      required this.text,
      required this.subtitle,
      required this.accent});

  final int bg;
  final int primary;
  final int text;
  final int subtitle;
  final int accent;
}

const DarkThemeColors darkThemeColors = DarkThemeColors();
const LightThemeColors lightThemeColors = LightThemeColors();
const DraculaLikeThemeColors draculaLikeThemeColors = DraculaLikeThemeColors();
const SynthwaveLikeThemeColors synthwaveLikeThemeColors =
    SynthwaveLikeThemeColors();
const GruvboxLikeThemeColors gruvboxLikeThemeColors = GruvboxLikeThemeColors();
const AyuLikeThemeColors ayuLikeThemeColors = AyuLikeThemeColors();
// const Experimental2LikeThemeColors experimental2LikeThemeColors = Experimental2LikeThemeColors();

const ThemeColors defaultTheme = draculaLikeThemeColors;

const double dynamicThemeContrastLevel = 0.68; // was 52

const int maxCachedMusicInfoEntries = 5;
const int maxRecentPlaylistsLength = 20;
const int maxRecentSearchSuggestions = 20;

const double tileVisualDendity = -1.5;
const double itemExtent = 68.0;
const double sidebarItemExtent = 58.0;
const double suggestionExtent = 52.0;

const double listViewGap = itemExtent + 50.0;

const double tileTitleFontSize = 15;
const double tileLineHeight = 1.2;

const double tabsHeight = 46;
const double bottomControlsHeight = 69;

const double drawerEdgeDragWidth = 60.0;

const listViewPadding = 110.0;

const contextMenuOptionHeight = 35.0;

const pageHeaderHeight = 150.0;

const pagePaddingHor = 12.0;
const pagePaddingVert = 15.0;

const String androidDefaultMusicDir = '/storage/emulated/0/Music';
const String androidDefaultDownloadsDir = '/storage/emulated/0/Download';

const defaultPluginsServerUrl = 'https://plugins.libresound.org/api';
const jsLibsDir = 'assets/libresound_js_libs';
const devPluginsDir = 'assets/music_player_plugins/plugins';

const String favouritesPlaylist = '__favourites__';

const carouselAnimationDuration = Duration(milliseconds: 300);
const queueAutoFocusDelay = Duration(seconds: mode == VersionMode.dev ? 4 : 60);
const scrollAnimationDuration = Duration(milliseconds: 400);

const double widthWideStart = 768;
const double heightWideStart = 500;

const mitm_proxy_url = 'http://127.0.0.1:8080';

const int promiseTimeout = mode == VersionMode.dev ? 65 : 120;
const Duration connectionTimeout =
    Duration(seconds: mode == VersionMode.dev ? 32 : 120);
const double smThumbnail = 50;

const isDisableDownloadPlugins =
    String.fromEnvironment('is_disable_download_plugins') == '1' ? true : false;
