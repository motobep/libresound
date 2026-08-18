import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:io' show Cookie, HttpClient, Platform;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:music_player/logic/EventRegistrar.dart';
import 'package:music_player/states/AppState.dart' show AutoplaySources;
import 'package:webview_cookie_manager/webview_cookie_manager.dart'
    show WebviewCookieManager;
import 'package:webview_flutter/webview_flutter.dart'
    show
        HttpAuthRequest,
        HttpResponseError,
        JavaScriptMode,
        NavigationDecision,
        NavigationDelegate,
        NavigationRequest,
        SslAuthError,
        UrlChange,
        WebResourceError,
        WebViewController;

import 'package:m4a_tags_handler/Tags.dart';

import 'package:music_player/logger.dart';
import 'package:music_player/logic/ActionButtonDescr.dart';
import 'package:music_player/logic/Item.dart';
import 'package:music_player/logic/JsonStorage.dart';
import 'package:music_player/logic/KeyValue.dart';
import 'package:music_player/logic/MpJsRuntime.dart';
import 'package:music_player/logic/PageDescr.dart';
import 'package:music_player/logic/MusicItem.dart';
import 'package:music_player/logic/GroupItem.dart';
import 'package:music_player/logic/SectionDescr.dart';
import 'package:music_player/logic/Source.dart';
import 'package:music_player/logic/DialogDescr.dart';
import 'package:music_player/logic/fs/download_funcs.dart';
import 'package:music_player/logic/lang.dart';
import 'package:music_player/logic/network.dart' as network;
import 'package:music_player/logic/playback/Playback.dart';
import 'package:music_player/logic/playback/PlaybackQueue.dart';
import 'package:music_player/logic/tapHandlers.dart';
import 'package:music_player/logic/dialogFuncs.dart';
import 'package:music_player/logic/utils.dart' as utils;
import 'package:music_player/logic/utils_flutter.dart' as utils_flutter;
import 'package:music_player/logic/enums.dart';
import 'package:music_player/states/DownloadsState.dart';
import 'package:music_player/view/snackBarFuncs.dart';

typedef Action = (String, IconName?, Future<void> Function() callback);

bool IS_PS_TEST = false;

class PluginSource implements Source {
  PluginSource(
    this.sourceId,
    this.mpJsRuntime, {
    required this.pluginTitle,
    required this.playback,
    required this.toThisSourceAsync,
    required this.propertyStorage,
    required this.updateAppState,
    required this.updatePlaybackState,
    required this.findMusicItem,
    required this.downloadsState,
    required this.eventRegistrar,
    required this.autoplaySources,
    this.webViewController,
  });

  @override
  String sourceId;
  final String pluginMainObjectName = 'plugin';
  JsRuntimeI mpJsRuntime;
  final String pluginTitle;
  Playback playback;
  PlaybackQueue get playbackQueue {
    return playback.queue;
  }

  DownloadsState downloadsState;
  WebViewController? webViewController;

  Future<void> Function() toThisSourceAsync;

  @override
  JsonStorage propertyStorage;
  void Function() updateAppState;
  void Function() updatePlaybackState;
  MusicItem? Function(String id) findMusicItem;

  EventRegistrar eventRegistrar;
  AutoplaySources autoplaySources;
  late bool Function() isCurrentSource;

  List<dynamic> settingsControls = [];

  @override
  bool isShowPreloader = false;

  @override
  String errorMsg = '';

  @override
  List<String> rightControls = ['search', 'queue'];

  @override
  bool isShowSearch = false;

  Future<dynamic> PS(
      String channelName, dynamic Function(dynamic args) fn) async {
    // logger.log('PS reg "PS.$channelName"');
    if (IS_PS_TEST) {
      return await mpJsRuntime.onMessage('PS.${channelName}', (args) {
        try {
          fn(args);
        } catch (e) {
          return null;
        }
      });
    } else {
      return await mpJsRuntime.onMessage('PS.${channelName}', fn);
    }
  }

