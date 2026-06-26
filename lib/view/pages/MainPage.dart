import 'package:flutter/material.dart';
import 'package:music_player/logger.dart';
import 'package:music_player/logic/PluginSource.dart';
import 'package:music_player/view/components/Drawers.dart';
import 'package:music_player/view/components/ScrolledOpacityAnimation.dart';
import 'package:music_player/view/components/ScrollingPageWrapper.dart';
import 'package:music_player/view/components/SelectionInfo.dart';
import 'package:music_player/view/components/plugins/PluginControlsBody.dart';
import 'package:provider/provider.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logic/enums.dart';
import 'package:music_player/logic/PageDescr.dart';

import 'package:music_player/states/AppState.dart';
import 'package:music_player/states/AppearanceState.dart';
import 'package:music_player/states/PlaybackState.dart';

import 'package:music_player/view/App.dart' show gPadding, searchFocusNode;
import 'package:music_player/view/components/SectionsWrapper.dart';
import 'package:music_player/view/components/SearchBox.dart';
import 'package:music_player/view/components/BottomControls.dart';
import 'package:music_player/view/components/DownloadsIndicator.dart';
import 'package:music_player/view/addGuardsFuncs.dart';
import 'package:music_player/view/components/Tabs.dart';
import 'package:music_player/view/components/TopTabs.dart';
import 'package:music_player/view/components/Sidebar.dart';

import 'package:music_player/view/pages/AppearancePage.dart';
import 'package:music_player/view/pages/PluginsPage.dart';
import 'package:music_player/view/pages/SettingsPage.dart';
import 'package:music_player/view/pages/SyncPage.dart';
import 'package:music_player/view/pages/QueuePage.dart';
import 'package:music_player/view/pages/ModifyPlaylistPage.dart';
import 'package:webview_flutter/webview_flutter.dart' show WebViewWidget;

