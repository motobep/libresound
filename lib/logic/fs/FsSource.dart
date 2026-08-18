// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:io' show File, Platform, Directory;
import 'dart:math';

import 'package:audioplayers/audioplayers.dart'
    show AudioPlayer, DeviceFileSource;
import 'package:flutter/foundation.dart' show compute;
import 'package:music_player/logic/fs/m3u.dart' as m3u;
import 'package:path/path.dart' as pathPkg;
import 'package:m4a_tags_handler/Tags.dart';
import 'package:music_player/logger.dart';
import 'package:music_player/logic/Config.dart';
import 'package:music_player/logic/DialogDescr.dart';
import 'package:music_player/logic/GroupItem.dart';
import 'package:music_player/logic/Item.dart' show IndexedItem;
import 'package:music_player/logic/JsonStorage.dart';
import 'package:music_player/logic/PageDescr.dart';
import 'package:music_player/logic/ActionButtonDescr.dart';

import 'package:music_player/consts.dart' as CONSTS;
import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logic/MusicItem.dart';
import 'package:music_player/logic/SectionDescr.dart';
import 'package:music_player/logic/Source.dart';
import 'package:music_player/logic/enums.dart';
import 'package:music_player/logic/PriorityStorage.dart';
import 'package:music_player/logic/fs/FsPlaylist.dart';
import 'package:music_player/logic/fs/cache.dart' as cache;
import 'package:music_player/logic/fs/files.dart' as fs;
import 'package:music_player/logic/fs/filesHighLevel.dart' as fsHighLevel;
import 'package:music_player/logic/fs/getMusicItems.dart'
    show getMusicItemsAsync, getMusicItemsWithCacheAsync;
import 'package:music_player/logic/KeyValue.dart';
import 'package:music_player/logic/lang.dart';
import 'package:music_player/logic/playback/Playback.dart';
import 'package:music_player/logic/playlist/Playlist.dart';
import 'package:music_player/logic/tapHandlers.dart';
import 'package:music_player/main.dart' show config;

class FsSource implements Source {
  FsSource({
    required this.sourceId,
    required this.playback,
    required this.toThisSourceAsync,
    required this.reloadFsSource,
    required this.update,
    required this.getMusicSourceDir,
    required this.getPlaylistsDir,
    required this.isMusicSourceValid,
  }) : logger = Logger(prefix: '📗 $sourceId: ');

  Playback playback;
  Future<void> Function() toThisSourceAsync;
  void Function() update;
  Future<void> Function() reloadFsSource;
  void updateCurrPage() {
    currPage.updateIdx++;
    update();
  }

  @override
  String sourceId;

  @override
  bool isShowPreloader = false;

  @override
  String errorMsg = '';

  @override
  List<String> rightControls = ['search', 'queue'];

  @override
  bool get isShowSearch {
    return navType != NavType.none; // Proposal: make more proper logic
  }

  @override
  JsonStorage propertyStorage = JsonStorage.empty();

  Directory? Function() getMusicSourceDir;
  Directory? Function() getPlaylistsDir;
  bool Function() isMusicSourceValid;

  @override
  Future<void> chooseSourceAsync() async {
    logger.blue('chooseSourceAsync');
    if (!isMusicSourceValid()) return;
    if (errorMsg != '') errorMsg = '';

    playlistHandler = PlaylistHandler(config, this);
    var newFiles = fs.fetchMusicFiles(_sourceDirPath);
    final isIdentical = _compareFilesArrays(newFiles, files);
    if (!isIdentical) {
      files = newFiles;
      await _loadMusicItemsAsync(_sourceDirPath);
    }
    // Probably can do better than this flag variable usage
    if (!_isLoadingMusicItems) {
      _checkIsMusicItemsEmpty();
    }
    loadCurrPage();
    logger.blue('End chooseSourceAsync');
  }

  @override
  Future<void> reloadAsync() async {
    if (!isMusicSourceValid()) return;
    if (errorMsg != '') errorMsg = '';

    playlistHandler = PlaylistHandler(config, this);
    files = fs.fetchMusicFiles(_sourceDirPath);
    await _loadMusicItemsAsync(_sourceDirPath);
    _checkIsMusicItemsEmpty();

    currPage.updateIdx++;
    _setShowPreloader_n(true);
    loadCurrPage();
    _setShowPreloader_n(false);
    // update();
  }

  Future<void> reinitAsync() async {
    logger.blue('reinitAsync');
    if (!isMusicSourceValid()) return;
    if (errorMsg != '') errorMsg = '';

    playlistHandler = PlaylistHandler(config, this);
    files = fs.fetchMusicFiles(_sourceDirPath);
    await _loadMusicItemsAsync(_sourceDirPath);
    _checkIsMusicItemsEmpty();

    currTabIdx = 0;
    _currPageStackName = _fsTabs[currTabIdx];
    _pageStacks.addAll(_getEmptyPageStacks());

    currPage.updateIdx++;
    _setShowPreloader_n(true);
    loadCurrPage();
    _setShowPreloader_n(false);
    // update();
    logger.blue('End reinitAsync');
  }

  void _setShowPreloader_n(bool val) {
    isShowPreloader = val;
    update();
  }

  Future<void> _setDurationWithPlayer(MusicItem mi) async {
    try {
      await _player.setSource(DeviceFileSource(mi.filepath!));
      var d = await _player.getDuration();
      if (d != null) {
        mi.duration = d;
        logger.log('Player "${mi.id}" duration: ${mi.duration}');
      } else {
        logger.error('No duration "${mi.id}"');
      }
    } catch (e) {
      logger.error('Exception getting duration for ${mi.filepath}: $e');
    }
  }

