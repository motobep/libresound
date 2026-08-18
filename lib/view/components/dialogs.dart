import 'dart:math';

import 'package:flutter/material.dart';
import 'package:m4a_tags_handler/Tags.dart' show PictureTag;
import 'package:music_player/logger.dart';
import 'package:music_player/logic/lang.dart';
import 'package:music_player/states/AppearanceState.dart';
import 'package:music_player/states/FocusState.dart';
import 'package:music_player/states/PlaybackState.dart';
import 'package:music_player/view/App.dart';
import 'package:music_player/view/addGuardsFuncs.dart' show SelectSourceDir;
import 'package:music_player/view/components/KeyBindigsTable.dart'
    show getActionToLangMap;
import 'package:music_player/view/components/buttons.dart';
import 'package:music_player/view/components/parts.dart' show Cover, Thumbnail;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import 'package:music_player/logic/MusicItem.dart';
import 'package:music_player/logic/DialogDescr.dart';
import 'package:music_player/logic/enums.dart';
import 'package:music_player/logic/fs/FsSource.dart';

import 'package:music_player/states/AppState.dart' show AppState;

import 'package:music_player/view/PageRouter.dart' show PageRouter;

// Other dialogs
class AddToPlaylistDialog extends StatelessWidget {
  const AddToPlaylistDialog({
    super.key,
    required this.tracklist,
    required this.onAdd,
    required this.onNewPlaylist,
  });

  final List<MusicItem> tracklist;
  final OnAddFunc onAdd;
  final OnNewPlaylistFunc onNewPlaylist;

  @override
  Widget build(BuildContext context) {
    PlaylistHandler playlistHandler =
        context.watch<AppState>().fsSource.playlistHandler;
    var recentPlaylistsNames =
        playlistHandler.getRecentPlaylistsNamesWithPictures();
    double width = MediaQuery.of(context).size.width;

    return AlertDialog(
      title: Text(lang.Add_to_playlist),
      content: SizedBox(
        width: min(width - 40.0, 600.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: recentPlaylistsNames.length,
                itemBuilder: (BuildContext context, int index) {
                  String playlistName = recentPlaylistsNames[index].$1;
                  PictureTag? picture = recentPlaylistsNames[index].$2;
                  return ListTile(
                    title: Text(playlistName),
                    leading: Thumbnail(picture: picture, size: 32),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 0.0, horizontal: 8.0),
                    onTap: () {
                      onAdd(playlistName, tracklist);
                      PageRouter.back(context);
                    },
                  );
                },
              ),
            ),
            TextButton.icon(
              style: ButtonStyle(
                foregroundColor: WidgetStateColor.resolveWith(
                    (states) => ColorScheme.of(context).primary),
                padding: const WidgetStatePropertyAll<EdgeInsets>(
                    EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 15.0,
                )),
              ),
              onPressed: () async {
                String? name = await showDialog<String>(
                  context: context,
                  builder: (context) => TextDialog(
                    title: lang.New_playlist,
                    hintText: lang.Name,
                  ),
                );
                if (name != null && name.isNotEmpty) {
                  onNewPlaylist(name, tracklist);
                  if (context.mounted) {
                    PageRouter.back(context);
                  }
                }
              },
              icon: const Icon(PhosphorIconsThin.plus),
              label: Text(lang.New_playlist),
            ),
          ],
        ),
      ),
    );
  }
}

class TextDialog extends StatefulWidget {
  const TextDialog({
    super.key,
    required this.title,
    required this.hintText,
  });

  final String title;
  final String hintText;

  @override
  State<TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<TextDialog> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  late void Function() _focusListener;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();

    final f = Provider.of<FocusManagerState>(context, listen: false);
    _focusListener = f.getInputFocusListener(_focusNode);
    _focusNode.addListener(_focusListener);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_focusListener);

    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        focusNode: _focusNode,
        autofocus: true,
        decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(color: ColorScheme.of(context).secondary)),
        controller: _controller,
        onSubmitted: (_) => submit(context),
      ),
      actions: [
        TextButton(
            onPressed: () {
              submit(context);
            },
            child: Text(lang.Submit)),
      ],
    );
  }

  void submit(ctx) {
    PageRouter.back(ctx, _controller.text);
  }
}

class RenameFileDialog extends StatelessWidget {
  const RenameFileDialog({
    super.key,
    required this.fileOriginal,
    required this.fileRenamed,
  });