  Future<void> initAsync() async {
    var proxyConfig = network.pickProxyConfig(null, true);
    // var proxyConfig = {'http_proxy': 'http://127.0.0.1:8080'};
    if (proxyConfig['http_proxy'] != null) {
      logger.blue('proxyConfig ${proxyConfig}');
      playback.setHttpProxy(proxyConfig['http_proxy']!);
    }
    Map<String, Function(dynamic)> funcs = {
      'initPageStacksAsync': (stacksNames) {
        for (var name in stacksNames) {
          _pageStackMap[name] = [];
        }
      },
      'tabs_getAsync': (args) {
        return _tabs.map((p) => [p.$1, p.$2?.name]).toList();
      },
      'tabs_setAsync': (list) {
        _tabs = [];
        for (final p in list) {
          final icon = toIconNameOrNull(p['icon']);
          _tabs.add((p['text'], icon));
        }
      },
      'currSearchTabIdx_getAsync': (args) {
        return currSearchTabIdx;
      },
      'currSearchTabIdx_setAsync': (name) {
        currSearchTabIdx = name;
      },
      'searchTabs_getAsync': (list) {
        return _searchTabs;
      },
      'searchTabs_setAsync': (list) {
        _searchTabs = list.cast<String>();
      },
      'currTabIdx_getAsync': (args) {
        return currTabIdx;
      },
      'currTabIdx_setAsync': (idx) {
        currTabIdx = idx;
      },
      'currPageStackName_getAsync': (args) {
        return _currPageStackName;
      },
      'currPageStackName_setAsync': (name) {
        _currPageStackName = name;
      },
      'currPageStack.length_getAsync': (args) {
        return _currPageStack.length;
      },
      'currPageStack.last_getAsync': (args) {
        var el = _currPageStack.last;
        logger.blue('page: ${el}');
        var obj = jsonDecode(jsonEncode(el));
        return obj;
      },
      'currPageStack.last_setAsync': (pageDescrMap) {
        _currPageStack.removeLastWithDestructor();
        _currPageStack.add(_pageDescrFromMap(pageDescrMap,
            _fmtPagId(_currPageStackName, _currPageStack.length)));
      },
      'currPageStack.pushAsync': (pageDescrMap) {
        _currPageStack.add(_pageDescrFromMap(pageDescrMap,
            _fmtPagId(_currPageStackName, _currPageStack.length)));
      },
      'currPageStack.popAsync': (args) {
        return !back();
      },
      'currMusicPage.title_getAsync': (_) {
        return currMusicPage.title;
      },
      'currMusicPage.title_setAsync': (str) {
        currMusicPage.title = str;
      },
      'currMusicPage.sectionlist_getAsync': (_) {
        // logger.log('in dart sectionlist: ${currMusicPage.sectionlist}');
        var v = currMusicPage.sectionlist;
        return jsonDecode(jsonEncode(v));
      },
      'currMusicPage.sectionlist_setAsync': (sectionlist) {
        // logger.log('sectionlist map: ${sectionlist}');
        currMusicPage.sectionlist =
            _sectionDescrJsListToDart(sectionlist.cast<KeyValue>());
        // logger.blue('sectionlist: ${currMusicPage.sectionlist}');
      },
      'currMusicPage.header_getAsync': (_) {
        var v = currMusicPage.header;
        return jsonDecode(jsonEncode(v));
      },
      'currMusicPage.header_setAsync': (obj) {
        currMusicPage.header = _pageHeaderFromObj(obj as KeyValue);
      },
      'currMusicPage.actionBtn_getAsync': (_) {
        var v = currMusicPage.actionBtn;
        return jsonDecode(jsonEncode(v));
      },
      'currMusicPage.actionBtn_setAsync': (obj) {
        currMusicPage.actionBtn = _actionBtnFromObj(obj as KeyValue);
      },
      'currMusicPage.attrs_getAsync': (_) {
        logger.log('attrs_getAsync: ${currPage.attrs}');
        return currPage.attrs;
      },
      'currMusicPage.props_getAsync': (_) {
        logger.warn('calling props_getAsync: ${currPage.props}');
        return currPage.props;
      },
      'currMusicPage.props_setAsync': (props) {
        currPage.props = props;
      },
      'currPage.typeAsync': (props) {
        return currPage.type.name;
      },
      'currPage.IdAsync': (props) {
        return currPageId;
      },
      'playback.playByIdxAsync': (index) async {
        await playback.playByIdx_n(index);
      },
      'playback.stopWithAsync': (stateStr) async {
        PlayState state = PlayState.fromString(stateStr);
        await playback.stopWith_n(state);
      },

      /// @Unstable
      'playback.resumeAsync': (_) async {
        await playback.resume();
      },

      /// @Unstable
      'playback.pauseAsync': (_) async {
        await playback.pause();
      },
      'playback.setUrlSourceAsync': (o) async {
        var mi = _miJsToDart(o);
        await playback.setUrlSourceAsync(mi);
      },
      'playback.setByteStreamSourceAsync': (o) async {
        var mi = _miJsToDart(o);
        await playback.setByteStreamSourceAsync(mi);
      },
      'playback.pushBufferAsync': (buffer) async {
        // logger.log('pushBufferAsync len: ${buffer.length}');
        List<int> list = buffer.cast<int>();
        var num = await playback.pushBufferAsync(list);
        // logger.log('pushBufferAsync ret: ${num}');
        return num;
      },
      'playback.flushBuffersAsync': (o) async {
        // logger.log('flushBuffersAsync');
        return await playback.flushBuffersAsync();
      },
      'playback.setPositionAsync': (o) async {
        // logger.log('setPosition');
        return playback.setPosition(o['milliseconds']);
      },
      'playback.addEventListener_counterUpdate': (_) async {
        // logger.log('addListener');

        return playback.progressCounter.addListener((int ms) async {
          var mi = playbackQueue.getCurrentMusicItem();
          if (mi.sourceId != sourceId) return;
          await mpJsRuntime.runCodeInAsyncFunc('''// js
              await musicPlayer.playback.eventListeners.counterUpdate?.($ms)
          ''');
        }, type: 'update');
      },
      'queue.insertAllAsync': (obj) {
        int index = obj['index'];
        List list = obj['list'];
        final musicItems = _miJsListToDart(list);
        playbackQueue.insertAll(index, musicItems);
      },
      'queue.addAllAsync': (list) {
        final musicItems = _miJsListToDart(list);
        playbackQueue.addAll(musicItems);
      },
      'queue.removeRange': (obj) {
        int start = obj['start'];
        int end = obj['end'];
        playbackQueue.removeRange(start, end);
      },
      'queue.clearAsync': (_) {
        playbackQueue.clear();
      },
      'queue.getTrackAsync': (index) {
        var v = playbackQueue.getMusicItem(index);
        return jsonDecode(jsonEncode(v));
      },
      'queue.setTrackAsync': (o) async {
        int index = o['index'];
        MusicItem mi = await _miJsToDartWithPictureAsync(o['mi']);
        playbackQueue.setAt(index, mi);
      },
      'queue.currTrackIdx_getAsync': (_) {
        return playbackQueue.currentIdx;
      },
      'queue.currTrackIdx_setAsync': (index) {
        playbackQueue.setCurrIdx(index);
      },
      'queue.lengthAsync': (_) {
        return playbackQueue.length;
      },
      'queue.canAutoplayAsync': (_) {
        return autoplaySources.currentId == sourceId;
      },
      'queue.setAutoplayAsync': (b) {
        if (b) {
          autoplaySources.add_n(sourceId, pluginTitle);
        } else {
          autoplaySources.remove_n(sourceId);
        }
      },
      'queue.addEventListener_musicItemChange': (args) {
        // TODO (bug): remove previous listener if already got one
        eventRegistrar.register(eventRegistrar.musicItemChangeListeners,
            (v) async {
          var vJson = jsonEncode(v);
          await mpJsRuntime.runCodeInAsyncFunc('''// js
            await musicPlayer.queue.eventListeners.musicItemChange?.($vJson);
          ''');
        });
      },
      'navType_getAsync': (controls) {
        return navType.name;
      },
      'navType_setAsync': (str) {
        navType = toNavType(str);
      },
      'isShowSearch_getAsync': (controls) {
        return isShowSearch;
      },
      'isShowSearch_setAsync': (isShow) {
        isShowSearch = isShow;
      },
      'rightControls_getAsync': (controls) {
        return rightControls;
      },
      'rightControls_setAsync': (controls) {
        rightControls = controls.cast<String>();
      },
      'isShowPreloader_getAsync': (b) {
        return isShowPreloader;
      },
      'isShowPreloader_setAsync': (b) {
        isShowPreloader = b;
      },
      'updateThumbnailFromUrlAsync': (args) async {
        return await updateThumbnailFromUrlAsync(args['id'], args['url']);
      },
      'source.addEventListener_scrollEnd': (args) {
        eventRegistrar.register(
            eventRegistrar.musicSourceContentsScrollEndListeners, (v) async {
          if (!isCurrentSource()) return;
          var vJson = jsonEncode(v);
          await mpJsRuntime.runCodeInAsyncFunc('''// js
            await musicPlayer.source.eventListeners.scrollEnd?.($vJson);
          ''');
        });
      },
      'propertyStorage.getAsync': (name) {
        return propertyStorage.getProperty(name);
      },
      'propertyStorage.setAsync': (args) {
        return propertyStorage.saveProperty(args['name'], args['value']);
      },
      'settings.setControlsAsync': (controls) {
        logger.blue('controls=$controls');
        settingsControls = controls;
      },
      'errorManager.getAsync': (_) {
        return errorMsg;
      },
      'errorManager.setAsync': (err) {
        errorMsg = err;
      },
      'getLanguageAsync': (_) {
        return lang.type_;
      },
      'showActionsDialogAsync': (obj) async {
        var actions = await _buildJsActionsAsync();
        var tapPos = obj['tapPos']?.cast<double>();
        showActionsDialog(actions, onExit: () {
          logger.green('free actions pool');
          freeAcitonsPoolAsync();
        }, tapPos: tapPos);
      },
      'toThisSourceAsync': (_) async {
        await toThisSourceAsync();
      },
      'closeActionsDialogAsync': (_) {
        closeActions();
      },
      'cachedMiExistsAsync': (o) async {
        var miJs = o['mi'];
        logger.blue(o);
        return await cachedWebFileExists(miJs['id']);
      },
      'saveCachedMiAsync': (o) async {
        var miJs = o['mi'];
        logger.blue(o);
        MusicItem mi = await _miJsToDartWithPictureAsync(miJs);
        return await saveCachedMiAsync(mi);
      },
      'saveMiAsync': (o) async {
        var miJs = o['mi'];
        List<int> bytes = o['bytes'].cast<int>();
        MusicItem mi = await _miJsToDartWithPictureAsync(miJs);
        return await saveMiAsync(mi, bytes);
      },
      'showSnackBarAsync': (o) {
        showSnackBarNoContext(o['message']);
      },
      'reloadFsSourceAsync': (_) {
        reloadFsSource();
      },
      'updateAppStateAsync': (_) {
        // (currPage as MusicPageDescr).updateIdx++;
        updateAppState();
      },
      'DownloadsState.download': (o) async {
        String poolName = o['poolName'];
        DownloadType downloadType = DownloadType.fromString(o['downloadType']);

        final dId = DownloadsState.fmt(downloadType, sourceId, o['id']);
        return await downloadsState.download(
          id: dId,
          text: o['text'],
          isRemovable: true,
          abort: () async {
            return await mpJsRuntime.runCodeInAsyncFunc('''// js
                let pool = musicPlayer._poolManager.getPool('$poolName');
                pool.get('abort')()
            ''');
          },
          fetch: () async {
            return await mpJsRuntime.runCodeInAsyncFunc('''// js
                let pool = musicPlayer._poolManager.getPool('$poolName');
                return await pool.get('fetch')()
              ''');
          },
        );
      },
      'DownloadsState.removeAndAbortByTypeAsync': (o) {
        final type = DownloadType.fromString(o['type']);
        downloadsState.removeAndAbortByType_n(type);
      },
      'readAssetAsync': (args) async {
        String path = args['path'];
        return await rootBundle.loadString(path);
      },
      'helpers.setAttrsAsync': (attrs) {
        _setAttrsSafe(attrs);
      }
    };

    for (var entry in funcs.entries) {
      await PS(entry.key, entry.value);
    }

    Map<String, Function(dynamic)> funcsWebView = {
      'isSupportedAsync': (_) async {
        logger.log('WebView.isSupportedAsync');
        return Platform.isAndroid || Platform.isIOS;
      },
      'runJavaScriptReturningResultAsync': (code) async {
        logger.log('WebView.runJavaScriptReturningResultAsync');
        return await webViewController!.runJavaScriptReturningResult(code);
      },
      'currentUrlAsync': (_) async {
        logger.log('WebView.currentUrlAsync');
        return await webViewController!.currentUrl();
      },
      'isNullAsync': (_) async {
        logger.log('WebView.isNull');
        return webViewController == null;
      },
      'cookieManager.clearCookiesAsync': (_) async {
        await cookieManager.clearCookies();
      },
      'cookieManager.hasCookiesAsync': (_) async {
        return await cookieManager.hasCookies();
      },
      'cookieManager.getCookiesAsync': (url) async {
        List<Cookie> cookies = await cookieManager.getCookies(url);
        List<Map<String, dynamic>> list = [];
        for (var c in cookies) {
          var o = {
            'name': c.name,
            'value': c.value,
            'path': c.path,
            'domain': c.domain,
            'secure': c.secure,
            'httpOnly': c.httpOnly,
            'expiresMs': c.expires?.millisecondsSinceEpoch,
            'maxAge': c.maxAge,
            'asString': c.toString(),
          };
          list.add(o);
        }
        return list;
      },
      'cookieManager.setCookiesAsync': (m) async {
        final cs = m['cookies'];
        final origin = m['origin'];
        List<Cookie> cookies = [];
        for (var o in cs) {
          final c = Cookie(o['name'], o['value']);
          c.path = o['path'];
          c.domain = o['domain'];
          c.secure = o['secure'] ?? c.secure;
          c.httpOnly = o['httpOnly'] ?? c.httpOnly;
          if (o['expires'] != null) {
            c.expires = DateTime.fromMillisecondsSinceEpoch(o['expiresMs']);
          }
          c.maxAge = o['maxAge'];
          cookies.add(c);
        }
        await cookieManager.setCookies(cookies, origin: origin);
      },
    };
    for (var entry in funcsWebView.entries) {
      await PS('WebView.${entry.key}', entry.value);
    }

    if (IS_PS_TEST) {
      await mpJsRuntime.runCodeInAsyncFunc('''// js
      await musicPlayer.testAllPS();
    ''');
    }

    logger.debug('Async Inited');
  }

