import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logic/lang.dart';
import 'package:music_player/states/AppearanceState.dart';
import 'package:music_player/states/FocusState.dart' show FocusManagerState;
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
import 'package:url_launcher/url_launcher.dart' show launchUrl;

const int myPluginsIdx = 0;
const int browsePluginsIdx = 1;

class PluginsPages {
  final List<List<String>> stacks = [
    [myPluginsPage],
    [browsePluginsPage],
  ];
  int stackIdx = myPluginsIdx;

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
  const PluginsObj(
    this.data,
    this.search,
    this.currPage, {
    this.orderBy,
    this.orderDirection,
  });
  final dynamic data;
  final String search;
  final int currPage;

  final String? orderBy;
  final String? orderDirection;
}

// FIXME: error, when downloading new plugin (may be downloading new not compatibale version of the plugin) on anroid
class PluginsBody extends StatefulWidget {
  const PluginsBody({super.key});

  @override
  State<PluginsBody> createState() => _PluginsBodyState();
}

class _PluginsBodyState extends State<PluginsBody> {
  List<String> tabs = [lang.My_plugins, lang.Download_plugins];

  @override
  Widget build(BuildContext context) {
    gLogger.build('build() PluginsBody');

    var appState = Provider.of<AppState>(context, listen: false);
    bool isPluginsDisclaimerRead =
        context.select<AppState, bool>((s) => s.isPluginsDisclaimerRead);

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
      tabs[myPluginsIdx] = '${lang.My_plugins} ($pluginUpdatesCount)';
    } else {
      tabs[myPluginsIdx] = lang.My_plugins;
    }

    widgets = [
      TopTabs(
        elements: tabs,
        initial: pluginsPages.stackIdx,
        onSelect: (index) {
          setState(() {
            pluginsPages.stackIdx = index;
            appState.update();
          });
          return false;
        },
        mainAxisAlignment: mainAxisAlignment,
      ),
      const SizedBox(height: 15),
      if (pluginsPages.stackIdx == myPluginsIdx)
        MyPlugins(toDownloadPlugins: () {
          setState(() {
            pluginsPages.stackIdx = browsePluginsIdx;
            appState.update();
          });
        }),
      if (pluginsPages.stackIdx == browsePluginsIdx) const BrowsePlugins(),
    ];

    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);

    return Stack(
      children: [
        ScrollingPageWrapper(widgets),
        if (!isPluginsDisclaimerRead) ...[
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
                          lang.phrase__disclaimer,
                          style: const TextStyle(height: 1.6),
                          // softWrap: true,
                        ),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                                color: appearanceState.colors[ColorType.text]),
                            children: [
                              TextSpan(
                                  text: '${lang.phrase__disclaimer_terms_1} '),
                              TextSpan(
                                text: lang.Terms_of_Service__ablative,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    launchUrl(
                                        Uri.parse(lang.link__Terms_of_Service));
                                  },
                              ),
                              TextSpan(text: lang.phrase__disclaimer_terms_2),
                              TextSpan(
                                text: lang.Privacy_Policy__ablative,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    launchUrl(
                                        Uri.parse(lang.link__Privacy_Policy));
                                  },
                              ),
                              const TextSpan(text: '.\n'),
                            ],
                          ),
                        ),
                        SelectableText(
                          '${lang.phrase__disclaimer_end}',
                          style: const TextStyle(height: 1.6),
                          // softWrap: true,
                        ),
                        const SizedBox(height: 14.0),
                        Row(
                          children: [
                            StandardButton(lang.Continue, onTap: () {
                              config.saveProperty(
                                  'isPluginsDisclaimerRead_v2', true);
                              appState.update();
                            }),
                            const SizedBox(width: 12.0),
                            StandardButton(lang.Back, onTap: () {
                              FocusManagerState focusState =
                                  Provider.of<FocusManagerState>(context,
                                      listen: false);
                              focusState.onSidebarClick(4);
                              // appState.update();
                            }),
                          ],
                        ),
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