final GlobalKey<ScaffoldState> mpStateKey = GlobalKey();

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final Widget endDrawerPage = const QueuePage();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    bool isPlaybackControlsClosed = context.select<AppState, bool>(
        (s) => s.controlsSheetOpenDegree == OpenDegree.closed);
    Pages mainPage = context.select<AppState, Pages>((s) => s.mainPage);

    var appBar = getAppBar(context);

    bool isIdle =
        context.select<PlaybackState, bool>((s) => s.playback.isIdle());

    List<String> searchCats = context
        .select<AppState, List<String>>((s) => s.currentSource.getSearchTabs());

    final idx = context
        .select<AppState, int>((app) => app.currentSource.currSearchTabIdx);

    var navType =
        context.select<AppState, NavType>((s) => s.currentSource.navType);

    double height = MediaQuery.of(context).size.height;
    EdgeInsets padding = MediaQuery.paddingOf(context);
    gPadding = padding;

    bool isWithTabs = navType == NavType.tabs;
    double tabsHeightOrZero = isWithTabs ? CONFIG.tabsHeight : 0;

    double minControlsChildSize =
        (CONFIG.bottomControlsHeight + tabsHeightOrZero) /
            (height - padding.bottom - padding.top);

    bool isWithBottomControls = mainPage == Pages.source && !isIdle;

    late Widget mainBody;
    switch (mainPage) {
      case Pages.settings:
        mainBody = const SettingsBody();
        break;
      case Pages.appearance:
        mainBody = const AppearanceBody();
        break;
      case Pages.sync:
        mainBody = const SyncBody();
        break;
      case Pages.plugins:
        mainBody = const PluginsBody();
        break;
      case Pages.source:
        mainBody = Stack(
          // alignment: Alignment.center,
          children: [
            // TODO: add guards to body with tabs, etc.
            addGuardsToPageBody(const SourceContents(), context),
            Positioned(
                bottom: padding.bottom +
                    20 +
                    tabsHeightOrZero +
                    (isWithBottomControls ? 60 : 0),
                child: const SelectionInfo())
          ],
        );
        break;
    }

    var mainAxisAlignment = appState.isWide
        ? MainAxisAlignment.start
        : MainAxisAlignment.spaceBetween;

    final pageType =
        context.select<AppState, PageDescrType>((s) => s.currPage.type);
    final bool isWebView = pageType == PageDescrType.webView;

    return Scaffold(
      key: mpStateKey,
      body: SafeArea(
        child: MainPopScope(
          child: Drawers(
            appState: appState,
            drawer: const SlidingSidebar(),
            onDrawerStatusChanged: (status) {
              // gLogger.log('drawer status=$status');
              if (status.isCompleted) {
                if (!appState.isDrawerOpened) {
                  appState.isDrawerOpened = true;
                  appState.update();
                }
              } else {
                if (appState.isDrawerOpened) {
                  appState.isDrawerOpened = false;
                  appState.update();
                }
              }
            },
            onEndDrawerStatusChanged: (status) {
              // gLogger.log('endDrawer status=$status');
              if (status.isCompleted) {
                if (!appState.isEndDrawerOpened) {
                  appState.isEndDrawerOpened = true;
                  appState.update();
                }
              } else {
                if (appState.isEndDrawerOpened) {
                  appState.isEndDrawerOpened = false;
                  appState.update();
                }
              }
            },
            enableDrag: isPlaybackControlsClosed && !isWebView,
            endDrawer: endDrawerPage,
            child: SizedBox(
              width: double.infinity,
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      appBar,
                      if (mainPage == Pages.source &&
                          navType == NavType.searchTabs)
                        TopTabs(
                          elements: searchCats,
                          initial: idx,
                          onSelect: (index) {
                            appState.chooseSearchTabAsync(index);
                            return false;
                          },
                          mainAxisAlignment: mainAxisAlignment,
                        ),
                      Expanded(child: mainBody),
                    ],
                  ),
                  if (mainPage == Pages.source && !isIdle)
                    BottomControls(
                      viewPadding: padding,
                      minControlsChildSizeArg: minControlsChildSize,
                    ),
                  if (mainPage == Pages.source && isWithTabs)
                    Positioned(
                        left: 0,
                        bottom: 0,
                        child: ScrolledOpacityAnimation(
                          sheetController: controlsSheetController,
                          fadeInPercent: minControlsChildSize,
                          fadeOutPercent: 0.24,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: CONFIG.tabsHeight,
                            child: const Tabs(),
                          ),
                        )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

AppBar getAppBar(BuildContext context) {
  final appState = Provider.of<AppState>(context, listen: false);
  String headlineTitle =
      context.select<AppState, String>((s) => s.headlineTitle);
  bool isSearchToggled =
      context.select<AppState, bool>((s) => s.isSearchToggled);

  bool isShowSearch =
      context.select<AppState, bool>((s) => s.currentSource.isShowSearch);
  List<String> rightControls = context
      .select<AppState, List<String>>((s) => s.currentSource.rightControls);

  final appearanceState = Provider.of<AppearanceState>(context, listen: false);
  final searchBtnStyle = IconButton.styleFrom(
    backgroundColor: isSearchToggled
        ? appearanceState.lerpBgColor(0.05)
        : ColorScheme.of(context).surface,
  );

  bool isSourcePage = appState.mainPage == Pages.source;
  List<Widget> centerChildren = [];
  List<Widget> rightWidgets = [];
  bool isOnlySearch = isShowSearch && isSearchToggled && isSourcePage;

  if (!isOnlySearch) {
    rightWidgets.add(const DownloadsIndicator());
    // If show queue button
    if (false)
      rightWidgets.add(
        Builder(builder: (ctx) {
          return IconButton(
              onPressed: () {
                gLogger.view('Queue toggled');
                Drawers.of(ctx).openEndDrawer();
              },
              icon: const Icon(PhosphorIconsThin.queue));
        }),
      );

    for (var c in rightControls) {
      assert(allowedRightControls.contains(c), 'Wrong control: $c');

      Widget? el = switch (c) {
        'settings' => isSourcePage
            ? IconButton(
                onPressed: () {
                  gLogger.view('Source settings clicked');
                  appState.triggerSourceEvent(appState.currentSource.sourceId,
                      'SourceSettingsClick', {});
                },
                icon: const Icon(PhosphorIconsThin.fadersHorizontal),
              )
            : null,
        _ => null,
      };
      if (el != null) {
        rightWidgets.add(el);
      }
    }

    if (isShowSearch && isSourcePage && rightControls.contains('search')) {
      rightWidgets.add(
        Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: IconButton(
              style: searchBtnStyle,
              onPressed: () {
                appState.isSearchToggled = !isSearchToggled;
                appState.update();

                if (appState.isSearchToggled && !searchFocusNode.hasFocus) {
                  searchFocusNode.requestFocus();
                }
              },
              icon: const Icon(PhosphorIconsThin.magnifyingGlass)),
        ),
      );
    }

    centerChildren = [
      Expanded(child: Text(headlineTitle, overflow: TextOverflow.fade)),
      const UpButton(),
    ];
  } else {
    centerChildren = [
      Expanded(
          child: Padding(
        padding: const EdgeInsets.only(left: 0.0, right: 8),
        child: SearchBox(
          focusNode: searchFocusNode,
          contentPadding: const EdgeInsets.only(),
          boxBg: ColorScheme.of(context).surface,
        ),
      )),
    ];
  }

  return AppBar(
    leading: !isOnlySearch
        ? Builder(builder: (ctx) {
            return IconButton(
                splashRadius: 28.0,
                onPressed: () {
                  Drawers.of(ctx).openDrawer();
                },
                icon: const Icon(PhosphorIconsThin.list));
          })
        : IconButton(
            onPressed: () {
              appState.isSearchToggled = false;
              appState.update();
            },
            icon: const Icon(PhosphorIconsThin.arrowLeft)),
    titleSpacing: 0.0,
    title: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: centerChildren,
    ),
    actions: rightWidgets,
  );
}

class UpButton extends StatelessWidget {
  const UpButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var appState = Provider.of<AppState>(context, listen: false);
    bool canBack = context.select<AppState, bool>((s) => s.canBack());
    return canBack
        ? IconButton(
            splashRadius: 28.0,
            iconSize: 24.0,
            onPressed: () {
              gLogger.view('getAppBar back');
              appState.back();
            },
            icon: const Icon(PhosphorIconsThin.caretUp))
        : const SizedBox.shrink();
  }
}