  final cookieManager = WebviewCookieManager();

  NavigationDelegate _createNavigationDelegate() {
    return NavigationDelegate(
      onPageStarted: (String url) {
        logger.log('"$url" - onPageStarted');
        mpJsRuntime.runCodeInAsyncFunc('''// js
              await musicPlayer.webView.listeners.onPageStarted?.("$url")
            ''');
      },
      onProgress: (int progress) {
        logger.log('"$progress" - onProgress');
        mpJsRuntime.runCodeInAsyncFunc('''// js
              await musicPlayer.webView.listeners.onProgress?.(progress)
            ''');
      },
      onPageFinished: (String url) async {
        logger.log('"$url" - onPageFinished');
        logger.warn('cookies:');
        final gotCookies = await cookieManager.getCookies(url);
        for (var item in gotCookies) {
          logger.warn(item);
        }
        logger.warn('done cookes for "$url"');
        mpJsRuntime.runCodeInAsyncFunc('''// js
              await musicPlayer.webView.listeners.onPageFinished?.("$url")
            ''');
      },
      onUrlChange: (UrlChange urlChange) {
        logger.log('"${urlChange.url}" - onUrlChange');
        mpJsRuntime.runCodeInAsyncFunc('''// js
              await musicPlayer.webView.listeners.onUrlChange?.({ 
                url: "${urlChange.url}",
              })
            ''');
      },
      onNavigationRequest: (NavigationRequest request) {
        logger.log('"$request" - onNavigationRequest');
        mpJsRuntime.runCodeInAsyncFunc('''// js
              await musicPlayer.webView.listeners.onUrlChange?.({ 
                url: "${request.url}",
                isMainFrame: "${request.isMainFrame}",
              })
            ''');
        return NavigationDecision.navigate;
      },
      onHttpAuthRequest: (HttpAuthRequest request) {
        logger.log('"$request" - onHttpAuthRequest');
        mpJsRuntime.runCodeInAsyncFunc('''// js
              await musicPlayer.webView.listeners.onHttpAuthRequest?.()
            ''');
      },
      onHttpError: (HttpResponseError error) {
        logger.log('"$error" - onHttpError');
        mpJsRuntime.runCodeInAsyncFunc('''// js
              await musicPlayer.webView.listeners.onHttpError?.()
            ''');
      },
      onWebResourceError: (WebResourceError error) {
        logger.log('"$error" - onWebResourceError');
        mpJsRuntime.runCodeInAsyncFunc('''// js
              await musicPlayer.webView.listeners.onWebResourceError?.()
            ''');
      },
      onSslAuthError: (SslAuthError error) {
        logger.log('"$error" - onSslAuthError');
        mpJsRuntime.runCodeInAsyncFunc('''// js
              await musicPlayer.webView.listeners.onSslAuthError?.()
            ''');
      },
    );
  }

