import 'package:flutter/material.dart';

import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logger.dart';
import 'package:music_player/logic/Item.dart';
import 'package:music_player/logic/PageDescr.dart';
import 'package:music_player/logic/playlist/Playlist.dart';
import 'package:music_player/logic/lang.dart' show lang;

import 'package:music_player/states/AppState.dart';
import 'package:music_player/states/AppearanceState.dart';
import 'package:music_player/states/FocusState.dart';
import 'package:music_player/view/components/buttons.dart';

import 'package:provider/provider.dart';

import 'package:music_player/view/components/parts.dart';

class ModifyPlaylist extends StatefulWidget {
  const ModifyPlaylist({
    Key? key,
    required this.pageDescr,
  }) : super(key: key);

  final MusicPageDescr pageDescr;

  @override
  State<ModifyPlaylist> createState() => _ModifyPlaylistState();
}

class _ModifyPlaylistState extends State<ModifyPlaylist> {
  late TextEditingController _controller;
  late Playlist _playlist;

  final FocusNode _focusNode = FocusNode();
  late void Function() _focusListener;

  @override
  void initState() {
    super.initState();
    final f = Provider.of<FocusManagerState>(context, listen: false);
    _focusListener = f.getInputFocusListener(_focusNode);
    _focusNode.addListener(_focusListener);
    _controller = TextEditingController();
    _controller.text = widget.pageDescr.header!.title;
    _playlist = Playlist(
        _controller.text, [...widget.pageDescr.firstItemlistOrEmpty()]);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_focusListener);
    _controller.dispose();
    super.dispose();
  }

  static bool _isValidPlaylistName(String name) {
    RegExp regex = RegExp(r'^[\p{Letter}\w\- ]+$', unicode: true);
    bool ok = regex.hasMatch(name);
    return ok;
  }

  bool _isValid = true;

  void _setValid(bool isValid) {
    if (!isValid) {
      _isValid = false;
    } else {
      widget.pageDescr.header!.title = _controller.text;
      _isValid = true;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    AppState appState = Provider.of<AppState>(context, listen: false);
    Color textColor = context
        .select<AppearanceState, Color>((s) => s.colors[ColorType.text]!);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: 12.0, right: 12.0, top: 18.0, bottom: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _controller.text == CONFIG.favouritesPlaylist
                    ? Text(
                        lang.Favourites,
                        style: const TextStyle(fontSize: 20, height: 1.0),
                      )
                    : TextFormField(
                        focusNode: _focusNode,
                        controller: _controller,
                        style: const TextStyle(fontSize: 20, height: 1.0),
                        onChanged: (s) async {
                          // On change user search text
                          gLogger.view('change: $s');
                          _setValid(_isValidPlaylistName(_controller.text));
                        },
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 6.0, vertical: 12.0),
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: textColor)),
                          errorText:
                              !_isValid ? lang.phrase__only_allowed : null,
                        ),
                      ),
              ),
              Padding(
                padding:
                    const EdgeInsets.only(top: 4.0, left: 24.0, right: 8.0),
                child: StandardButton(
                  lang.Save,
                  onTap: () {
                    gLogger.view('on save');
                    final title = _controller.text;
                    final itemlist = _playlist.items;

                    bool isValid = _isValidPlaylistName(title);
                    _setValid(isValid);
                    if (isValid) {
                      appState.triggerSourceEvent(
                          appState.currentSource.sourceId,
                          'ModifyPlaylistEnd',
                          {'title': title, 'itemlist': itemlist});
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: !appState.isWide
                ? const EdgeInsets.only(bottom: CONFIG.listViewGap)
                : null,
            buildDefaultDragHandles: false,
            onReorder: (oldIndex, newIndex) {
              gLogger.view('on playlist item reoreder');
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              _playlist.moveItem(oldIndex, newIndex);
              widget.pageDescr.sectionlist[0].itemlist = _playlist.items;
            },
            itemCount: widget.pageDescr.firstItemlistOrEmpty().length,
            itemBuilder: (BuildContext context, int index) {
              Item mi = _playlist.items[index];
              return ListTile(
                key: ValueKey(index),
                leading: Thumbnail(picture: mi.picture),
                title: Text(
                  mi.title == CONFIG.favouritesPlaylist
                      ? lang.Favourites
                      : mi.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  mi.subtitle ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: ReorderableDragStartListener(
                  index: index,
                  child: Icon(
                    Icons.drag_handle,
                    color: textColor,
                  ),
                ),
                horizontalTitleGap: 18,
              );
            },
          ),
        ),
      ],
    );
  }
}
