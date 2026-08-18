import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import 'package:file/file.dart' as filePkg;
import 'package:music_player/logic/fs/filesHighLevel.dart' as fsHighLevel;

import 'package:music_player/logger.dart';
import 'package:music_player/config.dart' show fileSystem;
import 'package:music_player/logic/DialogDescr.dart' show ItemAction;
import 'package:music_player/logic/GroupItem.dart';
import 'package:music_player/logic/Item.dart';
import 'package:music_player/logic/PageDescr.dart';
import 'package:music_player/logic/PluginSource.dart';
import 'package:music_player/logic/dialogFuncs.dart';
import 'package:music_player/logic/lang.dart';
import 'package:music_player/logic/MusicItem.dart';
import 'package:music_player/logic/enums.dart';
import 'package:music_player/logic/utils.dart' as utils;
import 'package:music_player/logic/fs/download_funcs.dart';

import 'package:music_player/states/PlaybackState.dart';
import 'package:music_player/states/AppState.dart' show AppState;
import 'package:music_player/states/FocusState.dart';
import 'package:music_player/states/SelectionState.dart';

import 'package:flutter/material.dart'
    show Offset, showDialog, Padding, EdgeInsets, Text;
import 'package:music_player/view/App.dart' show navigatorKey;

// WARNING FIXME later: view in logic
import 'package:music_player/view/components/dialogs.dart' as dialogs;
import 'package:music_player/view/components/itemActions.dart' as itemActions;

Future<void> onItemTapHandler(int index, int sectionId) async {
  var context = navigatorKey.currentContext!;
  var appState = Provider.of<AppState>(context, listen: false);
  var currPage = appState.currMusicPage;
  var itemlist = _getItemList(currPage, sectionId);

  bool isMi = itemlist[0] is MusicItem;
  if (isMi) {
    var playback = Provider.of<PlaybackState>(context, listen: false).playback;
    playback.load([...(itemlist as List<MusicItem>)]);
    appState.invalidateQueueScrollOffset();

    await appState.playback.playByIdx_n(index);
    // appState.update();
  } else {
    await appState.chooseGroupAsync(itemlist[index] as GroupItem);
  }
}

/* Future<void> onMusicItemTapHandler(int index, int sectionId) async {
  var context = navigatorKey.currentContext!;
  var appState = Provider.of<AppState>(context, listen: false);
  var currPage = appState.currMusicPage;

  var itemlist = _getItemList(currPage, sectionId);
} */

/* void onGroupItemTapHandler(int index, int sectionId) {
  var context = navigatorKey.currentContext!;
  var appState = Provider.of<AppState>(context, listen: false);
  var currPage = appState.currMusicPage;

  List<GroupItem> itemlist =
      _getItemList(currPage, sectionId) as List<GroupItem>;
} */

List<Item> _getItemList(MusicPageDescr currPage, int sectionId) {
  var s = currPage.findSection(sectionId);
  return s != null ? s.itemlist : [];
}

void showCurrItemDialog(
  MusicItem musicItem, {
  required int sectionIndex,
}) {
  showItemDialog(-1, musicItem, sectionIndex: sectionIndex);
}

void showItemDialog(
  int index,
  Item item, {
  required int sectionIndex,
  Offset? tapPos,
}) async {
  var context = navigatorKey.currentContext!;
  AppState appState = Provider.of<AppState>(context, listen: false);
  final sourceId = item.sourceId;
  final source = appState.sources[sourceId]!;

  List<ItemAction> actions = [];
  if (item is MusicItem) {
    actions = appState.getDefaultActions([item]);
  }
  actions.add(ItemAction(
    icon: IconName.clear,
    text: lang.Clear_queue,
    callback: (dialogFuncs) async {
      dialogFuncs.closeDialog();
      appState.playback.clearQueue_n();
    },
  ));
  actions.addAll(
    await source.buildActionsAsync(IndexedItem(index, item), sectionIndex),
  );
  await showActionsDialog(actions,
      tapPos: tapPos != null ? [tapPos.dx, tapPos.dy] : null,
      onExit: source is PluginSource
          ? () {
              logger.green('free actions pool');
              source.freeAcitonsPoolAsync();
            }
          : null);
}

Future<void> showMultiActions(Map<String, List<IndexedItem>> indexedItemMap,
    void Function() cancel) async {
  var context = navigatorKey.currentContext!;
  AppState appState = Provider.of<AppState>(context, listen: false);
  var selectionState = Provider.of<SelectionState>(context, listen: false);

  List<MusicItem> items = [];
  for (var e in indexedItemMap.entries) {
    for (var el in e.value) {
      items.add(el.item as MusicItem);
    }
  }
  List<ItemAction> actions = appState.getDefaultActions(items, cancel);
  // List<ItemAction> actions = [];

  final sourceId = items[0].sourceId;
  final source = appState.sources[sourceId]!;

  if (selectionState.isOnlySource) {
    actions.addAll(await source.buildMultiActionsAsync(indexedItemMap, cancel));
  }

  // showActionsDialog(actions);
  await showActionsDialog(actions,
      onExit: source is PluginSource
          ? () {
              logger.green('free actions pool');
              source.freeAcitonsPoolAsync();
            }
          : null);
}