  void _setShowPreloader_n(bool val) {
    isShowPreloader = val;
    updateAppState();
  }

  void _setAttrsSafe(KeyValue? attrs) {
    if (attrs == null) {
      logger.log('No attrs');
      return;
    }
    logger.blue('>>> Page attrs: ${attrs}');
    if (attrs.containsKey('isShowSearch')) {
      isShowSearch = attrs['isShowSearch'];
    }
    if (!attrs.containsKey('tabsNav')) return;

    var tabsNav = attrs['tabsNav'];
    if (tabsNav.containsKey('type')) {
      navType = toNavType(tabsNav['type']);
    }

    if (tabsNav.containsKey('tabs')) {
      final list = tabsNav['tabs'];
      if (navType == NavType.searchTabs) {
        _searchTabs = list.cast<String>();
      } else if (navType == NavType.tabs) {
        _tabs = [];
        for (final p in list) {
          final icon = toIconNameOrNull(p['icon']);
          _tabs.add((p['text'], icon));
        }
      }
    }
    if (tabsNav.containsKey('index')) {
      if (navType == NavType.searchTabs) {
        currSearchTabIdx = tabsNav['index'];
      } else if (navType == NavType.tabs) {
        currTabIdx = tabsNav['index'];
      }
    }
  }

  PageDescr _pageDescrFromMap(KeyValue descr, String pageId) {
    _makeFuncsPool(pageId);
    final type = descr['type'] as String;
    switch (type) {
      case 'music':
        var s = descr['sectionlist'].cast<KeyValue>();
        var sectionlist = _sectionDescrJsListToDart(s);
        if (sectionlist.isEmpty) {
          logger.warn('Sectionlist is empty');
        }

        final headerMap = descr['header'];
        final actionMap = descr['actionBtn'];
        var p = MusicPageDescr(
          title: descr['title'] ?? '',
          sectionlist: sectionlist,
          header: headerMap != null ? _pageHeaderFromObj(headerMap) : null,
          actionBtn: _allocActionBtnFromObjOrNull(actionMap),
          attrs: descr['attrs'],
          props: descr['props'] ?? const {},
          destruct: () {
            _removeFuncsPool(pageId);
          },
        );
        logger.blue('p: $p');
        _setAttrsSafe(p.attrs);
        return p;
      case 'controls':
        final p = ControlsPageDescr(
          title: descr['title'] ?? '',
          controls: descr['controls'],
          attrs: descr['attrs'],
          props: descr['props'] ?? const {},
          destruct: () {
            _removeFuncsPool(pageId);
          },
        );
        _setAttrsSafe(p.attrs);
        return p;
      case 'webView':
        var url = descr['url'];
        assert(url is String, 'url must be string');
        final p = WebViewPageDescr(
          title: descr['title'] ?? '',
          attrs: descr['attrs'],
          props: descr['props'] ?? const {},
          destruct: () {
            _removeFuncsPool(pageId);
            logger.log('WebViewPageDescr.destruct: nulling webViewController');
            webViewController = null;
          },
        );
        var uri = Uri.tryParse(url);
        if (uri == null) {
          logger.error('WebView: bad url="$url"');
          return p;
        }
        if (webViewController != null) {
          logger.error(
              'WebView: Only one webViewController at a time allowed! Creation aborted.');
          return p;
        }
        final navigationDelegate = _createNavigationDelegate();
        webViewController = WebViewController();
        webViewController!
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(navigationDelegate)
          ..loadRequest(uri);
        _setAttrsSafe(p.attrs);
        return p;
      default:
        throw Exception('Wrong branch: ${type}');
    }
  }

