import 'dart:io';

import 'package:music_player/logic/PluginSource.dart';
import 'package:music_player/logic/plugins.dart';
import 'package:file_picker/file_picker.dart';

import 'package:music_player/logger.dart';
import 'package:music_player/logic/lang.dart';
import 'package:music_player/logic/playback/Playback.dart';
import 'package:music_player/logic/plugins/PluginsClient.dart'
    show PluginsClient;
import 'package:music_player/main.dart';
import 'package:music_player/states/AppState.dart';
import 'package:music_player/states/AppearanceState.dart';
import 'package:music_player/states/PlaybackState.dart';
import 'package:music_player/view/components/buttons.dart';
import 'package:music_player/view/components/plugins/BrowsePlugins.dart'
    show downloadPluginAndExtract;
import 'package:music_player/view/components/plugins/PluginControlsBody.dart';
import 'package:music_player/view/pages/PluginsPage.dart'
    show PluginsPages, onSuccessfulPluginInstall;
import 'package:music_player/view/snackBarFuncs.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:music_player/view/components/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:archive/archive_io.dart';

class MyPlugins extends StatelessWidget {
  const MyPlugins({super.key});

  @override
  Widget build(BuildContext context) {
    // To update
    context.select<AppState, String>((s) => s.pluginsPages.currPage);
    var appState = Provider.of<AppState>(context, listen: false);
    final pluginsPages = appState.pluginsPages;

    if (pluginsPages.currPage == PluginsPages.settingsPage) {
      var source = appState.sources[pluginsPages.pluginId] as PluginSource;

      gLogger.log(source.settingsControls);
      List<Widget> ws = buildControls(source.settingsControls,
          source.mpJsRuntime, PluginSource.controlsPoolName);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: ws,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang.Install_from_zip_file),
        const SizedBox(height: 8),
        StandardButton(
          lang.Choose,
          onTap: () async {
            gLogger.view('Picking');
            var messengerFunc = getSnackBarMessangerFunc(context);
            FilePickerResult? result = await FilePicker.platform.pickFiles();
            if (result == null) {
              gLogger.view('Canceled choosing zip');
              return;
            }

            String archivePath = result.files.single.path!;
            String targetDir = config.pluginsInstalledDir;
            gLogger.view(archivePath);

            try {
              await extractFileToDisk(archivePath, targetDir);
            } catch (e) {
              gLogger.error('Error while extracting zip: $e');
              var err = lang.Error_occurred_while_extracting_zip_archive;
              messengerFunc(err);
            }

            onSuccessfulPluginInstall(context);
            gLogger.view('Picking END');
          },
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: _MyPluginsList(),
        ),
      ],
    );
  }
}

class _MyPluginsList extends StatelessWidget {
  const _MyPluginsList();
  @override
  Widget build(BuildContext context) {
    var appState = Provider.of<AppState>(context, listen: false);
    final pluginsPages = appState.pluginsPages;

    final pluginsList = context
        .select<AppState, List<PluginInfo>>((s) => s.pluginManager.pluginsList);

    Playback playback =
        Provider.of<PlaybackState>(context, listen: false).playback;

    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);

    return Column(
      children: [
        for (var plugin in pluginsList)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 0.0),
            title: Row(
              children: [
                Text(plugin.longtitleTranslated() ?? plugin.titleTranslated()),
                const SizedBox(width: 6.0),
                if (plugin.status == PluginInfoStatus.errored)
                  Icon(
                    PhosphorIconsThin.warning,
                    color: ColorScheme.of(context).tertiary,
                    size: 16,
                  ),
              ],
            ),
            subtitle: Text('${plugin.type} (${plugin.dirpath})'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (plugin.newVersion != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: appearanceState.lerpBgColor(0.07), width: 1.0),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () async {
                            gLogger.blue(
                                'update plugin: ${plugin.mainObjectName}');
                            final uri = Uri.parse(config.pluginsServerUrl);
                            await downloadPluginAndExtract(context,
                                PluginsClient(uri), plugin.mainObjectName);
                          },
                          color: ColorScheme.of(context).primary,
                          icon: const Icon(PhosphorIconsThin.downloadSimple,
                              size: 22),
                        ),
                        Text(plugin.newVersion!),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (plugin.options.contains('settings'))
                  IconButton(
                    onPressed: () async {
                      print('pressed');
                      await appState.triggerSourceEvent(
                          plugin.id, 'PluginSettingsOpen', {});

                      pluginsPages.currStack.add(PluginsPages.settingsPage);
                      pluginsPages.pluginId = plugin.id;
                      appState.update();
                    },
                    color: ColorScheme.of(context).primary,
                    icon: const Icon(PhosphorIconsThin.fadersHorizontal),
                  ),
                IconButton(
                  onPressed: () async {
                    gLogger.blue('reloadPlugin: ${plugin.id}');
                    var messengerFunc = getSnackBarMessangerFunc(context);
                    await appState.reloadPlugin(plugin);
                    var msg = lang.The_plugin_has_been_reloaded;
                    gLogger.log(msg);
                    messengerFunc(msg);
                  },
                  color: ColorScheme.of(context).primary,
                  icon: const Icon(PhosphorIconsThin.arrowCounterClockwise,
                      size: 22),
                ),
                IconButton(
                  color: ColorScheme.of(context).primary,
                  icon: const Icon(PhosphorIconsThin.minusSquare, size: 22),
                  onPressed: () async {
                    var messengerFunc = getSnackBarMessangerFunc(context);
                    bool? isConfirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => ConfirmDialog(
                        heading: lang.Delete__q,
                        confirmText: lang.Ok,
                        cancelText: lang.Cancel,
                      ),
                    );
                    if (isConfirm != null && isConfirm == true) {
                      gLogger.view('deleting plugin');
                      bool ok = _deletePlugin(plugin.dirpath);
                      // bool ok = true;
                      if (!ok) {
                        var msg = lang.Error_occurred_while_deleting_plugin;
                        gLogger.error(msg);
                        messengerFunc(msg);
                        return;
                      } else {
                        gLogger.view('Plugin in "${plugin.dirpath}" deleted');
                      }
                      await playback.removeSourceItemsFromQueue(plugin.id);
                      appState.reloadPlugins();
                    } else {
                      gLogger.view('canceled');
                    }
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

bool _deletePlugin(String dirpath) {
  try {
    Directory(dirpath).deleteSync(recursive: true);
    return true;
  } catch (e) {
    gLogger.view('Exception while deleting plugin $dirpath: $e');
    return false;
  }
}
