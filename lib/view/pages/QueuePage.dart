import 'package:flutter/material.dart';
import 'package:music_player/logger.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:music_player/logic/lang.dart';

import 'package:music_player/states/AppState.dart' show AppState;

import 'package:music_player/view/components/SelectionInfo.dart';
import 'package:music_player/view/components/Queue.dart';

const double appBarHeight = 54;

class QueuePage extends StatelessWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    gLogger.build(runtimeType);
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Column(
      children: [
        AppBar(
          leading: IconButton(
            icon: const Icon(PhosphorIconsThin.arrowLeft),
            onPressed: () => Provider.of<AppState>(context, listen: false)
                .closeEndDrawer(),
          ),
          title: Text(lang.Queue),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            Queue(
              width: width,
              height: height - appBarHeight,
            ),
            const Positioned(bottom: 30 + 40, child: SelectionInfo()),
          ],
        ),
      ],
    );
  }
}