  Future<void> _makeFuncsPool(String id) async {
    await mpJsRuntime.runCodeInAsyncFunc('''// js
        musicPlayer._poolManager.makePool('$id');
    ''');
  }

  Future<void> _removeFuncsPool(String id) async {
    await mpJsRuntime.runCodeInAsyncFunc('''// js
        musicPlayer._poolManager.deletePool('$id');
    ''');
  }

  List<SectionDescr> _sectionDescrJsListToDart(List<KeyValue> sectionlistMaps) {
    List<SectionDescr> sectionlist = [];
    int idx = 0;
    for (var sectionMap in sectionlistMaps) {
      ListType listType = toListType(sectionMap['listType']);

      List<Item> itemlist = const [];
      if (listType == ListType.tracklist) {
        itemlist = _miJsListToDart(sectionMap['itemlist']);
      } else if (listType == ListType.grouplist) {
        itemlist = _groupsJsListToDart(sectionMap['itemlist']);
      }

      final headerMap = sectionMap['header'];
      SectionHeaderDescr? header;
      if (headerMap != null) {
        final ac = headerMap['actionBtn'];
        final btnDescr = _allocActionBtnFromObjOrNull(ac);

        header = SectionHeaderDescr(
          title: headerMap['title'],
          subtitle: headerMap['subtitle'],
          actionBtn: btnDescr,
        );
      }
      final SectionDescr section = SectionDescr.indexed(
        header: header,
        itemlist: itemlist,
        isBigTile: sectionMap['isBigTile'] ?? false,
        rowsCount: sectionMap['rowsCount'],
        index: idx++,
      );
      sectionlist.add(section);
    }

    return sectionlist;
  }

