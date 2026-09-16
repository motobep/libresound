import 'package:flutter/material.dart';
import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logic/Source.dart' show Source;
import 'package:music_player/logic/enums.dart' show Pages;
import 'package:music_player/states/AppearanceState.dart';
import 'package:music_player/view/PageRouter.dart';
import 'package:provider/provider.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:music_player/states/AppState.dart';

import 'package:music_player/logger.dart';

class SortByWidget extends StatelessWidget {
  const SortByWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final mainPage = context.select<AppState, Pages>((s) => s.mainPage);
    final source = context.select<AppState, Source>((s) => s.currentSource);
    List? sortItems = context
        .select<AppState, List?>((s) => s.fsSource.currPage.props['sortItems']);

    if (mainPage != Pages.source ||
        source.sourceId != CONFIG.fsSourceId ||
        sortItems == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 6.0, right: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTapUp: (details) {
            gLogger.debug('sort');
            var pos = details.globalPosition;
            showSortByContextMenu(context, pos);
          },
          mouseCursor: SystemMouseCursors.click,
          customBorder: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(CONFIG.Default.iconOverlayRadius),
          ),
          child: const SizedBox(
            width: CONFIG.Default.iconSize,
            height: CONFIG.Default.iconSize,
            child: Icon(PhosphorIconsThin.sortAscending),
          ),
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
                color: appearanceState.overBgColorWithAlpha(),
                child: Container(
                  decoration: BoxDecoration(
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
