import 'package:flutter/material.dart';
import 'package:music_player/logger.dart';
import 'package:music_player/states/AppState.dart';
import 'package:music_player/states/AppearanceState.dart';
import 'package:music_player/view/PageRouter.dart';
import 'package:music_player/view/components/DownloadsIndicator.dart';
import 'package:music_player/view/components/SelectionInfo.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

class Header extends StatelessWidget {
  const Header({
    super.key,
    required this.title,
    required this.upBtn,
    required this.width,
    required this.searchWideOrContainer,
    required this.isRightPanelOpen,
    required this.onRightPanelToggle,
  });

  final String title;
  final Widget upBtn;
  final double width;
  final Widget searchWideOrContainer;

  final bool isRightPanelOpen;
  final void Function() onRightPanelToggle;

  @override
  Widget build(BuildContext context) {
    var secondaryColor = Theme.of(context).colorScheme.secondary;
    bool isShowLyrics = context.select<AppState, bool>((s) => s.isShowLyrics);
    bool hasLyrics = context.select<AppState, bool>((s) => s.hasLyrics);

    final appState = Provider.of<AppState>(context, listen: false);
    List? sortItems = context
        .select<AppState, List?>((s) => s.fsSource.currPage.props['sortItems']);

    // Right controls
    List<Widget> rightWidgets = [
      const DownloadsIndicator(),
      const SelectionInfo(),
      // Sort button
      if (sortItems != null)
        InkWell(
          onTapUp: (details) {
            gLogger.debug('sort');
            var pos = details.globalPosition;
            showSortByContextMenu(context, pos);
          },
          mouseCursor: SystemMouseCursors.click,
          child: const Icon(PhosphorIconsThin.sortAscending),
        ),
    ];

    List<String> rightControls = context
        .select<AppState, List<String>>((s) => s.currentSource.rightControls);
    // Settings btn
    if (rightControls.contains('settings')) {
      final el = IconButton(
          onPressed: () {
            gLogger.view('Source settings clicked');
            appState.triggerSourceEvent(
                appState.currentSource.sourceId, 'SourceSettingsClick', {});
          },
          icon: const Icon(PhosphorIconsThin.fadersHorizontal));
      rightWidgets.add(el);
    }

    // Queue/Lyrics switch
    if (hasLyrics) {
      final appearanceState =
          Provider.of<AppearanceState>(context, listen: false);
      var style = ButtonStyle(
        padding: const WidgetStatePropertyAll(EdgeInsets.all(4)),
        minimumSize: WidgetStateProperty.all(const Size.square(0)),
      );

      Widget w = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            border: Border.all(
                color: appearanceState.lerpBgColor(0.07), width: 1.0),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  gLogger.log('onTap');
                  appState.isLyricsSelected = false;
                  appState.update();
                },
                icon: const Icon(PhosphorIconsThin.queue),
                color: isShowLyrics ? secondaryColor : null,
                style: style,
              ),
              const SizedBox(width: 5),
              IconButton(
                onPressed: () {
                  gLogger.log('onTap');
                  appState.isLyricsSelected = true;
                  appState.update();
                },
                icon: const Icon(PhosphorIconsThin.textT),
                color: !isShowLyrics ? secondaryColor : null,
                style: style,
              ),
            ],
          ),
        ),
      );
      rightWidgets.add(w);
    }

    // Toggle btn
    final toggleBtn = IconButton(
        onPressed: onRightPanelToggle,
        icon: Icon(
          isRightPanelOpen
              ? PhosphorIconsThin.caretLineRight
              : PhosphorIconsThin.caretLineLeft,
        ));
    rightWidgets.add(toggleBtn);

    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Container(
        color: ColorScheme.of(context).surface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16)),
                  upBtn,
                ],
              ),
            ),
            Container(
              width: width * 0.3,
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              // color: Colors.red,
              child: Row(
                children: [
                  Expanded(child: searchWideOrContainer),
                ],
              ),
            ),
            Expanded(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: rightWidgets,
            )),
          ],
        ),
      ),
    );
  }
}

void showSortByContextMenu(BuildContext context, Offset pos) {
  double vh = MediaQuery.of(context).size.height;
  double vw = MediaQuery.of(context).size.width;
  const double iconSize = 20;
  final top = pos.dy + 8.0 > vh ? pos.dy - iconSize - 10 : pos.dy + 10;
  final right = vw - pos.dx;

  final appState = Provider.of<AppState>(context, listen: false);
  final appearanceState = Provider.of<AppearanceState>(context, listen: false);

  final sortItems = appState.fsSource.buildSortItems();
  final sortBy = appState.fsSource.getSortBy();

  showGeneralDialog(
    context: context,
    pageBuilder: (_, __, ___) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          gLogger.debug('didPop: $didPop');
          if (didPop) {
            return;
          }
          PageRouter.back(context);
        },
        child: Stack(
          children: [
            Positioned(
              right: right,
              top: top,
              child: Material(
                child: Container(
                  decoration: BoxDecoration(
                    color: ColorScheme.of(context).surface,
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x20000000),
                          blurRadius: 12.0,
                          blurStyle: BlurStyle.outer)
                    ],
                    border: Border.all(
                        color: appearanceState.lerpBgColor(0.07), width: 1.0),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4),
                  child: IntrinsicWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var el in sortItems)
                          TextButton.icon(
                            onPressed: () {
                              PageRouter.back(context);
                              appState.fsSource.setSortItem(el.$1);
                            },
                            iconAlignment: IconAlignment.end,
                            icon: Icon(
                              el.$1.name.endsWith('Asc')
                                  ? PhosphorIconsThin.arrowDown
                                  : PhosphorIconsThin.arrowUp,
                              color: el.$1 == sortBy
                                  ? ColorScheme.of(context).primary
                                  : ColorScheme.of(context).onSurface,
                            ),
                            label: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                el.$2,
                                style: TextStyle(
                                  color: el.$1 == sortBy
                                      ? ColorScheme.of(context).primary
                                      : ColorScheme.of(context).onSurface,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
    // barrierColor: Colors.black12,
    barrierColor: Colors.transparent,
    barrierDismissible: true,
    barrierLabel: 'barrier_label',
  );
}
