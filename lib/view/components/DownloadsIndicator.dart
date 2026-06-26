import 'package:flutter/material.dart';
import 'package:music_player/logger.dart';
import 'package:music_player/states/AppState.dart';
import 'package:music_player/states/AppearanceState.dart';
import 'package:provider/provider.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:music_player/states/DownloadsState.dart';

// Map m = {
//   '1': DownloadObj(
//       title:
//           'One lorem ipsum sit dolor amet. fafe. fasdfas. fasdfasd. feijiji jifwe mkjoajta One lorem ipsum sit dolor amet. fafe. fasdfas. fasdfasd. feijiji jifwe mkjoajta',
//       isRemovable: true),
//   '2': DownloadObj(title: 'Two', isRemovable: true),
//   '3': DownloadObj(title: 'Three', isRemovable: false),
//   '4': DownloadObj(title: 'Four', isRemovable: false),
// };

class DownloadsIndicator extends StatelessWidget {
  const DownloadsIndicator({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    DownloadsState downloadsState = context.watch<DownloadsState>();

    // return m.isNotEmpty
    return downloadsState.downloads.isNotEmpty
        ? InkWell(
            onTapUp: (details) {
              var pos = details.globalPosition;
              print('details="$pos"');
              _showDownloads(context, pos);
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              width: 34,
              height: 34,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        : const SizedBox.shrink();
  }
}

class _DownloadsMenu extends StatelessWidget {
  const _DownloadsMenu();

  @override
  Widget build(BuildContext context) {
    DownloadsState downloadsState = context.watch<DownloadsState>();

    const textStyle = TextStyle(color: Colors.white);
    if (downloadsState.downloads.isEmpty) {
      // if (m.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
        child: const Text(
          'Nothing downloading',
          style: textStyle,
        ),
      );
    }

    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var el in downloadsState.downloads.entries)
            // for (var el in m.entries)
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              margin: const EdgeInsets.only(bottom: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '${el.value.title}  ',
                      style: textStyle,
                      softWrap: true,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  el.value.isRemovable
                      ? GestureDetector(
                          child: const MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Icon(PhosphorIconsRegular.x, size: 20),
                          ),
                          onTap: () {
                            downloadsState.removeAndSafeAbort_n(el.key);
                          },
                        )
                      : const SizedBox.shrink(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

void _showDownloads(BuildContext context, Offset pos) {
  // var focusState = Provider.of<FocusManagerState>(context, listen: false);
  final appearanceState = Provider.of<AppearanceState>(context, listen: false);

  final decoration = BoxDecoration(
    color: ColorScheme.of(context).surface,
    boxShadow: const [
      BoxShadow(
          color: Color(0x20000000),
          blurRadius: 12.0,
          blurStyle: BlurStyle.outer)
    ],
    border: Border.all(color: appearanceState.lerpBgColor(0.07), width: 1.0),
    borderRadius: BorderRadius.circular(5.0),
  );
  const padding = EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0);

  final double width = MediaQuery.of(context).size.width;
  const double gap = 4;

  bool isWide = Provider.of<AppState>(context, listen: false).isWide;
  final w = (isWide)
      ? Positioned(
          right: width - pos.dx - 20,
          top: pos.dy + 25,
          child: Material(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500.0),
              decoration: decoration,
              padding: padding,
              child: const _DownloadsMenu(),
            ),
          ),
        )
      : Positioned(
          left: gap,
          top: pos.dy + 25,
          child: Material(
            child: Container(
              width: width - gap * 2,
              decoration: decoration,
              padding: padding,
              child: const _DownloadsMenu(),
            ),
          ),
        );

  showGeneralDialog(
    context: context,
    pageBuilder: (_, __, ___) {
      return PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          gLogger.view('didPop: $didPop');
          if (didPop) {
            return;
          }
          // focusState.unfocusActions();
        },
        child: Stack(children: [w]),
      );
    },
    barrierColor: Colors.transparent,
    barrierDismissible: true,
    barrierLabel: 'downloads_barrier',
  );
}
