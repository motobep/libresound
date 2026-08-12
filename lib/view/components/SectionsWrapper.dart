import 'package:flutter/material.dart';
import 'package:music_player/logger.dart';
import 'package:music_player/logic/Debouncer.dart';
import 'package:music_player/logic/EventRegistrar.dart';
import 'package:music_player/states/AppearanceState.dart';
import 'package:music_player/states/focus_states/SimpleListNavigator.dart';
import 'package:music_player/view/components/PageHeader.dart';
import 'package:provider/provider.dart';

import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logic/PageDescr.dart';
import 'package:music_player/logic/SectionDescr.dart';

import 'package:music_player/states/AppState.dart' show AppState;
import 'package:music_player/states/FocusState.dart';

import 'package:music_player/view/components/ItemsListView.dart';
import 'package:music_player/view/components/Section.dart';
import 'package:music_player/view/components/PreloaderWrapper.dart';
import 'package:music_player/view/components/buttons.dart';

final _scrollEndDebouncer = Debouncer(delay: const Duration(milliseconds: 200));

class SectionsWrapper extends StatelessWidget {
  const SectionsWrapper(
    this.currMusicPage, {
    Key? key,
  }) : super(key: key);

  final MusicPageDescr currMusicPage;

  @override
  Widget build(BuildContext context) {
    gLogger.build('SectionsWrapper');

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      gLogger.build('SectionsWrapper LayoutBuilder');
      AppState appState = Provider.of<AppState>(context, listen: false);
      List<SectionDescr> sectionlist = currMusicPage.sectionlist;
      final appearanceState =
          Provider.of<AppearanceState>(context, listen: false);

      // To keep Scroll
      final ScrollController scrollController = ScrollController(
          initialScrollOffset: currMusicPage.scrollPos, keepScrollOffset: true);

      FocusManagerState focusState =
          Provider.of<FocusManagerState>(context, listen: false);
      focusState.isNewPage =
          true; // WARNING: It's not good to put such logic on view but it's simplier

      var btnDescr = appState.currMusicPage.actionBtn;

      bool isPaneActive = context.select<FocusManagerState, bool>(
          (s) => s.focusStateI.type == 'BodyNav');
      double insetHeight = -1.0;

      var padding = const EdgeInsets.only(top: 6.0, bottom: 18.0);
      if (appState.isWide) {
        padding = const EdgeInsets.only(top: 16.0, bottom: 26.0);
      }

      Widget sliver;
      if (sectionlist.isNotEmpty && sectionlist[0].rowsCount == -1) {
        final headerHeight = (currMusicPage.header != null)
            ? calcPageHeaderHeight(currMusicPage.header!)
            : 0.0;
        insetHeight = constraints.maxHeight + headerHeight;

        if (isPaneActive) {
          focusState.bodyNavState.listNav.getScrollProps = () {
            return (
              ListNavitatorScrollProps(
                itemHeight: CONFIG.itemExtent,
                insetHeight: insetHeight,
                scrollPos: currMusicPage.scrollPos,
              ),
              scrollController
            );
          };
        }

        sliver = SliverPadding(
          padding: EdgeInsets.symmetric(
              horizontal: appearanceState.contentPaddingBaseHor),
          sliver: ItemsListView(currMusicPage),
        );
      } else {
        sliver = SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
                left: appearanceState.contentPaddingBaseHor,
                right: 4 + appearanceState.contentPaddingBaseHor,
                top: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var s in sectionlist)
                  Padding(
                    padding: padding,
                    child: Section(sectionDescr: s),
                  ),
                const SizedBox(height: CONFIG.listViewPadding),
              ],
            ),
          ),
        );
      }

      var customScrollView = CustomScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        // cacheExtent: 0,
        slivers: [
          if (currMusicPage.header != null)
            SliverToBoxAdapter(
                child: PageHeader(header: currMusicPage.header!)),
          sliver,
          if (!appState.isWide)
            const SliverToBoxAdapter(
                child: SizedBox(height: CONFIG.listViewGap)),
        ],
      );

      Widget w = NotificationListener<ScrollEndNotification>(
        key: Key(currMusicPage.hashCode.toString()),
        child: RefreshIndicator(
            strokeWidth: 2.0,
            child: customScrollView,
            onRefresh: () async {
              await appState.currentSource.reloadAsync();
            }),
        onNotification: (notification) {
          _scrollEndDebouncer.run(() {
            gLogger.debug('source scrollend');
            for (var l
                in eventRegistrar.musicSourceContentsScrollEndListeners) {
              l({
                'extentBefore': notification.metrics.extentBefore,
                'extentAfter': notification.metrics.extentAfter,
                'extentInside': notification.metrics.extentInside,
                'extentTotal': notification.metrics.extentTotal,
              });
            }
          });

          var pixels = notification.metrics.pixels;
          currMusicPage.scrollPos =
              pixels; // Notice: May be inefficient to use ScrollEndNotification

          if (isPaneActive) {
            var props = ListNavitatorScrollProps(
                scrollPos: currMusicPage.scrollPos,
                insetHeight: insetHeight,
                itemHeight: CONFIG.itemExtent);
            focusState.bodyNavState.putFocusInScrollU(props);
          }
          return true;
        },
      );

      return Stack(children: [
        PreloaderWrapper(w),
        if (btnDescr != null) CustomActionButton.fromDescr(btnDescr),
      ]);
    });
  }
}
