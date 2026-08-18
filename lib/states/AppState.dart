import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;

import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logger.dart';
import 'package:music_player/logic/Config.dart';
import 'package:music_player/logic/DialogDescr.dart' show ItemAction;
import 'package:music_player/logic/GroupItem.dart';
import 'package:music_player/logic/MusicItem.dart';
import 'package:music_player/logic/PageDescr.dart';
import 'package:music_player/logic/PriorityStorage.dart';
import 'package:music_player/logic/enums.dart';
import 'package:music_player/logic/Source.dart';
import 'package:music_player/logic/fs/FsSource.dart';
import 'package:music_player/logic/fs/files.dart' as fs;
import 'package:music_player/logic/PluginManager.dart';
import 'package:music_player/logic/getDeviceInfo.dart';
import 'package:music_player/logic/fs/getMusicItems.dart';
import 'package:music_player/logic/lang.dart';
import 'package:music_player/logic/playback/Playback.dart';
import 'package:music_player/logic/plugins.dart' as plugins;
import 'package:music_player/logic/utils_flutter.dart' as utils_flutter;
import 'package:music_player/view/components/BottomControls.dart';
import 'package:music_player/view/pages/DraggableQueue.dart';
import 'package:music_player/view/pages/PluginsPage.dart';
import 'package:music_player/view/pages/SettingsPage.dart' show Settings;

class AppState extends ChangeNotifier {
  AppState(this.config, this.playback, this.pluginManager) : super() {
    // Init search suggestions
    searchSuggestionsStorage = PriorityStorage(
        'searchSuggestions', CONFIG.maxRecentSearchSuggestions, config);
    searchSuggestionsStorage.load();

    logger.log('Creating FsSource');
    fsSource = FsSource(
      sourceId: CONFIG.fsSourceId,
      playback: playback,
      toThisSourceAsync: () => toSource(fsSource.sourceId),
      reloadFsSource: reloadFsSource,
      update: update,
      getMusicSourceDir: () => config.musicSourceDir,
      getPlaylistsDir: () => config.playlistsDir,
      isMusicSourceValid: config.isMusicSourceDirValid,
    );
    sources[fsSource.sourceId] = fsSource;

    currentSource = sources[fsSource.sourceId]!;

    if (_isAddTempFsSource()) {
      logger.log('Creating TempFsSource');
      tempFsSource = FsSource(
        sourceId: CONFIG.tempFsSourceId,
        playback: playback,
        toThisSourceAsync: () => toSource(CONFIG.tempFsSourceId),
        reloadFsSource: reloadFsSource,
        update: update,
        getMusicSourceDir: () => config.cliDir,
        getPlaylistsDir: () => config.playlistsDir,
        isMusicSourceValid: config.isCliDirValid,
      );
      sources[tempFsSource!.sourceId] = tempFsSource!;
      currentSource = sources[tempFsSource!.sourceId]!;
    }

    logger.log('Creating directories for plugins');
    plugins.ensurePluginDirectoriesCreated(config.pluginsDir);

    playback.getSourceByMi = getSourceByMi;

    controlsSheetController.addListener(_controlsSheetListener);
    queueSheetController.addListener(_queueSheetListener);

    _initAsync();
  }

  bool _isAddTempFsSource() {
    return config.isCliDirValid() &&
        config.cliDir?.path != config.musicSourceDir?.path;
  }

  PageDescr get currPage {
    return currentSource.currPage;
  }

  MusicPageDescr get currMusicPage {
    return currentSource.currPage as MusicPageDescr;
  }

  String get headlineTitle {
    return switch (mainPage) {
      Pages.source => currentSource.currPage.title,
      Pages.settings => lang.Settings,
      Pages.appearance => lang.Appearance,
      Pages.sync => lang.Sync,
      Pages.plugins => lang.Plugins,
    };
  }

  bool isSearchToggled = false;

  Map<String, Source> sources = {};
  late Source currentSource;
  late FsSource fsSource;
  FsSource? tempFsSource;