  PageHeaderDescr _pageHeaderFromObj(KeyValue obj) {
    logger.warn(obj);
    final v = PageHeaderDescr(
      title: obj['title'],
      subtitle: obj['subtitle'],
      actionBtn: _allocActionBtnFromObjOrNull(obj['actionBtn']),
    );

    final url = obj['thumbnailUrl'];
    if (url != null) {
      fetchPicture(url).then((picture) {
        v.picture = picture;
        currMusicPage.updateIdx++;
        playbackQueue.updateIdx++;
        updateAppState();
        updatePlaybackState();
      });
    }
    return v;
  }

  ActionBtnDescr? _allocActionBtnFromObjOrNull(KeyValue? obj) {
    return obj != null ? _actionBtnFromObj(obj) : null;
  }

  ActionBtnDescr _actionBtnFromObj(KeyValue obj) {
    String text = obj['text'] ?? '';
    IconName? icon = toIconNameOrNull(obj['icon']);
    // ignore: no_leading_underscores_for_local_identifiers
    String _callbackName = obj['_callbackName'];

    Future<void> callback() async {
      await mpJsRuntime.runCodeInAsyncFunc('''// js
            let poolName = await musicPlayer._PS('currPage.IdAsync');
            console.log('poolName', poolName)
            let pool = musicPlayer._poolManager.getPool(poolName);
            let f = pool.get("${_callbackName}")
            return await f();
      ''');
    }

    return ActionBtnDescr(
      text: text,
      icon: icon,
      onTap: callback,
    );
  }

  Future<void> afterPluginLoaded() async {
    await mpJsRuntime.runCodeInAsyncFunc('''// js
			await $pluginMainObjectName.initAsync();
    ''');
  }

  Future<MusicItem> _miJsToDartWithPictureAsync(dynamic miJs) async {
    MusicItem mi = _miJsToDart(miJs);
    var url = miJs['thumbnailUrl'];
    if (url != null) {
      mi.picture = await fetchPicture(url);
    }
    return mi;
  }

  List<MusicItem> _miJsListToDart(List<dynamic> musicsList) {
    List<MusicItem> musics = [];

    var picturesPromises = _makePicturePromises(musicsList);
    for (var miJs in musicsList) {
      var mi = _miJsToDart(miJs);
      musics.add(mi);

      var url = miJs['thumbnailUrl'];
      _gatherPictureSafe(mi, picturesPromises, url);
    }
    return musics;
  }

  MusicItem _miJsToDart(dynamic miJs) {
    final mi = MusicItem.fromJson(miJs, sourceId: sourceId);
    return mi;
  }

  List<GroupItem> _groupsJsListToDart(List<dynamic> groupsMap) {
    List<GroupItem> groups = [];

    var picturesPromises = _makePicturePromises(groupsMap);
    for (var el in groupsMap) {
      final group = GroupItem.fromJson(el, sourceId: sourceId);
      groups.add(group);

      var url = el['thumbnailUrl'];
      _gatherPictureSafe(group, picturesPromises, url);
    }
    return groups;
  }

  Future<void> _gatherPictureSafe(
      Item item, Map<String, Future<PictureTag?>> proms, String? url) async {
    if (url is String && url != '') {
      await _gatherPicture(item, proms, url);
    }
  }

  static const _defaultGatheredAmount = 15;
  int _gatheredAmount = _defaultGatheredAmount;
  var _gatheredCount = _defaultGatheredAmount;
  Future<void> _gatherPicture(
      Item item, Map<String, Future<PictureTag?>> proms, String url) async {
    try {
      item.picture = await proms[url];
      proms.remove(url);
      --_gatheredCount;
      // log('removed "$url" - $_gatheredCount');
      if (_gatheredCount == 0 || proms.isEmpty) {
        // log('updateIdx');
        _gatheredCount = _gatheredAmount;

        currMusicPage.updateIdx++;
        playbackQueue.updateIdx++;
        updateAppState();
        updatePlaybackState();
      }
    } catch (e) {
      logger.error('_gatherPicture: $e');
      rethrow;
    }
  }

  Map<String, Future<PictureTag?>> _makePicturePromises(musics) {
    Map<String, Future<PictureTag?>> picturesPromises = {};
    for (var el in musics) {
      var url = el['thumbnailUrl'];
      if (url != null && url != '') {
        picturesPromises[url] = fetchPicture(url);
      } else {
        logger.log('Skipping nullish url: "${url}"');
      }
    }
    if (picturesPromises.length < _defaultGatheredAmount) {
      _gatheredAmount = 1;
    } else {
      _gatheredAmount = _defaultGatheredAmount;
    }
    _gatheredCount = _gatheredAmount;
    return picturesPromises;
  }

  @override
  Future<void> searchAsync(String rawSearchText) async {
    String searchText = utils.sanitize(rawSearchText);
    await mpJsRuntime.runCodeInAsyncFunc('''// js
      musicPlayer.runtime.logger.log('Search text: ' + '$searchText');
      await $pluginMainObjectName.searchAsync('$searchText');
    ''');
    updateAppState();
  }

