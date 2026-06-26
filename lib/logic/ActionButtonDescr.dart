import 'package:music_player/logic/enums.dart';

class ActionBtnDescr {
  ActionBtnDescr({
    this.text = '',
    this.icon,
    required this.onTap,
  });
  final String text;
  final IconName? icon;
  final void Function() onTap;

  Map toJson() {
    return {
      'text': text,
      'iconName': icon?.name,
    };
  }
}