Future<void> showActionsDialog(List<ItemAction> actions,
    {List<double>? tapPos, void Function()? onExit}) async {
  var context = navigatorKey.currentContext!;

  final focusState = Provider.of<FocusManagerState>(context, listen: false);
  focusState.focusActions();

  focusState.actionsState.update(
    actions: actions,
    dialogFuncs: getDialogFuncs(),
    onExit: onExit,
  );

  if (tapPos != null) {
    itemActions.showActionsContextMenu(context, Offset(tapPos[0], tapPos[1]));
    return;
  }
  final isWide = Provider.of<AppState>(context, listen: false).isWide;
  if (isWide) {
    itemActions.showActionsDialog(context);
  } else {
    itemActions.showActionsBottomSheet(context);
  }
}

void shuffleAction() async {
  var context = navigatorKey.currentContext!;
  var appState = Provider.of<AppState>(context, listen: false);
  var playback = Provider.of<PlaybackState>(context, listen: false).playback;
  var itemlist = appState.currMusicPage.sectionlist[0].itemlist;
  bool isEmptyTracklist = itemlist.isEmpty;

  if (isEmptyTracklist) return;
  playback.load([...(itemlist as List<MusicItem>)]);
  await playback.shuffle();

  appState.invalidateQueueScrollOffset();
  appState.update();
}

void showCreatePlaylistDialog() async {
  var context = navigatorKey.currentContext!;
  var appState = Provider.of<AppState>(context, listen: false);

  String? name = await showDialog<String>(
    context: context,
    builder: (context) => dialogs.TextDialog(
      title: lang.New_playlist,
      hintText: lang.Name,
    ),
  );
  if (name != null && name.isNotEmpty) {
    appState.fsSource.playlistHandler.createPlaylist_n(name);
  }
}

// TODO: Move else
void reloadFsSource() {
  var context = navigatorKey.currentContext!;
  AppState appState = Provider.of<AppState>(context, listen: false);
  appState.reloadFsSource();
}

// TODO: Move else
Future<String?> saveCachedMiAsync(MusicItem mi) async {
  var context = navigatorKey.currentContext!;
  AppState appState = Provider.of<AppState>(context, listen: false);

  String sourceDirPath = appState.config.musicSourceDir!.path;
  String escapedName = utils.escapeFilename(mi.title);
  String filepath = '$sourceDirPath/$escapedName${mi.extension}';
  if (!appState.config.isMusicSourceDirValid()) {
    return 'INVALID_SOURCE_DIR';
  }
  try {
    await saveWebFileCached(filepath, mi);
  } catch (e) {
    return 'EXCEPTION: $e';
  }
  return null;
}

// TODO: Move else
Future<String?> saveMiAsync(MusicItem mi, List<int> bytes) async {
  var context = navigatorKey.currentContext!;
  AppState appState = Provider.of<AppState>(context, listen: false);

  String sourceDirPath = appState.config.musicSourceDir!.path;
  String escapedName = utils.escapeFilename(mi.title);
  String filepath = '$sourceDirPath/$escapedName${mi.extension}';
  if (!appState.config.isMusicSourceDirValid()) {
    return 'INVALID_SOURCE_DIR';
  }
  try {
    // TODO: remove comment
    // await saveWebFileCached(filepath, mi);
    // TODO: Refactor
    var f = fileSystem.file(filepath);
    if (f.existsSync()) {
      filePkg.File? renamedFile;
      for (var i = 1; i < 65536; i++) {
        String base = p.withoutExtension(f.path);
        String ext = p.extension(f.path);
        String renamedPath = '${base} ($i)${ext}';
        logger.log('saveMiAsync: testing renamed path "$renamedPath"');
        renamedFile = fileSystem.file(renamedPath);
        if (!renamedFile.existsSync()) {
          break;
        }
      }
      if (renamedFile == null) {
        throw Exception('So lucky to have this many files');
      }
      logger.warn('saveMiAsync: file "${f.path}" exists');
      String? dialogResult = await showDialog<String>(
        context: context,
        builder: (context) => dialogs.RenameFileDialog(
          fileOriginal: f.path,
          fileRenamed: renamedFile!.path,
        ),
      );
      if (dialogResult != null && dialogResult == 'overwrite') {
        logger.log('overwrite');
        bool ok = await fsHighLevel.deleteFilesAsync([f.path]);
        if (!ok) {
          logger.error("saveMiAsync: couldn't delete file '${f.path}'");
        }
      } else if (dialogResult != null && dialogResult == 'rename') {
        logger.log('rename');
        f = renamedFile;
      } else {
        logger.warn('canceled');
        return 'FILE_WRITE_FAILED';
      }
    }
    if (f.existsSync()) {
      logger.error('Should not exist at this point of time');
    }
    bool ok = await writeBytesWithTagsToFile(bytes, f.path, mi);
    if (!ok) {
      return 'FILE_WRITE_FAILED';
    }
  } catch (e) {
    return 'EXCEPTION: $e';
  }
  return null;
}

final Logger logger = Logger(prefix: 'tapHandlers: ');