  final _player = AudioPlayer();

  Future<List<MusicItem>> _computeManyMusicItems<T>(
      List<File> files, int chunksAmount) async {
    assert(files.length >= chunksAmount, 'chunksAmount > files.length');
    final l = files.length;
    int chunkSize = l ~/ chunksAmount;

    var futures = <Future<List<MusicItem>>>[];
    for (var i = 0; i < l; i += chunkSize) {
      final end = i + chunkSize > l ? l : i + chunkSize;

      final part = files.sublist(i, end);
      final f = compute(getMusicItemsAsync, part);
      futures.add(f);
    }
    final v = await Future.wait(futures);
    List<MusicItem> all = [];
    for (var el in v) {
      all.addAll(el);
    }
    return all;
  }

  bool _isLoadingMusicItems = false;

  Future<void> _loadMusicItemsAsync(String sourceDir) async {
    logger.blue('_loadMusicItemsAsync() - $_isLoadingMusicItems');
    if (_isLoadingMusicItems) {
      logger.warn('Already loading music items. sourceDir: $sourceDir');
      return;
    }
    _isLoadingMusicItems = true;
    try {
      _allMusicItems = [];

      KeyValue cachedInfo = cache.getCachedInfo();
      // log('cachedInfo:\n$cachedInfo');
      final isolatesNumber = min(Platform.numberOfProcessors - 2, 4);

      if (cachedInfo.isNotEmpty &&
          cachedInfo.keys.contains(sourceDir) &&
          CONFIG.isCacheMusic) {
        KeyValue cachedInfoEntry = cachedInfo[sourceDir];
        _allMusicItems = await compute(
            getMusicItemsWithCacheAsync, (files, cachedInfoEntry));
        logger.log('Got music files from cache');
      } else {
        if (files.length >= isolatesNumber) {
          _allMusicItems = await _computeManyMusicItems(
              files, min(files.length, isolatesNumber));
        } else {
          _allMusicItems = await compute(getMusicItemsAsync, files);
        }
        logger.log('Got music files without cache');
      }

      // Set duration for the rest
      for (var mi in _allMusicItems) {
        if (mi.duration != const Duration(seconds: 0)) continue;
        await _setDurationWithPlayer(mi);
      }

      _allMusicItems
          .removeWhere((el) => el.duration == const Duration(seconds: 0));

      sortMusicItems();

      cache.writeCachedInfoToFile(_allMusicItems, sourceDir);
    } finally {
      _isLoadingMusicItems = false;
    }
  }

  void _checkIsMusicItemsEmpty() {
    if (_allMusicItems.isEmpty) {
      errorMsg =
          lang.phrase__no_music_in_folder.replaceFirst('{}', _sourceDirPath);
      logger.warn(errorMsg);
    }
  }

  bool deleteCachedFilesInfoConfig() {
    String fpath = config.cachedInfoFilepath;

    try {
      File(fpath).deleteSync();
    } catch (e) {
      logger.error('logger.error deleting cached info files config');
      return false;
    }
    return true;
  }

  // States
  String get _sourceDirPath {
    assert(getMusicSourceDir() != null, 'musicSourceDir is null');
    return getMusicSourceDir()!.path;
  }

  late PlaylistHandler playlistHandler;
  List<File> files = [];

  List<MusicItem> _allMusicItems = [];

  List<MusicItem> getAllMusicItems() {
    return _allMusicItems;
  }

  // @override
  List<MusicPageDescr> get _currPageStack {
    if (!_pageStacks.containsKey(_currPageStackName)) {
      throw Exception('Unexpected page key: $_currPageStackName');
    }
    return _pageStacks[_currPageStackName]!;
  }

  @override
  MusicPageDescr get currPage {
    if (!_pageStacks.containsKey(_currPageStackName)) {
      throw Exception('Unexpected page key: $_currPageStackName');
    }
    return _pageStacks[_currPageStackName]!.last;
  }

  @override
  NavType get navType {
    NavType val;
    if (_currPageStackName == FsStacks.search) {
      if (_currPageStack.length > 1) {
        val = NavType.none;
      } else {
        val = NavType.searchTabs;
      }
    } else {
      val = NavType.tabs;
    }
    return val;
  }

  @override
  int currTabIdx = 0;

  String _currPageStackName = FsStacks.all;

  late final Map<String, List<MusicPageDescr>> _pageStacks =
      _getEmptyPageStacks();

  Map<String, List<MusicPageDescr>> _getEmptyPageStacks() => {
        FsStacks.all: [
          MusicPageDescr(
            title: lang.Tracks,
            sectionlist: [
              SectionDescr(
                isBigTile: false,
                rowsCount: -1,
              )
            ],
            actionBtn: ActionBtnDescr(
              icon: IconName.shuffle,
              onTap: shuffleAction,
            ),
          )
        ],
        FsStacks.playlists: [
          MusicPageDescr(
            title: lang.Playlists,
            sectionlist: [
              SectionDescr(
                isBigTile: false,
                rowsCount: -1,
              )
            ],
            actionBtn: ActionBtnDescr(
              icon: IconName.plus,
              onTap: showCreatePlaylistDialog,
            ),
          )
        ],
        FsStacks.artists: [
          MusicPageDescr(
            title: lang.Artists,
            sectionlist: [
              SectionDescr(
                isBigTile: false,
                rowsCount: -1,
              )
            ],
          )
        ],
        FsStacks.albums: [
          MusicPageDescr(
            title: lang.Albums,
            sectionlist: [
              SectionDescr(
                isBigTile: false,
                rowsCount: -1,
              )
            ],
          )
        ],
        FsStacks.search: [
          MusicPageDescr(
            title: lang.Search,
            sectionlist: [
              SectionDescr(
                isBigTile: false,
                rowsCount: -1,
              )
            ],
          )
        ],
      };

