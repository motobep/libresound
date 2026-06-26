import 'dart:io';
import 'dart:convert';

import 'package:music_player/logger.dart';
import 'package:path_provider/path_provider.dart';

import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logic/utils.dart';
import 'package:music_player/logic/fs/files.dart' as fs;
import 'package:music_player/logic/getDeviceInfo.dart';

import 'network.dart' as network;

typedef ConfigMap = Map<String, dynamic>;

class Config {
  List<NetworkInterface> _allIpInterfaces = [];
  List<String> get allIps {
    return network.interfacesToStrings(_allIpInterfaces)
      ..sort(network.ips_192_168_first);
  }

  late String deviceName;
  ConfigMap config = {};
  List<String> cliArgs = [];

  String _appDir = '';
  Directory? _musicSourceDir;

  Directory? get musicSourceDir {
    return _musicSourceDir;
  }

  String get appDir {
    return _appDir;
  }

  String get pluginsDir {
    return '$_appDir/plugins';
  }

  String get pluginsInstalledDir {
    return '$pluginsDir/installed';
  }

  String get pluginsArchivesDir {
    return '$pluginsDir/archives';
  }

  String get cachedInfoFilepath {
    return '$appDir/cached_file_info.json';
  }

  bool setMusicSourceDir(String dir) {
    _musicSourceDir = Directory(dir);
    return saveProperty('musicSourceDir', _musicSourceDir!.path);
  }

  String get configFilepath {
    return '$_appDir/config.json';
  }

  String get keyMappingsFilepath {
    return '$_appDir/keyMappings.json';
  }

  String get logFilepath {
    return '$_appDir/log.txt';
  }

  Future<void> init() async {
    // log('initConfigMap()');
    await _initConfigMap();
    // logger.log('ConfigMap: $config');
    // log('load()');
    await _load();
    logger.log('Config: ${toShortString()}');
  }

  /// Throws
  Future<void> _initConfigMap() async {
    _appDir = await _getAppDir();

    File configFile = File(configFilepath);
    if (!configFile.existsSync()) {
      _initDefaultConfigFile();
    }
    String contents = _readFile(configFilepath);
    try {
      config = jsonDecode(contents);
    } catch (e) {
      logger.log('Warning: Wrong config json');
      logger.log('INFO: Trying reinit config');
      _initDefaultConfigFile();
      config = jsonDecode(contents);
    }

    bool ok = _isConfigValid(config);
    if (!ok) {
      throw 'Exception: Invalid config';
    }
  }

  bool _isConfigValid(ConfigMap config) {
    return config.containsKey('musicSourceDir');
  }

  bool _initDefaultConfigFile() {
    logger.log('INFO: Creating default config file');
    config = {
      'musicSourceDir': '',
    };
    return _saveConfig();
  }

  Future<void> _load() async {
    await _loadMusicSourceDir();
    _handleVersionBuild();
    await updateIps();

    // Set all network interfaces
    try {
      _allIpInterfaces = await network.getAllIpV4Interfaces();
    } catch (e) {
      logger.log('Network error');
    }

    deviceName = await getDeviceName();
  }

  Future<void> _loadMusicSourceDir() async {
    // Cli Dir
    String cliDir = '';
    if (cliArgs.isNotEmpty) {
      logger.log('cliArgs isNotEmpty');
      String path = cliArgs[0];

      final dir = Directory(path);
      if (!dir.existsSync()) {
        logger.warn('cliArgs dir: Directory $dir doesn\'t exist');
      } else {
        cliDir = dir.absolute.path;
      }
    }

    // Env Dir
    const String envDir = CONFIG.cliMusicDir;
    if (envDir != '' &&
        isValidAbsolutePath(envDir) &&
        Directory(envDir).existsSync()) {
      cliDir = envDir;
    }

    if (cliDir != '') {
      logger.log('cli SOURCE_DIR=$cliDir');
      var musicDir = removeTrailingSlash(cliDir);
      setMusicSourceDir(musicDir);
      return;
    }

    // Config Dir
    String dir = config['musicSourceDir'];
    if (isValidAbsolutePath(dir) && Directory(dir).existsSync()) {
      var musicDir = removeTrailingSlash(dir);
      setMusicSourceDir(musicDir);
    } else {
      logger.log('WARN: Downloads directory is null');
      logger.log('INFO: Asking to choose music directory');
    }
  }

  void _handleVersionBuild() {
    String? build = getProperty('build');
    if (build == null) {
      saveProperty('build', CONFIG.build);
    } else {
      if (build != CONFIG.build) {
        saveProperty('build_previous', build);
        saveProperty('build', CONFIG.build);
      }
    }
  }

  Future<void> updateIps() async {
    try {
      _allIpInterfaces = await network.getAllIpV4Interfaces();
    } catch (e) {
      logger.log('Network error');
      _allIpInterfaces = [];
    }
  }

  dynamic getProperty(String propName, {dynamic orElse}) {
    return config.containsKey(propName) ? config[propName] : orElse;
  }

  /// Use only after init
  /// Returns ok
  bool saveProperty(String propName, dynamic propVal) {
    config[propName] = propVal;
    if (isWriteToConfig()) {
      return _saveConfig();
    } else {
      return true;
    }
  }

  bool _saveConfig() {
    String contents = json.encode(config);
    bool ok = fs.writeToFile(configFilepath, contents);
    if (!ok) {
      logger.log('WARN: Config file wasn\'t written');
    }
    return ok;
  }

  bool isMusicSourceDirValid() {
    return musicSourceDir != null && musicSourceDir!.existsSync();
  }

  /// Throws [MissingPlatformDirectoryException]
  Future<String> _getAppDir() async {
    Directory configDir = await getApplicationSupportDirectory();
    return configDir.path;
  }

  @override
  String toString() {
    const enc = JsonEncoder.withIndent('  ');
    final configStr = enc.convert(config);
    return '\n[\n\tMusic source directory: $musicSourceDir\n\tConfig filepath: $configFilepath.\n\tNetwork Interfaces: $_allIpInterfaces\n\tUdp Port: ${CONFIG.udpPort}\n\tPort: Device name: $deviceName\n\t\n\tConfig properties:\n\t$configStr\n]';
  }

  String toShortString() {
    return '\n[\n\tMusic source directory: $musicSourceDir\n\tConfig filepath: $configFilepath.\n\tNetwork Interfaces: $_allIpInterfaces\n\tUdp Port: ${CONFIG.udpPort}\n\tPort: Device name: $deviceName\n]';
  }

  /// Plugin helpers
  List<String> get allPluginsServerUrlList {
    return [CONFIG.defaultPluginsServerUrl] + pluginsServerUrlList;
  }

  String get pluginsServerUrl {
    return allPluginsServerUrlList[pluginsServerUrlIdx];
  }

  List<String> get pluginsServerUrlList {
    return getProperty('pluginsServerUrlList')?.cast<String>() ?? const [];
  }

  int get pluginsServerUrlIdx {
    return getProperty('pluginsServerUrlIdx') ?? 0;
  }
}

bool isWriteToConfig() {
  const String isWriteToConfigFile = String.fromEnvironment('IS_WRITE_CONFIG');
  return isWriteToConfigFile != 'false';
}

String _readFile(String filepath) {
  String contents = '';
  File configFile = File(filepath);

  try {
    contents = configFile.readAsStringSync();
  } on FileSystemException {
    logger.log('FileSystemException while reading config file');
    return '';
  } catch (e) {
    logger.log('Unexpected exception while reading music file $e');
    return '';
  }

  return contents;
}

final Logger logger = Logger(prefix: '📑 Config: ');
