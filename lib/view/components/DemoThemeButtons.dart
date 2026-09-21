import 'package:flutter/material.dart';
import 'package:music_player/states/AppearanceState.dart'
    show DemoPreset, AppearanceState;
import 'package:music_player/view/components/buttons.dart'
    show OutlinedStandardButton;
import 'package:provider/provider.dart';

class DemoThemeButtons extends StatefulWidget {
  const DemoThemeButtons({super.key});

  @override
  State<DemoThemeButtons> createState() => _DemoThemeButtonsState();
}

class _DemoThemeButtonsState extends State<DemoThemeButtons> {
  bool isShow = true;

  @override
  Widget build(BuildContext context) {
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);

    return Wrap(
      children: [
        if (isShow)
          for (var preset in DemoPreset.values) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: OutlinedStandardButton(
                preset.name,
                onTap: () {
                  appearanceState.setDemoPreset(preset);
                },
              ),
            ),
          ],
        TextButton(
          child: Text('toggle',
              style: TextStyle(
                  color: !isShow ? Colors.transparent : null)),
          onPressed: () {
            isShow = !isShow;
            setState(() {});
          },
        ),
      ],
    );
  }
}
