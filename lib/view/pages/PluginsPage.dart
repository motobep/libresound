import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logic/lang.dart';
import 'package:music_player/states/AppearanceState.dart';
import 'package:music_player/view/components/ScrollingPageWrapper.dart';
import 'package:music_player/view/components/TopTabs.dart';
import 'package:music_player/view/components/buttons.dart';
import 'package:music_player/view/components/inputs.dart';
import 'package:music_player/view/components/plugins/BrowsePlugins.dart';
import 'package:music_player/view/components/plugins/MyPlugins.dart';

import 'package:music_player/logger.dart';
import 'package:music_player/main.dart';
import 'package:music_player/states/AppState.dart';

import 'package:flutter/material.dart';
import 'package:music_player/view/snackBarFuncs.dart' show showSnackBar;
import 'package:provider/provider.dart';

class PluginsPages {
  final List<List<String>> stacks = [
    [browsePluginsPage],
    [myPluginsPage],
  ];
  int stackIdx = CONFIG.isDisableDownloadPlugins ? 1 : 0;

  static const String browsePluginsPage = 'browsePlugins';
  static const String myPluginsPage = 'myPlugins';
  static const String infoPage = 'info';
  static const String settingsPage = 'settings';

  String get currPage {
    return stacks[stackIdx].last;
  }

  List<String> get currStack {
    return stacks[stackIdx];
  }

  // For browse
  PluginsObj pluginsObj = const PluginsObj(null, '', -1);

  // For info
  dynamic pluginInfo;

  // For settings
  String pluginId = '';

  PluginsPages(this.appState);
  AppState appState;

  bool canBack() {
    return stacks[stackIdx].length > 1;
  }

  bool back() {
    if (canBack()) {
      if (currPage == settingsPage) {
        appState.triggerSourceEvent(pluginId, 'PluginSettingsClose', {});
      }
      stacks[stackIdx].removeLast();
      return false; // don't pop
    }
    return true; // pop
  }
}

class PluginsObj {
  const PluginsObj(this.data, this.search, this.currPage);
  final dynamic data;
  final String search;
  final int currPage;
}

// FIXME: error, when downloading new plugin (may be downloading new not compatibale version of the plugin) on anroid
class PluginsBody extends StatefulWidget {
  const PluginsBody({super.key});

  @override
  State<PluginsBody> createState() => _PluginsBodyState();
}

class _PluginsBodyState extends State<PluginsBody> {
  List<String> tabs = [lang.Download_plugins, lang.My_plugins];

  @override
  Widget build(BuildContext context) {
    gLogger.build('build() PluginsBody');

    var appState = Provider.of<AppState>(context, listen: false);
    bool isPluginsDisclaimerRead =
        context.select<AppState, bool>((s) => s.isPluginsDisclaimerRead);
    bool isPluginsMiniDisclaimerRead =
        context.select<AppState, bool>((s) => s.isPluginsMiniDisclaimerRead);

    // To update
    context.select<AppState, String>((s) => s.pluginsPages.currPage);
    final pluginsPages = appState.pluginsPages;

    List<Widget> widgets = [];

    var mainAxisAlignment = appState.isWide
        ? MainAxisAlignment.start
        : MainAxisAlignment.spaceBetween;

    final pluginUpdatesCount = context
        .select<AppState, int>((s) => s.pluginManager.pluginUpdatesCount);
    if (pluginUpdatesCount > 0) {
      tabs[1] = '${lang.My_plugins} ($pluginUpdatesCount)';
    } else {
      tabs[1] = lang.My_plugins;
    }

    widgets = [
      if (!CONFIG.isDisableDownloadPlugins)
        TopTabs(
          elements: tabs,
          initial: pluginsPages.stackIdx,
          onSelect: (index) {
            gLogger.view('hey: $index');
            setState(() {
              pluginsPages.stackIdx = index;
              appState.update();
            });
            return false;
          },
          mainAxisAlignment: mainAxisAlignment,
        ),
      if (!CONFIG.isDisableDownloadPlugins) const SizedBox(height: 15),
      if (pluginsPages.stackIdx == 0) const BrowsePlugins(),
      if (pluginsPages.stackIdx == 1) const MyPlugins(),
    ];

    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);