  Playback playback;
  late PluginManager pluginManager;

  Config config;
  late PriorityStorage searchSuggestionsStorage;

  bool isSourceLoaded = false;
  double queueScrollOffset = -1.0;

  bool get isShowChooseMusicDir {
    return currentSource.sourceId == CONFIG.fsSourceId &&
        !config.isMusicSourceDirValid();
  }

  bool isAudioAccessGranted = false;
  bool get isPluginsDisclaimerRead =>
      config.getProperty('isPluginsDisclaimerRead') ?? false;
  bool get isPluginsMiniDisclaimerRead =>
      config.getProperty('isPluginsMiniDisclaimerRead') ?? false;

  bool get isShowPreloader {
    return currentSource.isShowPreloader;
  }

  bool isWide = false;
  Pages mainPage = Pages.source;
  Settings settingsPages = Settings();
  late PluginsPages pluginsPages = PluginsPages(this);

  // List<Null Function()> sidebarButtonOnTaps = [];

  List<Null Function()> getSidebarButtonOnTaps() {
    return _getSidebarPageOnTaps() + _getSidebarSourceOnTaps();
  }

  List<Null Function()> _getSidebarPageOnTaps() {
    return [
      for (var name in [
        Pages.settings,
        Pages.appearance,
        Pages.sync,
        Pages.plugins
      ])
        () {
          _pageOnTap(name);
        },
    ];
  }

  List<Null Function()> _getSidebarSourceOnTaps() {
    final sourcesIds = sources.values.map((s) => s.sourceId);
    return [
      for (var id in sourcesIds)
        () {
          _sourceOnTap(id);
        },
    ];
  }

  void _sourceOnTap(String sourceId) {
    logger.trace('${sourceId} source btn');
    changeSource(sourceId);
    _pageOnTap(Pages.source);
  }

  void _pageOnTap(Pages page) {
    logger.trace('General Page btn');
    mainPage = page;
    update();
    if (isWide == false) closeDrawer();
  }

  Future<void> reloadPlugins({loadOnlyNew = false}) async {
    final prevSourceId = currentSource.sourceId;
    sources = {};
    sources[fsSource.sourceId] = fsSource;
    if (_isAddTempFsSource() && tempFsSource != null) {
      sources[tempFsSource!.sourceId] = tempFsSource!;
    }
    await _loadPlugins(loadOnlyNew
        ? pluginManager.getNewInstalledPlugins()
        : pluginManager.getInstalledPlugins());

    final sourceId =
        sources.containsKey(prevSourceId) ? prevSourceId : fsSource.sourceId;
    await changeSource(sourceId);
    pluginManager.checkPluginVersions();

    notifyListeners();
  }

  Future<void> reloadPlugin(plugins.PluginInfo plugin) async {
    final prevSourceId = currentSource.sourceId;

    if (plugin.isSource) {
      sources.remove(plugin.id);
      logger.blue('notifyListeners');
      notifyListeners();
    }
    bool ok = await pluginManager.loadPlugin(this, plugin);
    if (ok) {
      logger.log('Plugins: ${pluginManager.sources}');

      if (plugin.isSource) {
        sources[plugin.id] = pluginManager.sources[plugin.id]!;
        if (prevSourceId == plugin.id) {
          await changeSource(plugin.id);
        }
      } else if (plugin.isLyrics) {
        hasLyrics = pluginManager.getLyricsPluginId() != '';
      }
    }
    pluginManager.checkPluginVersions();

    notifyListeners();
  }

  // FIXME: make partial reload
  Future<void> _loadPlugins(List<plugins.PluginInfo> pluginList) async {
    // Pluginlist stays the same
    pluginManager.pluginsList = pluginManager.getInstalledPlugins();

    await pluginManager.loadPlugins(this, pluginManager.pluginsList);
    logger.log('Plugins: ${pluginManager.sources}');
    sources.addAll(pluginManager.sources);
    hasLyrics = pluginManager.getLyricsPluginId() != '';
  }