  final _fsTabs = [
    FsTabsNames.all,
    FsTabsNames.playlists,
    FsTabsNames.artists,
    FsTabsNames.albums,
  ];

  @override
  List<(String, IconName?)> getTabs() {
    final _fsTabsForUser = [
      (lang.Tracks, IconName.house),
      (lang.Playlists, IconName.playlist),
      (lang.Artists, IconName.artist),
      (lang.Albums, IconName.vinyl_record),
    ];
    return _fsTabsForUser;
  }

  @override
  int currSearchTabIdx = 0;

  final _fsSearchTabs = FsTabsNames.list;

  String _fsSearchTabsTranslation(String tabName) {
    assert(FsTabsNames.list.contains(tabName), 'Wrong tabName: "$tabName"');
    return {
      FsTabsNames.all: lang.Tracks,
      FsTabsNames.playlists: lang.Playlists,
      FsTabsNames.artists: lang.Artists,
      FsTabsNames.albums: lang.Albums,
    }[tabName]!;
  }

  @override
  List<String> getSearchTabs() {
    return _fsSearchTabs.map((t) => _fsSearchTabsTranslation(t)).toList();
  }

  /// No side effects
  List<GroupItem> _getGroupList(String groupCategory) {
    List<String> names = [];
    PictureTag? Function(String)? coverFunc;
    logger.log('groupCategory=$groupCategory');

    switch (groupCategory) {
      case FsStacks.playlists:
        names = playlistHandler.fsPlaylist.getPlaylists();
        coverFunc = (name) =>
            playlistHandler.fsPlaylist.getPlaylistPicture(name, _allMusicItems);
        break;
      case FsStacks.albums:
        names = _getAlbums(_allMusicItems);
        coverFunc = _makeCoverFunc(_filterAlbumMusicItems);
        break;
      case FsStacks.artists:
        names = _getArtists(_allMusicItems);
        coverFunc = _makeCoverFunc(_filterArtistMusicItems);
        break;
      case FsStacks.search:
        logger.error('not implemented');
        break;
      default:
        assert(false, 'Wrong group branch: $groupCategory');
    }
    final idx = names.indexOf(CONFIG.favouritesPlaylist);
    if (idx == -1) {
      names.sort((a, b) => a.compareTo(b));
    } else {
      // Put favouritesPlaylist on top
      final v = names.removeAt(idx);
      names.sort((a, b) => a.compareTo(b));
      names.insert(0, v);
    }

    List<GroupItem> grouplist = [];
    for (var name in names) {
      String id = _formGroupId(groupCategory, name);
      final group = GroupItem(
        id,
        name,
        // Proposal: add subtitle
        picture: coverFunc?.call(name),
        sourceId: sourceId,
      );

      grouplist.add(group);
    }

    return grouplist;
  }

  PictureTag? Function(String) _makeCoverFunc(
      Iterable<MusicItem> Function(String) func) {
    return (String s) {
      var items = func(s);
      if (items.isNotEmpty) {
        return items.first.tags.picture;
      }
      return null;
    };
  }

  @override
  bool canBack() {
    return _currPageStack.length >= 2 || _currPageStackName == FsStacks.search;
  }

  @override
  bool back() {
    assert(_currPageStack.isNotEmpty, 'Category must have pages!');
    logger.log(
        '\tback() - CurrPageStackName: $_currPageStackName; Curr Tab idx: $currTabIdx');

    if (_currPageStackName == 'Search') {
      if (_currPageStack.length == 1) {
        // log('Set to $currTabName');
        _currPageStackName = _fsTabs[currTabIdx];
      } else {
        // log('removeLast()');
        _currPageStack.removeLast();
      }
      loadCurrPage();
      return false; // shouldn't pop
    }

    if (_currPageStack.length == 1) {
      return true; // should pop
    }
    _currPageStack.removeLast();
    loadCurrPage(); // Reloading because parent page might change
    return false; // don't pop
  }

