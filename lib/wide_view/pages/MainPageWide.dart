import 'dart:math' show max, min;

import 'package:flutter/material.dart';
import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logger.dart';
import 'package:music_player/main.dart' show config;
import 'package:music_player/states/FocusState.dart';
import 'package:music_player/view/App.dart' show searchFocusNode;
import 'package:music_player/view/components/QueueOrLyrics.dart';
import 'package:music_player/wide_view/pages/Header.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import 'package:music_player/logic/Config.dart';
import 'package:music_player/logic/enums.dart';

import 'package:music_player/states/AppState.dart';
import 'package:music_player/states/AppearanceState.dart';

import 'package:music_player/view/components/Tabs.dart';
import 'package:music_player/view/components/TopTabs.dart';
import 'package:music_player/view/components/SearchBox.dart';
import 'package:music_player/view/pages/AppearancePage.dart';
import 'package:music_player/view/pages/PluginsPage.dart';
import 'package:music_player/view/pages/SettingsPage.dart';
import 'package:music_player/view/pages/SyncPage.dart';
import 'package:music_player/view/addGuardsFuncs.dart';
import 'package:music_player/view/pages/MainPage.dart';

import 'package:music_player/wide_view/components/BottomControlsWide.dart';
import 'package:music_player/view/components/Sidebar.dart';
import 'package:music_player/wide_view/components/ResizableSeparator.dart';

const double separatorWidth = 9.0;

const double kSidebarWidthPercentage = 0.2;
const double kRightPanelWidthPercentage = 0.3;
const bool kIsRightPanelOpen = true;

class MainPageWide extends StatefulWidget {
  const MainPageWide({super.key});

  @override
  State<MainPageWide> createState() => _MainPageWideState();
}

class _MainPageWideState extends State<MainPageWide> {
  double sidebarWidthPercentage = kSidebarWidthPercentage;
  final minSidebarWidth = 0.15;
  final maxSidebarWidth = 0.30;

  bool isRightPanelOpen = kIsRightPanelOpen;
  double rightPanelWidthPercentage = kRightPanelWidthPercentage;
  final minRightPanelWidth = 0.20;
  final maxRightPanelWidth = 0.40;

  @override
  void initState() {
    Config config = Provider.of<AppState>(context, listen: false).config;
    sidebarWidthPercentage =
        config.getProperty('sidebarWidthPercentage') ?? kSidebarWidthPercentage;
    rightPanelWidthPercentage =
        config.getProperty('rightPanelWidthPercentage') ??
            kRightPanelWidthPercentage;
    isRightPanelOpen =
        config.getProperty('isRightPanelOpen') ?? kIsRightPanelOpen;
    super.initState();
  }

  void _updateSidebarWidth(DragUpdateDetails details) {
    final width = MediaQuery.of(context).size.width;
    setState(() {
      sidebarWidthPercentage = _calcWidth(sidebarWidthPercentage, width,
          -details.delta.dx, minSidebarWidth, maxSidebarWidth);
    });
  }

  void _updateQueueWidth(DragUpdateDetails details) {
    final width = MediaQuery.of(context).size.width;
    setState(() {
      rightPanelWidthPercentage = _calcWidth(rightPanelWidthPercentage, width,
          details.delta.dx, minRightPanelWidth, maxRightPanelWidth);
    });
  }

  @override
  Widget build(BuildContext context) {
    Pages mainPage = context.select<AppState, Pages>((s) => s.mainPage);
    Config config = Provider.of<AppState>(context, listen: false).config;
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    String headlineTitle =
        context.select<AppState, String>((s) => s.headlineTitle);
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);