  final String fileOriginal;
  final String fileRenamed;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(lang.The_file_already_exists.replaceFirst('{}', '')),
      content: Container(
        constraints: const BoxConstraints(maxWidth: 450.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${lang.Overwrite_it}?'),
                const SizedBox(width: 14),
                OutlinedStandardButton(
                  lang.Ok,
                  onTap: () async {
                    PageRouter.back(context, 'overwrite');
                  },
                  fontSize: 14.0,
                  padding: const EdgeInsets.only(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Flexible(
                  child: Text(
                      '${lang.Create_a_new_file_named}\n"${fileRenamed}"?',
                      softWrap: true),
                ),
                const SizedBox(width: 14),
                OutlinedStandardButton(
                  lang.Ok,
                  onTap: () async {
                    PageRouter.back(context, 'rename');
                  },
                  fontSize: 14.0,
                  padding: const EdgeInsets.only(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () async {
                      PageRouter.back(context, 'cancel');
                    },
                    child: Text(lang.Cancel)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.heading,
    this.content,
    required this.confirmText,
    required this.cancelText,
  });

  final String heading;
  final Widget? content;
  final String confirmText;
  final String cancelText;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(heading),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (content != null) content!,
          Row(
            children: [
              TextButton(
                  onPressed: () async {
                    PageRouter.back(context, true);
                  },
                  child: Text(confirmText)),
              TextButton(
                  onPressed: () async {
                    PageRouter.back(context, false);
                  },
                  child: Text(cancelText)),
            ],
          ),
        ],
      ),
    );
  }
}

class SelectSourceDirDialog extends StatelessWidget {
  const SelectSourceDirDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12.0),
      contentPadding: const EdgeInsets.only(),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectSourceDir(onSelect: () {
            PageRouter.back(context);
          }),
        ],
      ),
    );
  }
}

class PriorityDialog extends StatelessWidget {
  const PriorityDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    AppearanceState appearanceState =
        Provider.of<AppearanceState>(context, listen: false);
    return AlertDialog(
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(child: Text(lang.phrase__Playlist_conflict)),
          const SizedBox(width: 10),
          TextButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateColor.resolveWith(
                  (states) => appearanceState.buttonColor()),
              minimumSize: WidgetStateProperty.all(Size.zero),
              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40.0),
              )),
              padding:
                  const WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.symmetric(
                horizontal: 0.0,
                vertical: .0,
              )),
            ),
            child: SizedBox(
              width: 34.0,
              height: 34.0,
              child: Icon(
                PhosphorIconsThin.question,
                color: ColorScheme.of(context).secondary,
                size: 22,
              ),
            ),
            onPressed: () {
              gLogger.view('More about modes btn');
              // TODO: manage focus
              showDialog<String>(
                context: context,
                builder: (context) => const ModesPlaylistInfoDialog(),
              );
            },
          ),
        ],
      ),
      content: Wrap(crossAxisAlignment: WrapCrossAlignment.start, children: [
        TextButton(
            onPressed: () {
              PageRouter.back(context, SyncPriority.self);
            },
            child: Text(lang.Mine)),
        const SizedBox(width: 10),
        TextButton(
            onPressed: () {
              PageRouter.back(context, SyncPriority.partner);
            },
            child: Text(lang.Partners)),
        const SizedBox(width: 10),
        TextButton(
            onPressed: () {
              PageRouter.back(context, SyncPriority.asIs);
            },
            child: Text(lang.Leave_as_is)),
      ]),
    );
  }
}

class KeyMappingDialog extends StatefulWidget {
  const KeyMappingDialog({
    super.key,
    this.mappingName = '',
  });

  final String mappingName;

  @override
  State<KeyMappingDialog> createState() => _KeyMappingDialogState();
}

class _KeyMappingDialogState extends State<KeyMappingDialog> {
  @override
  void initState() {
    super.initState();
    keyboardHandler.lastCodesListener = lastCodesListener;
  }

  @override
  void dispose() {
    keyboardHandler.lastCodesListener = null;
    super.dispose();
  }

  String? _codes;

  List<String> _conflictMappingNames = [];

  static const List<String> allowedKeys = [
    //
    '1', '!', '2', '@', '3', '#', '4', '\$', '5', '%', '6', '^', '7', '&', '8',
    '*', '9', '(', '0', ')',
    '`', '~',
    '-', '_', '=', '+',
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O',
    'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    '[', '{', ']', '}', '\\', '|',
    ';', ':', "'", '"',
    ',', '<', '.', '>', '/', '?',
    'Enter', 'Tab', 'Space', 'Caps Lock',
    'Arrow Left', 'Arrow Right', 'Arrow Down', 'Arrow Up',
    '<Ctrl>', '<Shift>', '<Alt>',
  ];

