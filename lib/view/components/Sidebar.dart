import 'package:music_player/logger.dart' show gLogger;
import 'package:music_player/logic/PluginManager.dart' show PluginManager;
import 'package:music_player/logic/plugins.dart';
import 'package:music_player/main.dart' show config;
import 'package:music_player/states/focus_states/SimpleListNavigator.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logic/lang.dart';

import 'package:music_player/states/AppState.dart' show AppState;
import 'package:music_player/states/AppearanceState.dart';
import 'package:music_player/states/FocusState.dart';

import 'package:music_player/view/components/buttons.dart';

class SlidingSidebar extends StatelessWidget {
  const SlidingSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(PhosphorIconsThin.arrowLeft),
          onPressed: () =>
              Provider.of<AppState>(context, listen: false).closeDrawer(),
        ),
        actions: const [SizedBox()],
      ),
      body: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 0.0),
        child: Sidebar(width: null, isWide: false),
      ),
    );
  }
}

class Sidebar extends StatefulWidget {
  const Sidebar({
    super.key,
    required this.width,
    this.isWide = true,
  });

  final double? width;
  final bool isWide;

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  ScrollController? _scrollController;

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor =
        context.select<AppearanceState, Color>((s) => s.colors[ColorType.bg]!);

    // To update plugin sources list
    context.select<AppState, int>((app) => app.sources.length);
    final pluginSources = context.select<AppState, Iterable<PluginInfo>>(
        (app) => app.pluginManager.pluginsList.where((p) =>
            p.isSource &&
            p.status == PluginInfoStatus.loaded &&
            app.sources.containsKey(p.id)));

    final pluginUpdatesCount = context
        .select<AppState, int>((s) => s.pluginManager.pluginUpdatesCount);

    final lang = context.select<AppearanceState, Lang>((s) => s.lang);
    final appState = Provider.of<AppState>(context, listen: false);

    var baseInfo = [
      _Btn(lang.Settings, PhosphorIconsThin.gearSix),
      _Btn(lang.Appearance, PhosphorIconsThin.palette),
      _Btn(lang.Sync, PhosphorIconsThin.arrowsLeftRight),
      _Btn(
        lang.Plugins,
        PhosphorIconsThin.puzzlePiece,
        endWidget: pluginUpdatesCount > 0
            ? Icon(
                PhosphorIconsFill.dotOutline,
                size: 26,
                color: ColorScheme.of(context).secondary,
              )
            : null,
      ),
      _Btn(lang.Files, PhosphorIconsThin.folders),
      if (appState.sources.containsKey(CONFIG.tempFsSourceId))
        _Btn(lang.Selected_folder, PhosphorIconsThin.folderDashed),
    ];
    var sourcesInfo = [
      for (var p in pluginSources)
        _Btn(
          p.titleTranslated(),
          PhosphorIconsThin.plugs,
          endWidget: CONFIG.isDev()
              ? IconButton(
                  icon: const Icon(PhosphorIconsThin.arrowCounterClockwise),
                  onPressed: () {
                    appState.reloadPlugin(p);
                  },
                )
              : null,
        ),
    ];
    var textWithIconList = baseInfo + sourcesInfo;

    final padding = widget.isWide
        ? const EdgeInsets.only(left: 4.5, top: 4.0)
        : const EdgeInsets.only(left: 0.0, top: 0.0);

    return Container(
      color: bgColor,
      width: widget.width,
      padding: padding,
      child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
        bool isPaneActive = context.select<FocusManagerState, bool>(
            (s) => s.focusStateI.type == 'SidebarNav');
        int focusIndex = isPaneActive
            ? context.select<FocusManagerState, int>(
                (s) => s.sidebarNavState.listNav.index)
            : -1;
        FocusManagerState focusState =
            Provider.of<FocusManagerState>(context, listen: false);

        double insetHeight = constraints.maxHeight;

        _scrollController ??= ScrollController();

        if (isPaneActive) {
          final scrollPos =
              _scrollController!.hasClients ? _scrollController!.offset : 0.0;
          focusState.sidebarNavState.listNav.getScrollProps = () {
            return (
              ListNavitatorScrollProps(
                itemHeight: CONFIG.sidebarItemExtent,
                insetHeight: insetHeight,
                scrollPos: scrollPos,
              ),
              _scrollController!
            );
          };
        }

        List<ListButton> sidebarWidgets = [
          ..._toButtons(textWithIconList, isPaneActive, focusIndex,
              focusState: focusState),
        ];

        return NotificationListener<ScrollEndNotification>(
          child: ListView(
            itemExtent: CONFIG.sidebarItemExtent,
            controller: _scrollController,
            children: sidebarWidgets,
          ),
          onNotification: (notification) {
            var pixels = notification.metrics.pixels;

            if (isPaneActive) {
              var props = ListNavitatorScrollProps(
                  scrollPos: pixels,
                  insetHeight: insetHeight,
                  itemHeight: CONFIG.sidebarItemExtent);
              focusState.queueNavState.putFocusInScrollU(props);
            }
            return true;
          },
        );
      }),
    );
  }
}

class _Btn {
  String text;
  PhosphorFlatIconData icon;
  Widget? endWidget;
  _Btn(this.text, this.icon, {this.endWidget});
}

List<ListButton> _toButtons(
    List<_Btn> btnDescrs, bool isPaneActive, int focusIndex,
    {required FocusManagerState focusState}) {
  return [
    for (var (i, btn) in btnDescrs.indexed)
      ListButton(
        btn.text,
        onTap: () {
          focusState.onSidebarClick(i);
        },
        icon: btn.icon,
        isFocused: isPaneActive && focusIndex == i,
        endWidget: btn.endWidget,
      )
  ];
}
