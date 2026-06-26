import 'package:music_player/logic/MusicItem.dart';
import 'package:music_player/logic/enums.dart';

class ItemAction {
  ItemAction({
    required this.text,
    required this.callback,
    this.icon,
  });
  String text;
  Future<void> Function(DialogFuncs dialogFuncs) callback;
  IconName? icon;
}

typedef OnAddFunc = void Function(String name, List<MusicItem> items);
typedef OnNewPlaylistFunc = void Function(String name, List<MusicItem> items);

class DialogFuncs {
  DialogFuncs({
    required this.openAddToPlaylistDialog,
    required this.openConfirmDialog,
    required this.closeDialog,
  });

  void Function({
    required List<MusicItem> tracklist,
    required OnAddFunc onAdd,
    required OnNewPlaylistFunc onNewPlaylist,
  }) openAddToPlaylistDialog;

  void Function({
    required String heading,
    required void Function() onConfirm,
    required void Function() onCancel,
  }) openConfirmDialog;

  void Function<T extends Object?>([T? result]) closeDialog;
}