  void loadCurrPage() {
    logger.warn('loadCurrPage()');
    assert(
        _currPageStack.length <= 3 ||
            _currPageStack.length == 4 && _currPageStackName == FsStacks.search,
        '_currPageStack.length=${_currPageStack.length}');
    _assertStack(_currPageStackName);

    if (currPage.isModifyPage) {
      // update();
      return;
    }

    if (_currPageStackName == FsStacks.all) {
      logger.log('load all');
      currPage.title = lang.Tracks;
      currPage.setFirstItemlist(_allMusicItems);
      /* currPage.sectionlist = [
        SectionDescr(
          header: SectionHeaderDescr(
            title: 'All',
          ),
          itemlist: _allMusicItems,
          isBigTile: false,
          rowsCount: 5,
          props: {'listType': ListType.tracklist},
        ),
        SectionDescr(
          header: SectionHeaderDescr(
            title: 'Playlists',
          ),
          itemlist: _getGroupList(FsStacks.playlists),
          isBigTile: false,
          rowsCount: 4,
        ),
        SectionDescr(
          header: SectionHeaderDescr(
            title: 'Artists',
          ),
          itemlist: _getGroupList(FsStacks.artists),
          isBigTile: true,
          rowsCount: 1,
        ),
        SectionDescr(
          header: SectionHeaderDescr(
            title: 'Albums',
          ),
          itemlist: _getGroupList(FsStacks.albums),
          isBigTile: false,
          rowsCount: 4,
        ),
      ]; */
      return;
    }

    // Grouplist
    if (_currPageStack.length == 1) {
      if (_currPageStackName == FsStacks.search) {
        _currPageStack.last =
            _search(_lastSearched, _fsSearchTabs[currSearchTabIdx]);
        return;
      }
      logger.log('load grouplist');
      currPage.title = switch (_currPageStackName) {
        FsStacks.playlists => lang.Playlists,
        FsStacks.albums => lang.Albums,
        FsStacks.artists => lang.Artists,
        // Shuold not be here
        _ => '[Should not be here]'
      };
      currPage.setFirstItemlist(_getGroupList(_currPageStackName));
      return;
    }

    // Tracklist from group
    String groupId = currPage.props['groupId']!;
    String groupName = _titleFromGroupId(groupId);
    String groupCategory = _categoryFromGroupId(groupId);
    List<MusicItem> tracklist =
        _getTracklistFromGroup(groupName, groupCategory);
    currPage.setFirstItemlist(tracklist);

    // Possible Performance issue: Extra work
    final groups = _getGroupList(groupCategory);
    GroupItem item = groups.firstWhere((el) => el.id == groupId);
    currPage.header = PageHeaderDescr(
      title: item.title,
      subtitle: '${tracklist.length} ${lang.songs}',
      picture: item.picture,
      actionBtn: ActionBtnDescr(
          text: lang.Actions,
          onTap: () {
            showItemDialog(-1, item, sectionIndex: 0);
          }),
    );

    // Shuffle action for a group
    currPage.actionBtn = ActionBtnDescr(
      icon: IconName.shuffle,
      onTap: shuffleAction,
    );

    if (_currPageStackName == FsStacks.playlists) {
      playlistHandler.loadPlaylist(groupName, tracklist);

      // Cleaning non-existing m3u entries
      List<String> filepaths =
          playlistHandler.fsPlaylist.getPlaylistFilepaths(groupName);
      List<String> notFoundMiFilepaths =
          FsPlaylist.getNotFoundMisFilesInPlaylist(filepaths, tracklist);
      if (notFoundMiFilepaths.isNotEmpty) {
        playlistHandler.savePlaylistFromTracklist(groupName, tracklist);
      }
    }
  }

  @override
  Future<void> chooseTabAsync(int tabIdx) async {
    _setShowPreloader_n(true);

    currTabIdx = tabIdx;
    _currPageStackName = _fsTabs[currTabIdx];
    loadCurrPage();

    _setShowPreloader_n(false);
  }

  @override
  Future<void> setPlaybackSourceAsync(MusicItem mi) async {
    return await playback.setFileSourceAsync(mi);
  }

  @override
  Future<void> chooseGroupAsync(GroupItem group) async {
    _setShowPreloader_n(true);
    _chooseGroupItem(group.id);
    _setShowPreloader_n(false);
  }

  void _chooseGroupItem(String groupId) {
    _assertStack(_currPageStackName);

    _currPageStack.add(MusicPageDescr(
      title: currPage.title,
      sectionlist: [
        SectionDescr(
          rowsCount: -1,
          isBigTile: false,
        )
      ],
      props: {
        'groupId': groupId,
      },
    ));
    loadCurrPage();
  }

  @override
  Future<void> searchAsync(String text) async {
    _setShowPreloader_n(true);

    logger.log('text: $text');
    String category = FsTabsNames.all;
    _currPageStackName = 'Search';
    _currPageStack.last = _search(text, category);
    _lastSearched = text;
    currSearchTabIdx = 0;

    _setShowPreloader_n(false);
  }

  @override
  Future<void> chooseSearchTabAsync(int index) async {
    _setShowPreloader_n(true);

    final name = _fsSearchTabs[index];
    assert(FsTabsNames.list.contains(name), 'Wrong search tab');
    _currPageStack.last = _search(_lastSearched, name);
    currSearchTabIdx = index;

    _setShowPreloader_n(false);
  }

  @override
  Future<List<String>?> getSuggestionsAsync(String text) async {
    if (text.length < 2) {
      return null;
    }

    List<String> suggestions = [];
    final itemsLists = [
      _allMusicItems,
      _getGroupList(FsTabsNames.playlists),
      _getGroupList(FsTabsNames.artists),
      _getGroupList(FsTabsNames.albums),
    ];
    for (var items in itemsLists) {
      for (var el in items) {
        if (_matchWord(text, el.title)) {
          suggestions.add(el.title);
        }
      }
    }
    logger.log('suggestions: $suggestions');
    return suggestions;
  }

  @override
  Duration debounceDelay = const Duration(milliseconds: 0);

  late String _lastSearched;