  // Future<bool> tryGrantManageExternalStorage() async {
  //   bool isManageExternalStorageGranted = true;
  //   isManageExternalStorageGranted =
  //       await utils_flutter.requestManageExternalStorage();
  //   // log('Is external storage access granted: $isManageExternalStorageGranted');
  //   logger.log(
  //       'Is external storage access granted: $isManageExternalStorageGranted');
  //
  //   int sdk = await getAndroidSdkVersion();
  //   isShowGrantStorageAccess =
  //       Platform.isAndroid && sdk >= 33 && !isManageExternalStorageGranted;
  //   return isManageExternalStorageGranted;
  // }

  Future<bool> tryGrantAudioAccess() async {
    isAudioAccessGranted = await utils_flutter.requestAudioPermission();
    // log('Is audio access granted: $isAudioAccessGranted');
    logger.log('Is audio access granted: $isAudioAccessGranted');
    return isAudioAccessGranted;
  }

  /// Notifies
  Future<bool> changeSource(String sourceId) async {
    assert(sources.containsKey(sourceId),
        'Key must be in the map. Got "$sourceId"');
    currentSource = sources[sourceId]!;
    isSourceLoaded = false;
    notifyListeners();

    // Load music items
    logger.log('Source chooseSource "$sourceId"');
    await currentSource.chooseSourceAsync();

    isSourceLoaded = true;
    notifyListeners();

    return true;
  }

  void invalidateQueueScrollOffset() {
    queueScrollOffset = -1.0;
  }

  Future<bool> loadFromDirectoryAsync(String dir) async {
    bool ok = config.setDirsFromSourceDir(dir);
    if (!ok) return false;

    isSourceLoaded = false;
    notifyListeners();

    logger.log('FsSource reinitAsync');
    await fsSource.reinitAsync();

    isSourceLoaded = true;
    notifyListeners();
    return true;
  }

  void update() {
    notifyListeners();
  }

  void _initAsync() async {
    await tryGrantAudioAccess();

    // config.log(config.toString());

    if (CONFIG.isDev()) {
      // Set here source for dubugging
      await changeSource(currentSource.sourceId);
    } else {
      await changeSource(currentSource.sourceId);
    }
    await _loadPlugins(pluginManager.getInstalledPlugins());
    if (!CONFIG.isDisableDownloadPlugins &&
        config.getProperty('isAutoCheckPluginUpdates', orElse: true)) {
      await pluginManager.checkPluginUpdatesAsync();
    }

    if (config.getProperty('isWatchPluginDirs') ?? false) {
      fs.watchSubDirs(pluginManager.pluginsDir, callback: () {
        reloadPlugins();
      }, delayMs: 2000, ext: '.js');
    }

    notifyListeners();

    await _afterInit();
  }

  Future<void> _afterInit() async {
    logger.trace('_afterInit()');
    if (config.cliArgs.isNotEmpty) {
      logger.log('cliArgs isNotEmpty');
      String filepath = config.cliArgs[0];
      await _playFileFromPath(filepath);
    }
  }

  Future<void> _playFileFromPath(String path) async {
    final file = File(path);
    if (!file.existsSync()) {
      gLogger.warn('_playFileFromPath: File $file doesn\'t exist');
      return;
    }
    logger.log('exists $file');
    final fileAbsolute = file.absolute;
    logger.log('absolute $fileAbsolute');

    final list = await getMusicItemsAsync([fileAbsolute]);
    var mi = list[0];

    playback.addItemToQueue(mi);
    int lastIdx = playback.queue.length - 1;
    await playback.playByIdx_n(lastIdx);
    logger.log('played $mi');
  }

  Future<void> reloadFsSource() async {
    logger.log('FsSource reloadAsync');
    await fsSource.reloadAsync();
    notifyListeners();
  }

