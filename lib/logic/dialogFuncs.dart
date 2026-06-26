import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:music_player/logic/DialogDescr.dart';
import 'package:music_player/logic/lang.dart';

import 'package:music_player/states/FocusState.dart';

// WARNING: view in logic
import 'package:music_player/view/App.dart';
import 'package:music_player/view/components/dialogs.dart';

// TODO: use inner functions directly
DialogFuncs getDialogFuncs() {
  var context = navigatorKey.currentContext!;
  DialogFuncs dialogFuncs = DialogFuncs(
    openAddToPlaylistDialog: (
        {required tracklist, required onAdd, required onNewPlaylist}) {
      showDialog(
        context: context,
        builder: (context) => AddToPlaylistDialog(
            tracklist: tracklist, onAdd: onAdd, onNewPlaylist: onNewPlaylist),
      );
    },
    openConfirmDialog: (
        {required heading, required onConfirm, required onCancel}) async {
      bool? isConfirm = await showDialog<bool>(
        context: context,
        builder: (context) => ConfirmDialog(
          heading: heading,
          confirmText: lang.Ok,
          cancelText: lang.Cancel,
        ),
      );

      if (isConfirm != null && isConfirm == true) {
        onConfirm();
      } else {
        onCancel();
      }
    },
    closeDialog: closeActions,
  );
  return dialogFuncs;
}

void closeActions<T extends Object?>([T? result]) {
  var context = navigatorKey.currentContext!;
  var focusState = Provider.of<FocusManagerState>(context, listen: false);
  focusState.unfocusActions();
}