  /// No side effects
  MusicPageDescr _search(String text, String category) {
    logger.blue('text: $text; cat: $category');
    final musicItemsSearched =
        _allMusicItems.where((el) => _matchWord(text, el.title)).toList();
    switch (category) {
      case '':
      case FsTabsNames.all:
        return MusicPageDescr(title: lang.Search, sectionlist: [
          SectionDescr(
            itemlist: musicItemsSearched,
            isBigTile: false,
            rowsCount: -1,
          ),
        ]);
      case FsTabsNames.playlists:
        final names = musicItemsSearched.map((m) => m.title).toList();
        return MusicPageDescr(title: lang.Search, sectionlist: [
          SectionDescr(
            itemlist: _getGroupList(category).where((el) {
              if (_matchWord(text, el.title)) return true;

              String groupCategory = _categoryFromGroupId(el.id);
              List<MusicItem> tracklist =
                  _getTracklistFromGroup(el.title, groupCategory);
              return tracklist.any((mi) => names.contains(mi.title));
            }).toList(),
            isBigTile: false,
            rowsCount: -1,
          ),
        ]);
      case FsTabsNames.artists:
      case FsTabsNames.albums:
        List<String> names = [];
        if (category == FsTabsNames.albums) {
          names = musicItemsSearched.map((m) => m.album).toList();
        } else if (category == FsTabsNames.artists) {
          names = musicItemsSearched.map((m) => m.artistName).toList();
        }
        return MusicPageDescr(title: lang.Search, sectionlist: [
          SectionDescr(
            itemlist: _getGroupList(category)
                .where((el) =>
                    _matchWord(text, el.title) || names.contains(el.title))
                .toList(),
            isBigTile: false,
            rowsCount: -1,
          ),
        ]);
      default:
        throw 'Wrong search branch: $category';
    }
  }

  List<MusicItem> getTracklistFromGroup(GroupItem group) {
    String groupCategory = _categoryFromGroupId(group.id);
    return _getTracklistFromGroup(group.title, groupCategory);
  }

  /// Basically a filter of allMusicItems
  /// No side effects
  List<MusicItem> _getTracklistFromGroup(String groupName, String tabName) {
    // In Case of FsCategory.playlists music items are cloned and itemDialogDescr changed
    // In other cases there is no need for that.
    logger.log('groupName: $groupName');
    logger.log('groupTabName: $tabName');
    switch (tabName) {
      case FsStacks.playlists:
        List<String> filepaths =
            playlistHandler.fsPlaylist.getPlaylistFilepaths(groupName);
        List<MusicItem> playlistMIs = _getPlaylistMusicItems(filepaths);
        return playlistMIs;
      case FsStacks.artists:
        return _filterArtistMusicItems(groupName).toList();
      case FsStacks.albums:
        return _filterAlbumMusicItems(groupName).toList();
      default:
        throw Exception('Unexpected branch: "$tabName"');
    }
  }

  List<MusicItem> _getPlaylistMusicItems(List<String> filepaths) {
    List<MusicItem> musicItems = [];
    for (var fpath in filepaths) {
      for (var mi in _allMusicItems) {
        if (fpath == mi.filepath!) {
          musicItems.add(mi);
          break;
        }
      }
    }
    return musicItems;
  }

  Iterable<MusicItem> _filterArtistMusicItems(String artist) {
    return _allMusicItems.where((el) => el.artistName == artist);
  }

  Iterable<MusicItem> _filterAlbumMusicItems(String album) {
    return _allMusicItems.where((el) => el.album == album);
  }

  List<String> _getArtists(List<MusicItem> items) {
    return items.map((el) => el.artistName).toSet().toList();
  }

  List<String> _getAlbums(List<MusicItem> items) {
    return items.map((el) => el.album).toSet().toList();
  }

  void sortMusicItems() {
    _allMusicItems
        .sort((a, b) => a.title.toUpperCase().compareTo(b.title.toUpperCase()));
  }

  Future<void> _toArtistAsync(MusicItem mi) async {
    assert(_currPageStack.length <= 2, 'Max depth is 2');

    final artistId = _formGroupId('Artists', mi.artistName);
    logger.log('toArtist id=${artistId}');

    if (_currPageStackName == FsStacks.search) {
      var pageDescr = MusicPageDescr(title: currPage.title, sectionlist: [
        SectionDescr(
          rowsCount: -1,
          isBigTile: false,
        ),
      ], props: {
        'groupId': artistId,
      });
      if (_currPageStack.length == 2) {
        // Replacing last page
        _currPageStack.last = pageDescr;
      } else {
        // Adding page
        _currPageStack.add(pageDescr);
      }
      loadCurrPage();
      return;
    }

    int idx = _fsTabs.indexWhere((el) => el == FsStacks.artists);
    chooseTabAsync(idx);
    // If more than one level down, go up to the groups page
    if (_currPageStack.length > 1) {
      _currPageStack.removeLast();
    }
    _chooseGroupItem(artistId);
  }

