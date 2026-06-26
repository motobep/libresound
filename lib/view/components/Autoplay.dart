import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:music_player/logic/lang.dart' show lang;

import 'package:music_player/states/AppState.dart';
import 'package:music_player/states/AppearanceState.dart';

class AutoplayTile extends StatelessWidget {
  const AutoplayTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var autoplaySources =
        Provider.of<AppState>(context, listen: false).autoplaySources;
    String currentId =
        context.select<AppState, String>((s) => s.autoplaySources.currentId);
    List<(String, String)> names =
        context.select<AppState, List<(String, String)>>(
            (s) => s.autoplaySources.names);

    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);

    final currName = autoplaySources.get(currentId).$2;
    return MenuAnchor(
      menuChildren: <Widget>[
        for (var (id, name) in names)
          SizedBox(
            height: 32,
            child: MenuItemButton(
              onPressed: () {
                autoplaySources.setCurrent_n(id);
              },
              style: ButtonStyle(
                padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 12)),
              ),
              child: Text(name),
            ),
          ),
      ],
      builder: (_, MenuController controller, Widget? child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          child: Row(
            children: [
              TextButton(
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.all(
                      appearanceState.colors[ColorType.text]),
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                    side: BorderSide(
                        width: 1, color: appearanceState.lerpBgColor(0.10)),
                    borderRadius: BorderRadius.circular(12.0),
                  )),
                ),
                child: Icon(
                  currentId == '-'
                      ? PhosphorIconsThin.waveformSlash
                      : PhosphorIconsThin.waveform,
                  color: appearanceState.colors[ColorType.primary],
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '${lang.Autoplay}: $currName',
              ),
            ],
          ),
        );
      },
    );
  }
}

// class AutoplayBtn extends StatelessWidget {
//   const AutoplayBtn({
//     super.key,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     var autoplaySources =
//         Provider.of<AppState>(context, listen: false).autoplaySources;
//     String currentId =
//         context.select<AppState, String>((s) => s.autoplaySources.currentId);
//     List<(String, String)> names =
//         context.select<AppState, List<(String, String)>>(
//             (s) => s.autoplaySources.names);
//
//     final appearanceState =
//         Provider.of<AppearanceState>(context, listen: false);
//     return MenuAnchor(
//       menuChildren: <Widget>[
//         Container(
//           height: 35,
//           padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//           child: Text(
//             lang.Autoplay,
//             style: TextStyle(color: appearanceState.colors[ColorType.subtitle]),
//           ),
//         ),
//         for (var (id, name) in names)
//           SizedBox(
//             height: 32,
//             child: MenuItemButton(
//               onPressed: () {
//                 autoplaySources.setCurrent_n(id);
//               },
//               style: ButtonStyle(
//                 padding: WidgetStateProperty.all(
//                     const EdgeInsets.symmetric(vertical: 0, horizontal: 12)),
//               ),
//               child: Text(name),
//             ),
//           ),
//       ],
//       builder: (_, MenuController controller, Widget? child) {
//         return TextButton(
//           onPressed: () {
//             if (controller.isOpen) {
//               controller.close();
//             } else {
//               controller.open();
//             }
//           },
//           style: ButtonStyle(
//             foregroundColor:
//                 WidgetStateProperty.all(appearanceState.colors[ColorType.text]),
//             shape: WidgetStateProperty.all<RoundedRectangleBorder>(
//                 RoundedRectangleBorder(
//               side: BorderSide(
//                   width: 1, color: appearanceState.lerpBgColor(0.07)),
//               borderRadius: BorderRadius.circular(12.0),
//             )),
//           ),
//           child: currentId == '-'
//               ? Icon(
//                   PhosphorIconsThin.waveformSlash,
//                   color: appearanceState.colors[ColorType.primary],
//                   size: 20,
//                 )
//               : Row(
//                   children: [
//                     Icon(
//                       PhosphorIconsThin.waveform,
//                       color: appearanceState.colors[ColorType.primary],
//                       size: 20,
//                     ),
//                     const SizedBox(width: 5),
//                     Text(autoplaySources.get(currentId).$2),
//                   ],
//                 ),
//         );
//       },
//     );
//   }
// }