  @override
  Future<List<String>?> getSuggestionsAsync(String text) async {
    String sugsText = utils.sanitize(text);
    final sugs = await mpJsRuntime.runCodeInAsyncFunc('''// js
      musicPlayer.runtime.logger.log('getSuggestions text: ' + '$sugsText');
      return await $pluginMainObjectName.getSuggestionsAsync('$sugsText');
    ''');
    if (sugs is List) {
      return sugs.cast<String>();
    }
    return null;
  }

  @override
  Duration debounceDelay = const Duration(milliseconds: 0);

  Future<bool> updateThumbnailFromUrlAsync(String id, String url) async {
    MusicItem? mi = findMusicItem(id);
    if (mi == null) {
      logger.error('[updateThumbnailFromUrlAsync]: MusicItem not found');
      return false;
    }
    var pic = await fetchPicture(url);
    mi.thumbnailUrl = url;
    mi.tags.picture = pic;
    updateAppState();
    return pic != null;
  }

  Future<PictureTag?> fetchPicture(String url) async {
    // logger.blue('fetchPicture');
    FileInfo? fInfo = await DefaultCacheManager().getFileFromCache(url);
    if (fInfo != null) {
      // logger.blue(
      //     'Pic from cache: ${fInfo.originalUrl} with path : ${fInfo.file.path}');
      final picture = PictureTag(
          mime: utils.mimeFromPath(fInfo.file.path) ?? 'image/jpeg',
          bytes: fInfo.file.readAsBytesSync());
      return picture;
    } else {
      Map<String, String>? proxyConfig =
          (await mpJsRuntime.runCodeInAsyncFunc('''// js
              return __dartjs_sendMessage('MP.getProxyConfig', JSON.stringify({}));
          '''))?.cast<String, String>();
      network.setProxy(_httpClient, proxy: proxyConfig);
      final picture =
          await utils_flutter.downloadPictureAsync(url, _httpClient);

      if (picture != null) {
        logger.log('New pic cache: ${url}');
        await cachePictureAsync(url, picture);
      }
      return picture;
    }
  }

  final HttpClient _httpClient = network.makeHttpClient();

  @override
  PageDescr get currPage {
    return _currPageStack.last;
  }

  String get currPageId {
    return '$_currPageStackName.${_currPageStack.length - 1}';
  }

  String _fmtPagId(String stackName, int pageIndex) {
    return '$stackName.$pageIndex';
  }

  MusicPageDescr get currMusicPage {
    return _currPageStack.last as MusicPageDescr;
  }

  @override
  NavType navType = NavType.none;

  @override
  int currTabIdx = 0;

  String _currPageStackName = '';

  List<PageDescr> get _currPageStack {
    var v = _pageStackMap[_currPageStackName];
    if (v == null) {
      logger.error('logger.error: Wrong page stack name "$_currPageStackName"');
      return [];
    }
    return v;
  }

  final Map<String, List<PageDescr>> _pageStackMap = {};

  printPageStacks() {
    String s = 'PageStacks [$_currPageStackName - curr]:\n{';
    for (var entry in _pageStackMap.entries) {
      var l = entry.value.length;
      s += '\t${entry.key} ($l): [';
      for (var el in entry.value) {
        s += '${el.title} > ';
      }
      s += ']\n';
    }
    s += '}';
    logger.log(s);
  }

  List<(String, IconName?)> _tabs = [];

  @override
  List<(String, IconName?)> getTabs() {
    return _tabs;
  }

  @override
  int currSearchTabIdx = 0;

  @override
  List<String> getSearchTabs() {
    return _searchTabs;
  }

  List<String> _searchTabs = [];

  @override
  Future<void> chooseSourceAsync() async {
    logger.log('chooseSource: ("$sourceId", "$pluginMainObjectName")');
    await mpJsRuntime.runCodeInAsyncFunc('''// js
			await $pluginMainObjectName.chooseSourceAsync();
    ''');
    updateAppState();
  }

  @override
  Future<void> reloadAsync() async {
    logger.log('reloadAsync');
    await mpJsRuntime.runCodeInAsyncFunc('''// js
			await $pluginMainObjectName.reloadAsync();
    ''');
    updateAppState();
  }

  @override
  Future<void> chooseTabAsync(int index) async {
    await mpJsRuntime.runCodeInAsyncFunc('''// js
			await $pluginMainObjectName.chooseTabAsync($index);
    ''');
    updateAppState();
  }

  @override
  Future<void> chooseSearchTabAsync(int index) async {
    await mpJsRuntime.runCodeInAsyncFunc('''// js
			await $pluginMainObjectName.chooseSearchTabAsync($index);
    ''');
    updateAppState();
  }

  /// Throws
  @override
  Future<void> setPlaybackSourceAsync(MusicItem mi) async {
    logger.blue('setPlaybackSourceAsync');
    try {
      final miJson = jsonEncode(mi);
      await mpJsRuntime.runCodeInAsyncFunc('''// js
        musicPlayer.runtime.logger.log('setPlaybackSourceAsync plugin');
        await $pluginMainObjectName.setPlaybackSourceAsync($miJson);
      ''');
    } catch (e) {
      // logger.warn('$e');
      logger.warn('Error in setPlaybackSourceAsync rethrow');
      rethrow;
    }
  }

  @override
  Future<void> chooseGroupAsync(GroupItem group) async {
    final groupJson = jsonEncode(group);
    try {
      await mpJsRuntime.runCodeInAsyncFunc('''// js
        await $pluginMainObjectName.chooseGroupAsync($groupJson);
      ''');
    } catch (e) {
      logger.warn('$e');
    }
  }