  @override
  Future<List<ItemAction>> buildActionsAsync(
      IndexedItem indexedItem, int sectionIndex) async {
    List<ItemAction> itemActions = [];
    var index = indexedItem.index;
    var item = indexedItem.item;
    if (item is MusicItem) {
      var mi = item;

      itemActions = [
        ItemAction(
          text: lang.To_artist,
          icon: IconName.artist,
          callback: (dialogFuncs) async {
            dialogFuncs.closeDialog();
            await toThisSourceAsync();
            await _toArtistAsync(mi);
            update();
          },
        ),
        ItemAction(
            text: lang.Add_to_playlist,
            icon: IconName.playlist,
            callback: (DialogFuncs dialogFuncs) async {
              var arr = [mi];
              dialogFuncs.openAddToPlaylistDialog(
                tracklist: arr,
                onAdd: (String name, List<MusicItem> items) {
                  playlistHandler.addItemlistToPlaylist_n(items, name);
                },
                onNewPlaylist: (String name, List<MusicItem> items) {
                  playlistHandler.createPlaylist(name);
                  playlistHandler.addItemlistToPlaylist_n(items, name);
                },
              );
            }),
      ];

      if (!playlistHandler.fsPlaylist
              .existsPlaylist(CONFIG.favouritesPlaylist) ||
          !playlistHandler.favouritesMiExists(mi)) {
        var likeAction = ItemAction(
          text: lang.Like,
          icon: IconName.thumbs_up,
          callback: (DialogFuncs dialogFuncs) async {
            dialogFuncs.closeDialog();

            logger.blue('like');
            playlistHandler.favouritesAddMis_n([mi]);
          },
        );
        itemActions.add(likeAction);
      } else {
        var dislikeAction = ItemAction(
          text: lang.Dislike,
          icon: IconName.thumbs_down,
          callback: (DialogFuncs dialogFuncs) async {
            dialogFuncs.closeDialog();

            logger.blue('dislike');
            playlistHandler.favouritesDeleteMis_n([mi]);
          },
        );
        itemActions.add(dislikeAction);
      }

      var deleteAction = ItemAction(
        text: lang.Delete,
        icon: IconName.trash_can,
        callback: (DialogFuncs dialogFuncs) async {
          dialogFuncs.openConfirmDialog(
              heading: lang.Delete_this_song,
              onConfirm: () async {
                dialogFuncs.closeDialog();

                var path = mi.filepath;
                assert(path != null, 'Fs Music item must contain path');

                logger.log('Deleting item: $path');
                var ok = await fsHighLevel.deleteFilesAsync([path!]);
                if (ok) {
                  if (playback.queue.isNotEmpty) {
                    // FIXME: remove by queue index
                    playback.removeItemsFromQueue([index]);
                  }
                  await reloadFsSource();
                } else {
                  logger.warn('Not ok while deleting');
                }
              },
              onCancel: () async {
                logger.log('Cancel track deletion');
              });
        },
      );
      itemActions.add(deleteAction);

      if (_currPageStackName == FsStacks.playlists &&
          sectionIndex != CONSTS.queueSectionIdx) {
        final text = lang.Remove_from_playlist;
        var removeFromPlaylistAction = ItemAction(
            text: text,
            icon: IconName.remove,
            callback: (DialogFuncs dialogFuncs) async {
              dialogFuncs.closeDialog();

              playlistHandler.deleteItemFromPlaylist(index);
              loadCurrPage();
              currPage.updateIdx++;
              update();
            });
        itemActions.add(removeFromPlaylistAction);
      }
    } else if (item is GroupItem) {
      var group = item;
      itemActions = [
        ItemAction(
          text: lang.Add_to_queue,
          icon: IconName.plus,
          callback: (dialogFuncs) async {
            dialogFuncs.closeDialog();

            var tracklist = getTracklistFromGroup(group);
            playback.addAll_n(tracklist);
          },
        ),
        ItemAction(
          text: lang.Play_next,
          icon: IconName.chevron_right,
          callback: (dialogFuncs) async {
            dialogFuncs.closeDialog();

            var tracklist = getTracklistFromGroup(group);
            playback.addAllNext_n(tracklist);
          },
        ),
        ItemAction(
            text: lang.Add_to_playlist,
            icon: IconName.playlist,
            callback: (DialogFuncs dialogFuncs) async {
              var tracklist = getTracklistFromGroup(group);
              dialogFuncs.openAddToPlaylistDialog(
                tracklist: tracklist,
                onAdd: (String name, List<MusicItem> items) {
                  playlistHandler.addItemlistToPlaylist_n(items, name);
                },
                onNewPlaylist: (String name, List<MusicItem> items) {
                  playlistHandler.createPlaylist(name);
                  playlistHandler.addItemlistToPlaylist_n(items, name);
                },
              );
            }),
      ];

      if (_currPageStackName == FsStacks.playlists) {
        itemActions.add(
          ItemAction(
            text: lang.Delete_playlist,
            icon: IconName.trash_can,
            callback: (DialogFuncs dialogFuncs) async {
              dialogFuncs.closeDialog();

              String? groupId = currPage.props['groupId'];
              if (groupId == group.id) {
                logger.log('Self delete playlist id==${group.id}');
                back();
              }
              playlistHandler.deletePlaylist_n(group.title);
            },
          ),
        );
        String? groupId = currPage.props['groupId'];
        // If in Playlist page
        if (groupId != null) {
          String groupName = _titleFromGroupId(groupId);
          String groupCategory = _categoryFromGroupId(groupId);
          List<MusicItem> tracklist =
              _getTracklistFromGroup(groupName, groupCategory);

          var modifyPlaylistAction = ItemAction(
            text: lang.Modify_playlist,
            icon: IconName.pencil,
            callback: (DialogFuncs dialogFuncs) async {
              dialogFuncs.closeDialog();

              _currPageStack.add(MusicPageDescr(
                title: lang.Modify_playlist,
                header: currPage.header!.clone(),
                sectionlist: [
                  SectionDescr(
                    rowsCount: -1,
                    isBigTile: false,
                    itemlist: tracklist,
                  )
                ],
                isModifyPage: true,
              ));
              loadCurrPage();
              update();
            },
          );
          itemActions.add(modifyPlaylistAction);
        }
      }
    }
    return itemActions;
  }