  Future<void> chooseTabAsync(int index) async {
    await currentSource.chooseTabAsync(index);
  }

  Future<void> chooseSearchTabAsync(int idx) async {
    await currentSource.chooseSearchTabAsync(idx);
  }

  Source getSourceByMi(MusicItem mi) {
    return sources[mi.sourceId]!;
  }

  Future<void> chooseGroupAsync(GroupItem group) async {
    await currentSource.chooseGroupAsync(group);
  }

  Future<void> triggerSourceEvent(
      String sourceId, String event, Map map) async {
    assert(sources.containsKey(sourceId),
        'Key must be in the map. Got "$sourceId"');
    logger.log('Event ($sourceId): $event');
    await sources[sourceId]!.triggerEventAsync(event, map);
  }

  bool canBack() {
    if (isDrawerOpened) return true;
    if (isEndDrawerOpened) return true;
    return switch (mainPage) {
      Pages.settings => settingsPages.canBack(),
      Pages.plugins => pluginsPages.canBack(),
      Pages.source => () {
          if (isQueueSheetOpened) return true;
          if (controlsSheetOpenDegree == OpenDegree.opened) return true;
          if (isSearchToggled) return true;
          return currentSource.canBack();
        }(),
      _ => false,
    };
  }

  late void Function() closeDrawer;
  late void Function() closeEndDrawer;

  bool back() {
    gLogger.blue('back');
    if (isDrawerOpened) {
      gLogger.blue('closeDrawer');
      closeDrawer();
      return false;
    }
    if (isEndDrawerOpened) {
      gLogger.blue('closeEndDrawer');
      closeEndDrawer();
      return false;
    }
    if (mainPage == Pages.settings) {
      bool shouldPop = settingsPages.back();
      notifyListeners();
      return shouldPop;
    }
    if (mainPage == Pages.plugins) {
      bool shouldPop = pluginsPages.back();
      notifyListeners();
      return shouldPop;
    }
    if (mainPage == Pages.source) {
      if (isQueueSheetOpened) {
        queueSheetController_animateToZero();
        return false;
      }
      if (controlsSheetOpenDegree == OpenDegree.opened) {
        controlsSheetController_animateToZero();
        return false;
      }
      if (isSearchToggled) {
        isSearchToggled = false;
        notifyListeners();
        return false;
      }
      // shouldPop == !canBack()
      // And canBack must be sync. A variable for example that's been set by js
      bool shouldPop = currentSource.back();
      notifyListeners();
      return shouldPop;
    }
    return true;
  }

  bool isDrawerOpened = false;
  bool isEndDrawerOpened = false;
  OpenDegree controlsSheetOpenDegree = OpenDegree.closed;
  bool isQueueSheetOpened = false;

  bool hasLyrics = false;
  bool isLyricsSelected = false;
  bool get isShowLyrics => hasLyrics && isLyricsSelected;

  void Function(OpenDegree)? onSheetControlsToggle;

  void _controlsSheetListener() {
    if (controlsSheetController.size + 0.001 >= maxControlsChildSize) {
      if (controlsSheetOpenDegree != OpenDegree.opened) {
        controlsSheetOpenDegree = OpenDegree.opened;
        onSheetControlsToggle?.call(controlsSheetOpenDegree);
        final mi = playback.queue.getCurrentMusicItem();
        triggerSourceEvent(mi.sourceId, 'PlaybackControlsOpen', mi.toJson());
        notifyListeners();
      }
    } else if (controlsSheetController.size - 0.001 <= minControlsChildSize) {
      if (controlsSheetOpenDegree != OpenDegree.closed) {
        logger.blue('closed');
        controlsSheetOpenDegree = OpenDegree.closed;
        onSheetControlsToggle?.call(controlsSheetOpenDegree);
        notifyListeners();
      }
    } else {
      if (controlsSheetOpenDegree != OpenDegree.middle) {
        controlsSheetOpenDegree = OpenDegree.middle;
        onSheetControlsToggle?.call(controlsSheetOpenDegree);
        WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
      }
    }
  }