    late Widget mainBody;
    Widget searchWideOrContainer = const SizedBox.shrink();
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
        Widget body = addGuardsToPageBody(const BodyWide(), context);
        mainBody = body;
        searchWideOrContainer = SearchBox(
          focusNode: searchFocusNode,
          prefixIcon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Icon(
              PhosphorIconsThin.magnifyingGlass,
              size: 24,
              color: ColorScheme.of(context).onSurface,
            ),
          ),
          boxBg: appearanceState.lerpBgColor(0.05),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        );
        break;
    }

    Color separatorColor =
        context.select<AppearanceState, Color>((s) => s.separatorColor());

    final focusManager = Provider.of<FocusManagerState>(context, listen: false);

    return Scaffold(
      body: Column(
        children: [
          Header(
              title: headlineTitle,
              upBtn: const UpButton(),
              width: width,
              searchWideOrContainer: searchWideOrContainer,
              isRightPanelOpen: isRightPanelOpen,
              onRightPanelToggle: () {
                gLogger.view('(Wide) Right panel toggled');
                // Toggle queue
                setState(() {
                  isRightPanelOpen = !isRightPanelOpen;
                  config.saveProperty('isRightPanelOpen', isRightPanelOpen);
                  if (!isRightPanelOpen) focusManager.focusBody();
                });
              }),
          Container(
            height: 1,
            color: separatorColor,
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Sidebar(width: width * sidebarWidthPercentage),
                ResizeableSeparator(
                    onHorizontalDragUpdate: _updateSidebarWidth,
                    onHorizontalDragEnd: (details) {
                      config.saveProperty(
                          'sidebarWidthPercentage', sidebarWidthPercentage);
                    },
                    width: separatorWidth,
                    height: height,
                    separatorColor: separatorColor),
                Expanded(
                  child: MainPopScope(
                    child: mainBody,
                  ),
                ),
                if (isRightPanelOpen)
                  ResizeableSeparator(
                      onHorizontalDragUpdate: _updateQueueWidth,
                      onHorizontalDragEnd: (details) {
                        config.saveProperty('rightPanelWidthPercentage',
                            rightPanelWidthPercentage);
                      },
                      width: separatorWidth,
                      height: height,
                      separatorColor: separatorColor),
                if (isRightPanelOpen)
                  QueueOrLyrics(
                      width: width * rightPanelWidthPercentage, height: height)
              ],
            ),
          ),
          const BottomControlsWide(),
        ],
      ),
    );
  }
}

double _calcWidth(double width, double fullWidth, double dx, double minWidth,
    double maxWidth) {
  double boxWidth = (width * fullWidth);
  if (dx.isNegative) {
    width = min(maxWidth, (boxWidth + dx.abs()) / fullWidth);
  } else {
    width = max(minWidth, (boxWidth - dx.abs()) / fullWidth);
  }
  return width;
}

class BodyWide extends StatelessWidget {
  const BodyWide({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var navType =
        context.select<AppState, NavType>((s) => s.currentSource.navType);

    List<String> searchCats = context
        .select<AppState, List<String>>((s) => s.currentSource.getSearchTabs());

    final idx = context
        .select<AppState, int>((app) => app.currentSource.currSearchTabIdx);

    final appState = Provider.of<AppState>(context, listen: false);

    var mainAxisAlignment = appState.isWide
        ? MainAxisAlignment.start
        : MainAxisAlignment.spaceBetween;

    switch (navType) {
      case NavType.tabs:
        return const Column(
          children: [
            Expanded(child: SourceContents()),
            Tabs(),
          ],
        );
      case NavType.searchTabs:
        return Column(
          children: [
            if (searchCats.isNotEmpty && idx >= 0)
              TopTabs(
                elements: searchCats,
                initial: idx,
                onSelect: (index) {
                  appState.chooseSearchTabAsync(index);
                  return false;
                },
                mainAxisAlignment: mainAxisAlignment,
              ),
            const Expanded(child: SourceContents()),
          ],
        );
      case NavType.none:
        return const Column(
          children: [
            Expanded(child: SourceContents()),
          ],
        );
    }
  }
}

bool checkContentWide(double width) {
  double contentWidth = width * calcContentWidthPercentage();
  return width > CONFIG.widthWideStart && contentWidth >= 768;
}

double calcContentWidthPercentage() {
  var sidebarWidthPercentage =
      config.getProperty('sidebarWidthPercentage') ?? kSidebarWidthPercentage;
  var rightPanelWidthPercentage =
      config.getProperty('rightPanelWidthPercentage') ??
          kRightPanelWidthPercentage;
  var isRightPanelOpen =
      config.getProperty('isRightPanelOpen') ?? kIsRightPanelOpen;

  return 1.0 -
      sidebarWidthPercentage -
      rightPanelWidthPercentage * (isRightPanelOpen ? 1 : 0);
}