  @override
  Future<List<ItemAction>> buildActionsAsync(
    IndexedItem indexedItem,
    int sectionIndex,
  ) async {
    String indexedItemJson = jsonEncode(indexedItem);
    try {
      await mpJsRuntime.runCodeInAsyncFunc('''// js
        musicPlayer._actions = await $pluginMainObjectName
            .buildActionsAsync($indexedItemJson, $sectionIndex);
    ''');
      List<ItemAction> actions = await _buildJsActionsAsync();
      return actions;
    } catch (e) {
      logger.error('buildActionsAsync: $e');
      return [];
    }
  }

  @override
  Future<List<ItemAction>> buildMultiActionsAsync(
      Map<String, List<IndexedItem>> selectionMap,
      void Function() cancel) async {
    String selectionMapJson = jsonEncode(selectionMap);
    logger.blue('selectionMapJson="${selectionMapJson}"');
    try {
      await mpJsRuntime.runCodeInAsyncFunc('''// js
        musicPlayer._actions = await $pluginMainObjectName
            .buildMultiActionsAsync($selectionMapJson);
    ''');
      List<ItemAction> actions = await _buildJsActionsAsync();
      return actions;
    } catch (e) {
      logger.error('buildMultiActionsAsync: $e, ${e.runtimeType}');
      return [];
    }
  }

  @override
  bool back() {
    assert(_currPageStack.isNotEmpty, 'Category must have pages!');
    // 1. Pop from stack by self
    if (_currPageStack.length == 1) {
      return true; // should pop
    }

    _currPageStack.removeLastWithDestructor();
    _setAttrsSafe(currPage.attrs);
    printPageStacks();

    // 2. Call js
    triggerEventAsync('AfterBack', {});

    return false; // don't pop
  }

  @override
  bool canBack() {
    return _currPageStack.length >= 2;
  }

  @override
  Future<bool> seekAsync(int milliseconds) async {
    // logger.blue('seekAsync to: $milliseconds');
    var resp = await mpJsRuntime.runCodeInAsyncFunc('''// js
				if (typeof $pluginMainObjectName.seekAsync !== 'function') {
					musicPlayer.runtime.logger.log('seekAsync function not implemented')
					return false;
				}
        let prevent = await $pluginMainObjectName.seekAsync($milliseconds);
        musicPlayer.runtime.logger.log('seekAsync prevent:', prevent)
        return prevent
      ''');
    // logger.blue('seekAsync prevent: $resp');
    return resp;
  }

  /// Triggers event with args in map
  @override
  Future<void> triggerEventAsync(String event, Map map) async {
    String serialized = jsonEncode(map);
    logger.log('Event "$event" arguments: $serialized');
    if (event == 'PluginSettingsOpen') {
      var resp = await mpJsRuntime.runCodeInAsyncFunc('''// js
        return await $pluginMainObjectName.settings.onOpen();
      ''');
      logger.blue('resp: $resp');
      return;
    }
    if (event == 'PluginSettingsClose') {
      var resp = await mpJsRuntime.runCodeInAsyncFunc('''// js
        return await $pluginMainObjectName.settings.onClose();
      ''');
      logger.blue('resp: $resp');
      return;
    }

    // Run js
    final name = pluginMainObjectName;
    await mpJsRuntime.runCodeInAsyncFunc('''// js
				if (typeof $name.on$event !== 'function') {
					musicPlayer.runtime.logger.warn('[$name] function', 'on$event', "doesn't exist.")
					return
				}
				const resp = await $name.on$event($serialized);
				musicPlayer.runtime.logger.log('[$name] event returned:', resp, '.');
    ''');
  }

  static const String _actionsPoolName = 'actionsPool';
  static const String controlsPoolName = 'controlsPool';

  Future<List<ItemAction>> _buildJsActionsAsync() async {
    // gLogger.log('_buildJsActionsAsync');
    final List<Map> actions = (await mpJsRuntime.runCodeInAsyncFunc('''// js
      let actionsJs = musicPlayer._actions

      var pool = musicPlayer._poolManager.makePool("${_actionsPoolName}");
      var actions =  actionsJs.map((a) => {
        let name = pool.add(a.callback)
        return {
            text: a.text,
            icon: a.icon,
            _callbackName: name,
        }
      })
      return actions
    ''')).cast<Map>();

    return actions
        .map((item) => ItemAction(
              text: item['text'] ?? '',
              icon: toIconNameOrNull(item['icon']),
              callback: (DialogFuncs dialogFuncs) async {
                logger.log('Calling dialog func');
                await mpJsRuntime.runCodeInAsyncFunc('''// js
                      var pool = musicPlayer._poolManager.getPool("${_actionsPoolName}");
                      var f = pool.get("${item['_callbackName']}")
                      return await f();
                ''');
              },
            ))
        .toList();
  }

  Future<void> freeAcitonsPoolAsync() async {
    mpJsRuntime.runCodeInAsyncFunc('''// js
        musicPlayer._poolManager.deletePool("${_actionsPoolName}");
      ''');
  }

  static final Logger logger = Logger(prefix: '📗 PluginSource: ');
}

extension ElementDestructorExtension<T extends Destructable> on List<T> {
  T removeLastWithDestructor() {
    last.destruct?.call();
    return removeLast();
  }

  // setLastWithDestructor(T el) {
  //   last = el;
  //   el.destruct?.call();
  // }
}