  void _queueSheetListener() {
    if (queueSheetController.size + 0.001 >= maxQueuePercent) {
      if (!isQueueSheetOpened) {
        isQueueSheetOpened = true;
        notifyListeners();
      }
    } else {
      if (isQueueSheetOpened) {
        isQueueSheetOpened = false;
        notifyListeners();
      }
    }
  }

  Future<void> toSource(String sourceId) async {
    await changeSource(sourceId);
    mainPage = Pages.source;
  }

  MusicItem? findMusicItem(String id) {
    MusicItem? mi = playback.findMusicItem(id);
    if (mi != null) return mi;

    for (var s in currMusicPage.sectionlist) {
      int idx = s.itemlist.indexWhere((mi) => mi.id == id);
      if (idx != -1) {
        return s.itemlist[idx]
            as MusicItem; // WARNING: Tracklists and grouplists must have different ids
      }
    }
    return null;
  }

  void toPrevTab() {
    var cats = currentSource.getTabs();
    if (cats.isEmpty) return;

    int prev_idx = currentSource.currTabIdx - 1;
    if (prev_idx >= 0) {
      chooseTabAsync(prev_idx);
    } else {
      chooseTabAsync(cats.length - 1);
    }
  }

  void toNextTab() {
    var cats = currentSource.getTabs();
    if (cats.isEmpty) return;

    int next_idx = currentSource.currTabIdx + 1;
    if (next_idx < cats.length) {
      chooseTabAsync(next_idx);
    } else {
      chooseTabAsync(0);
    }
  }

  void toPrevSearchTab() {
    var cats = currentSource.getSearchTabs();
    if (cats.isEmpty) return;

    int prev_idx = currentSource.currSearchTabIdx - 1;
    if (prev_idx >= 0) {
      chooseSearchTabAsync(prev_idx);
    } else {
      chooseSearchTabAsync(cats.length - 1);
    }
  }

  void toNextSearchTab() {
    var cats = currentSource.getSearchTabs();
    if (cats.isEmpty) return;

    int next_idx = currentSource.currSearchTabIdx + 1;
    if (next_idx < cats.length) {
      chooseSearchTabAsync(next_idx);
    } else {
      chooseSearchTabAsync(0);
    }
  }

  List<ItemAction> getDefaultActions(List<MusicItem> items,
      [void Function()? cancel]) {
    return [
      ItemAction(
        text: lang.Add_to_queue,
        icon: IconName.plus,
        callback: (dialogFuncs) async {
          cancel?.call();
          dialogFuncs.closeDialog();
          playback.addAll_n(items);
        },
      ),
      ItemAction(
        text: lang.Play_next,
        icon: IconName.chevron_right,
        callback: (dialogFuncs) async {
          cancel?.call();
          dialogFuncs.closeDialog();
          playback.addAllNext_n(items);
        },
      ),
    ];
  }

  late final AutoplaySources autoplaySources = AutoplaySources(notifyListeners);
}

class AutoplaySources {
  AutoplaySources(this.update);
  void Function() update;

  String currentId = '-';
  List<(String, String)> names = [('-', lang.Off)];
  void setCurrent_n(String id) {
    currentId = id;
    update();
  }

  (String, String) get(String id) {
    return names.firstWhere((el) => el.$1 == id);
  }

  void add_n(String id, String name) {
    if (names.contains((id, name))) return;
    names.add((id, name));
    names = [...names]; // to update object
    if (names.length == 2) {
      currentId = id; // Autoenable first pushed autoplay source
    }
    update();
  }

  void remove_n(String id) {
    names.removeWhere((el) => el.$1 == id);
    names = [...names]; // to update object
    if (currentId == id) {
      currentId = '-';
    }
    update();
  }

  bool isShow() {
    return names.length > 1;
  }
}

final Logger logger = Logger(prefix: '📓 AppState: ');