    return Stack(
      children: [
        ScrollingPageWrapper(widgets),
        if (!isPluginsDisclaimerRead && !CONFIG.isDisableDownloadPlugins) ...[
          Positioned(
            child: Container(
              padding: const EdgeInsets.only(
                  top: 50.0, bottom: 20, left: 8, right: 8),
              color: appearanceState.lerpBgColor(0.00).withAlpha(230),
              child: Center(
                child: Container(
                  // color: appearanceState.lerpBgColor(0.00),
                  decoration: BoxDecoration(
                    color: appearanceState.colors[ColorType.bg],
                    border: Border.all(
                        color: appearanceState.lerpBgColor(0.07), width: 1.0),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  width: 600,
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          lang.Plugins,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(height: 10.0),
                        SelectableText(
                          lang.phrase__plugin_welcome,
                          style: const TextStyle(height: 1.6),
                          // softWrap: true,
                        ),
                        const SizedBox(height: 18.0),
                        SelectableText(
                          '${lang.Warning}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8.0),
                        SelectableText(
                          '${lang.phrase__disclaimer}',
                          style: const TextStyle(height: 1.6),
                          // softWrap: true,
                        ),
                        const SizedBox(height: 18.0),
                        Text(
                          lang.Plugin_settings,
                          // softWrap: true,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            CheckboxInput(
                              initial: config.getProperty(
                                  'isAutoLoadPluginHomePage',
                                  orElse: true),
                              onSelect: (b) {
                                gLogger.log('isAutoLoadPluginHomePage: $b');
                                bool ok = config.saveProperty(
                                    'isAutoLoadPluginHomePage', b);
                                return ok;
                              },
                            ),
                            const SizedBox(width: 8.0),
                            Flexible(
                              child: Text(
                                lang.Automatically_load_the_home_page_when_entering_the_plugins_page,
                                softWrap: true,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        Row(children: [
                          CheckboxInput(
                            initial: config.getProperty(
                                'isAutoCheckPluginUpdates',
                                orElse: true),
                            onSelect: (b) {
                              gLogger.log('isAutoCheckPluginUpdates: $b');
                              bool ok = config.saveProperty(
                                  'isAutoCheckPluginUpdates', b);
                              return ok;
                            },
                          ),
                          const SizedBox(width: 8.0),
                          Flexible(
                            child: Text(
                              lang.Automatic_check_for_plugin_updates,
                              softWrap: true,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 20.0),
                        Text('${lang.This_message_will_not_appear_again}.'),
                        const SizedBox(height: 14.0),
                        StandardButton(lang.Continue, onTap: () {
                          config.saveProperty('isPluginsDisclaimerRead', true);
                          appState.update();
                        }),
                        const SizedBox(height: 6.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        if (!isPluginsMiniDisclaimerRead && CONFIG.isDisableDownloadPlugins) ...[
          Positioned(
            child: Container(
              padding: const EdgeInsets.only(
                  top: 50.0, bottom: 20, left: 8, right: 8),
              color: appearanceState.lerpBgColor(0.00).withAlpha(230),
              child: Center(
                child: Container(
                  // color: appearanceState.lerpBgColor(0.00),
                  decoration: BoxDecoration(
                    color: appearanceState.colors[ColorType.bg],
                    border: Border.all(
                        color: appearanceState.lerpBgColor(0.07), width: 1.0),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  width: 600,
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          lang.Plugins,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(height: 10.0),
                        SelectableText(
                          lang.phrase__plugin_welcome,
                          style: const TextStyle(height: 1.6),
                          // softWrap: true,
                        ),
                        const SizedBox(height: 18.0),
                        SelectableText(
                          '${lang.Warning}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8.0),
                        SelectableText(
                          '${lang.phrase__disclaimer}',
                          style: const TextStyle(height: 1.6),
                          // softWrap: true,
                        ),
                        const SizedBox(height: 20.0),
                        Text('${lang.This_message_will_not_appear_again}.'),
                        const SizedBox(height: 14.0),
                        StandardButton(lang.Continue, onTap: () {
                          config.saveProperty('isPluginsMiniDisclaimerRead', true);
                          appState.update();
                        }),
                        const SizedBox(height: 6.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

void onSuccessfulPluginInstall(BuildContext context) {
  var appState = Provider.of<AppState>(context, listen: false);
  var msg = lang.phrase__Plugin_successfully_installed;
  gLogger.view(msg);
  showSnackBar(msg, context);
  appState.reloadPlugins(loadOnlyNew: true);
}