  void lastCodesListener(String lastCodes) {
    final codes = lastCodes.split('] ')[1];
    var splitted = codes.split('-');
    gLogger.log('splitted=$splitted');
    if (splitted.every((el) => allowedKeys.contains(el))) {
      _codes = codes;
      _conflictMappingNames = bindingsHandler.getMappingNamesByKeyCodes(codes)
        ..remove(widget.mappingName);

      setState(() {});
    } else {
      gLogger.warn('Not allowed keys');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);
    Color bgColor = appearanceState.lerpBgColor(0.07);

    final actionToLangMap = getActionToLangMap();
    final conflictMappingNamesForUser = _conflictMappingNames
        .map((el) => actionToLangMap[KeyboardAction.values.byName(el)]!)
        .join(', ');

    return AlertDialog(
      title: Text(lang.Press_keys),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(5.0),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            child: Text(_codes ?? '',
                style: const TextStyle(fontWeight: FontWeight.normal)),
          ),
          const SizedBox(height: 12.0),
          if (_conflictMappingNames.isNotEmpty)
            Text(
                '${lang.Conflicts_have_occurred}.\n"${conflictMappingNamesForUser}" ${lang.will_be_reset_when_you_press_save}'),
          const SizedBox(height: 12.0),
          Row(
            children: [
              TextButton(
                  onPressed: () async {
                    if (_conflictMappingNames.isNotEmpty) {
                      for (var name in _conflictMappingNames) {
                        bindingsHandler.removeMapping(name, _codes!);
                      }
                    }
                    PageRouter.back(context, _codes);
                  },
                  child: Text(lang.Save)),
              TextButton(
                  onPressed: () async {
                    PageRouter.back(context, null);
                  },
                  child: Text(lang.Cancel)),
            ],
          ),
        ],
      ),
    );
  }
}

class ModesInfoDialog extends StatelessWidget {
  const ModesInfoDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.symmetric(vertical: 15),
      content: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 10),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ModeDescr(
                  title: lang.Synchronize,
                  text: lang.File_sharing_with_a_partner,
                  path: 'assets/images/animations/1.gif',
                ),
                const SizedBox(height: 20),
                _ModeDescr(
                  title: lang.Download,
                  text: lang.Downloading_file_from_partner,
                  path: 'assets/images/animations/2.gif',
                ),
                const SizedBox(height: 20),
                _ModeDescr(
                  title: lang.Clean,
                  text:
                      lang.Removing_extra_files_that_the_partner_does_not_have,
                  path: 'assets/images/animations/3.gif',
                ),
              ]),
        ),
      ),
    );
  }
}

class ModesPlaylistInfoDialog extends StatelessWidget {
  const ModesPlaylistInfoDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.symmetric(vertical: 15),
      content: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 10),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ModeDescr(
                  title: lang.Mine,
                  text: lang.phrase__mine,
                  path: 'assets/images/animations/mine.gif',
                ),
                const SizedBox(height: 20),
                _ModeDescr(
                  title: lang.Partners,
                  text: lang.phrase__partner,
                  path: 'assets/images/animations/partner.gif',
                ),
                const SizedBox(height: 20),
                _ModeDescr(
                  title: lang.Leave_as_is,
                  text: lang.phrase__as_is,
                  path: 'assets/images/animations/as_is.gif',
                ),
              ]),
        ),
      ),
    );
  }
}

class _ModeDescr extends StatelessWidget {
  const _ModeDescr({
    required this.title,
    required this.text,
    required this.path,
  });

  final String title;
  final String text;
  final String path;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: ColorScheme.of(context).primary,
            )),
        Text(text, style: TextStyle(color: ColorScheme.of(context).secondary)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            width: 300,
            child: Image.asset(
              path,
              // fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}

class CoverDialog extends StatelessWidget {
  const CoverDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final playback =
        Provider.of<PlaybackState>(context, listen: false).playback;
    AppearanceState appearanceState =
        Provider.of<AppearanceState>(context, listen: false);
    var mi = playback.getCurrentMusicItem();
    const double imgSize = 500;

    return AlertDialog(
      contentPadding: const EdgeInsets.only(),
      backgroundColor: Colors.transparent,
      content: Cover(
        picture: mi.picture,
        radius: appearanceState.coverRadius,
        sideSize: imgSize,
      ),
    );
  }
}