  @override
  Future<List<ItemAction>> buildMultiActionsAsync(
      Map<String, List<IndexedItem>> indexedItemsMap,
      void Function() cancel) async {
    logger.log('indexedItemsMap={$indexedItemsMap}');
    List<MusicItem> items = [];
    for (var e in indexedItemsMap.entries) {
      for (var el in e.value) {
        items.add(el.item as MusicItem);
      }
    }

    var toDelete = items.toSet().toList();

    List<ItemAction> itemActions = [
      ItemAction(
        text: lang.Add_to_playlist,
        icon: IconName.playlist,
        callback: (dialogFuncs) async {
          cancel();
          dialogFuncs.closeDialog();

          var arr = items;
          dialogFuncs.openAddToPlaylistDialog(
            tracklist: arr,
            onAdd: (String name, List<MusicItem> items) {
              playlistHandler.addItemlistToPlaylist_n(items, name);
            },
            onNewPlaylist: (String name, List<MusicItem> items) {
              playlistHandler.createPlaylist(name);
              playlistHandler.addItemlistToPlaylist_n(items, name);
            },
          );
        },
      ),
      ItemAction(
        text: lang.Delete,
        icon: IconName.trash_can,
        callback: (dialogFuncs) async {
          logger.blue('delete');
          dialogFuncs.openConfirmDialog(
              heading:
                  '${lang.Delete_these_songs} (${toDelete.length}) [ ${items.length} ]',
              onConfirm: () async {
                cancel();
                dialogFuncs.closeDialog();
                List<String> paths = toDelete.map((mi) {
                  assert(
                      mi.filepath != null, 'Fs Music item must contain path');
                  return mi.filepath!;
                }).toList();
                logger.log('Deleting items: $paths');
                var ok = await fsHighLevel.deleteFilesAsync(paths);
                if (!ok) {
                  logger.warn('Not ok while deleting $paths');
                }
                // FIXME: remove queue indexed items
                var queueList = indexedItemsMap[CONSTS.queueSectionIdx];
                if (queueList != null) {
                  // remove items from queue
                  final indicesDecending = queueList
                      .map((el) => el.index)
                      .toList()
                      .reversed
                      .toList();
                  playback.removeItemsFromQueue(indicesDecending);
                }
                await reloadFsSource();
              },
              onCancel: () async {
                logger.log('Cancel track deletion');
              });
        },
      ),
    ];
    return itemActions;
  }

  @override
  Future<bool> seekAsync(int milliseconds) async => false;

  @override
  Future<void> triggerEventAsync(String event, Map args) async {
    if (event == 'ModifyPlaylistEnd') {
      // logger.log('Handling. Args: $args');
      final title = args['title'];
      final itemlist = args['itemlist'];

      final l = _currPageStack.length;
      final prevPage = _currPageStack[l - 2];
      final prevTitle = prevPage.header!.title;
      // log(prevTitle);

      final p = Playlist(title, itemlist);
      playlistHandler.savePlaylist(p, prevTitle: prevTitle);

      prevPage.props['groupId'] = _formGroupId('Playlists', title);

      back();
      update();
    } else if (event == 'TapArtistTitle') {
      await toThisSourceAsync();
      await _toArtistAsync(args['musicItem']);
      update();
    }
  }

  String _formGroupId(String prefix, String title) {
    return '${prefix}__$title';
  }

  String _titleFromGroupId(String groupId) {
    return groupId.split('__').sublist(1).join('__');
  }

  String _categoryFromGroupId(String groupId) {
    return groupId.split('__')[0];
  }

  void _assertStack(String name) {
    assert(FsStacks.list.contains(name), 'Wrong stack: $name');
  }

  Logger logger;
}

bool _compareFilesArrays(List<File> a, List<File> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i].path != b[i].path) return false;
  }
  return true;
}

class PlaylistHandler {
  PlaylistHandler(Config config, this.fsSource)
      : fsPlaylist = FsPlaylist(fsSource.getPlaylistsDir()!.path),
        updateCurrPage = fsSource.updateCurrPage,
        _loadCurrPage = fsSource.loadCurrPage,
        _recentPlaylistsStorage = PriorityStorage(
            'recentPlaylistsNames', CONFIG.maxRecentPlaylistsLength, config) {
    _recentPlaylistsStorage.load();

    // gLogger.debug('PlaylistHandler constructor');

    // Part bellow basically only needed for Android
    var sourceDir = fsSource.getMusicSourceDir()!;
    if (sourceDir.absolute.path == fsSource.getPlaylistsDir()?.absolute.path) {
      gLogger.log(sourceDir.absolute.path);
      gLogger.log(fsSource.getPlaylistsDir()?.absolute.path);
      gLogger.log('music dir == playlists dir. Returning');
      return;
    }

    // TODO: make it not automatic
    var entities = sourceDir.listSync();
    List<String> externalPlaylistsPaths = [];
    gLogger.log('Getting external playlists');
    for (var entity in entities) {
      if (entity is File && entity.path.endsWith('.m3u')) {
        // gLogger.log('ent: ${entity.path}');
        externalPlaylistsPaths.add(entity.path);
      }
    }

    String playlistsDirPath = fsPlaylist.playlistsDirPath;
    final playlistsDir = Directory(playlistsDirPath);
    assert(playlistsDir.existsSync(),
        'playlistsDir "$playlistsDirPath" doesn\'t exist');

    String indexPath = config.ignorePlaylistsIndexFilepath;
    gLogger.log('indexPath: $indexPath');
    File ignoreIndexFile = File(indexPath);
    gLogger.log(
        'ignoreIndexFile (${ignoreIndexFile.path}): ${ignoreIndexFile.existsSync()}');
    try {
      ignoreIndex = JsonStorage(indexPath);
      List<String> ignoreArr =
          (ignoreIndex!.getProperty('ignore') ?? []).cast<String>();
      // Copy external file to playlists folder

      String musicDirRelativeToPlaylistsDir =
          pathPkg.relative(sourceDir.path, from: playlistsDirPath);
      gLogger
          .debug('playlistsDirPathRelative: $musicDirRelativeToPlaylistsDir');
      for (var p in externalPlaylistsPaths) {
        try {
          String filename = pathPkg.basename(p);
          if (ignoreArr.contains(filename)) {
            continue;
          }
          // TODO: test check
          var f = File('$playlistsDirPath/$filename');
          final fileToCopy = CONFIG.fileSystem.file(p);
          if (!f.existsSync()) {
            String contents = fileToCopy.readAsStringSync();
            var (newContents, err) =
                m3u.prefixM3uPaths(contents, musicDirRelativeToPlaylistsDir);
            if (err != null) {
              gLogger.exception('Failed prefixing', err);
              continue;
            }
            f.writeAsString(newContents);
          }
        } catch (e, s) {
          gLogger.exception('index.json in loop', e, s);
          continue;
        }
      }
    } catch (e, s) {
      gLogger.exception('ignore_shared_playlists', e, s);
    }
  }