class SourceContents extends StatelessWidget {
  const SourceContents({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currPage = context.select<AppState, PageDescr>((s) => s.currPage);
    switch (currPage.type) {
      case PageDescrType.music:
        context.select<AppState, int>((s) => s.currMusicPage.updateIdx);
        return MusicSourceContents(currMusicPage: currPage as MusicPageDescr);
      case PageDescrType.controls:
        var appState = Provider.of<AppState>(context, listen: false);
        var source = appState.currentSource as PluginSource;
        List<Widget> ws = buildControls(
            (source.currPage as ControlsPageDescr).controls,
            source.mpJsRuntime,
            source.currPageId);
        return ScrollingPageWrapper(ws);
      case PageDescrType.webView:
        var appState = Provider.of<AppState>(context, listen: false);
        var source = appState.currentSource as PluginSource;
        return WebViewWidget(controller: source.webViewController!);
    }
  }
}

class MusicSourceContents extends StatelessWidget {
  const MusicSourceContents({
    Key? key,
    required this.currMusicPage,
  }) : super(key: key);

  final MusicPageDescr currMusicPage;

  @override
  Widget build(BuildContext context) {
    bool isModifyPlaylist = currMusicPage.isModifyPage;
    if (isModifyPlaylist) {
      return ModifyPlaylist(
        pageDescr: currMusicPage,
      );
    }
    return SectionsWrapper(currMusicPage);
  }
}

class MainPopScope extends StatelessWidget {
  const MainPopScope({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final canBack = context.select<AppState, bool>((s) => s.canBack());
    return PopScope(
      canPop: !canBack, // Allow pop if source can't go back anymore
      onPopInvokedWithResult: (didPop, result) {
        // NOTICE: takes pops even from Drawers
        gLogger.view('MainPopScope: didPop=$didPop');
        if (didPop) {
          return;
        }
        appState.back();
      },
      child: child,
    );
  }
}