  JsonStorage? ignoreIndex;

  // States
  final FsSource fsSource;
  final FsPlaylist fsPlaylist;
  Playlist? _currPlaylist;
  final PriorityStorage _recentPlaylistsStorage;
  final void Function() updateCurrPage;
  final void Function() _loadCurrPage;

  List<(String, PictureTag?)> getRecentPlaylistsNamesWithPictures() {
    Set<String> it = _recentPlaylistsStorage.value.toSet();
    Set<String> other = fsPlaylist.getPlaylists().toSet();
    Set<String> left = it.intersection(other);
    Set<String> right = other.difference(it);
    final playlists = left.toList() + right.toList();
    return playlists
        .where((p) => p != CONFIG.favouritesPlaylist)
        .map((p) =>
            (p, fsPlaylist.getPlaylistPicture(p, fsSource._allMusicItems)))
        .toList();
  }

  void loadPlaylist(String name, List<MusicItem> musicItems) {
    _currPlaylist = Playlist(name, musicItems);
  }

  /// Modifies fs playlist
  void createPlaylist_n(String name) {
    fsPlaylist.createPlaylist(name);
    _loadCurrPage();
    updateCurrPage();

    _whenModified(name);
  }

  /// Modifies fs playlist
  void createPlaylist(String name) {
    fsPlaylist.createPlaylist(name);

    _whenModified(name);
  }

  /// Modifies fs playlist
  void deletePlaylist_n(String name) {
    fsPlaylist.deletePlaylist(name);
    // TODO: test check. make others
    _loadCurrPage();
    updateCurrPage();

    _whenModified(name);
  }

  bool favouritesMiExists(MusicItem mi) {
    List<String> filepaths =
        fsPlaylist.getPlaylistFilepaths(CONFIG.favouritesPlaylist);
    return filepaths.contains(mi.filepath!);
  }

  /// Modifies fs playlist
  void favouritesAddMis_n(List<MusicItem> items) {
    String name = CONFIG.favouritesPlaylist;
    if (!fsPlaylist.existsPlaylist(name)) {
      fsPlaylist.createPlaylist(name);
    }
    addItemlistToPlaylist_n(items, name);

    _whenModified(name);
  }

  /// Modifies fs playlist
  void favouritesDeleteMis_n(List<MusicItem> mis) {
    String name = CONFIG.favouritesPlaylist;
    assert(fsPlaylist.existsPlaylist(name), 'Playlist "$name" must exist');
    fsPlaylist.removeFromPlaylist(name, mis);
    _loadCurrPage();
    updateCurrPage();

    _whenModified(name);
  }

  /// Modifies fs playlist
  void addItemlistToPlaylist_n(List<MusicItem> items, String name) {
    _recentPlaylistsStorage.addAndSave(name);
    fsPlaylist.addToPlaylist(name, items);
    if (name == _currPlaylist?.name) {
      _currPlaylist?.addItemList(items);
      updateCurrPage();
    }
    _loadCurrPage();
    updateCurrPage();

    _whenModified(name);
  }

  void deleteItemFromPlaylist(int index) {
    _currPlaylist?.deleteItem(index);
    savePlaylist(_currPlaylist!);
  }

  /// Modifies fs playlist
  void savePlaylist(Playlist playlist, {String? prevTitle}) {
    // Delete old name
    if (prevTitle != null) {
      if (!fsPlaylist.deletePlaylist(prevTitle)) {
        gLogger.error('Playlist: $prevTitle couldn\'t be deleted');
        return;
      }
    }

    fsPlaylist.savePlaylist(playlist.name, playlist.items.cast<MusicItem>());
    _whenModified(playlist.name);
  }

  /// Modifies fs playlist
  void savePlaylistFromTracklist(String name, List<MusicItem> tracklist) {
    fsPlaylist.savePlaylist(name, tracklist);
    _whenModified(name);
  }

  void _whenModified(String name) {
    gLogger.debug('_whenModified($name)');
    try {
      if (ignoreIndex == null) {
        if (Platform.isAndroid) {
          gLogger.error('No ignore playlists index file');
        } else {
          gLogger.log('No ignore playlists index file');
        }
        return;
      }

      String filename = '$name.m3u';
      List<String> ignoreArr =
          (ignoreIndex!.getProperty('ignore') ?? []).cast<String>();

      if (ignoreArr.contains(filename)) {
        gLogger.log('_whenModified: already got $filename');
        return;
      }

      // Add unique
      var s = ignoreArr.toSet();
      s.add(filename);
      var newArr = s.toList()..sort();

      ignoreIndex!.saveProperty('ignore', newArr);
    } catch (e, s) {
      gLogger.exception('_whenModified', e, s);
    }
  }
}

bool _matchWord(String needle, String haystack) {
  // String reStr = r'((\s|^|\w\W)' + RegExp.escape(needle) + r'(\s|$|\W\w))';
  String reStr = RegExp.escape(needle);
  var re = RegExp(reStr, caseSensitive: false);
  return re.hasMatch(haystack);
}
