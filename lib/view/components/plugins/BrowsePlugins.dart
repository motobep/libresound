import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logic/plugins/PluginsClient.dart';
import 'package:music_player/logic/utils.dart' as utils;
import 'package:music_player/view/components/dialogs.dart' show TextDialog;
import 'package:music_player/view/components/inputs.dart';

import 'package:music_player/logger.dart';
import 'package:music_player/logic/lang.dart';
import 'package:music_player/main.dart' show config;
import 'package:music_player/states/AppState.dart';
import 'package:music_player/states/AppearanceState.dart';
import 'package:music_player/view/components/buttons.dart';
import 'package:music_player/view/components/SearchAutocomplete.dart';
import 'package:music_player/view/components/plugins/PluginsList.dart';
import 'package:music_player/view/pages/PluginsPage.dart'
    show PluginsObj, PluginsPages, onSuccessfulPluginInstall;
import 'package:music_player/view/snackBarFuncs.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:archive/archive_io.dart';

class BrowsePlugins extends StatefulWidget {
  const BrowsePlugins({super.key});

  @override
  State<BrowsePlugins> createState() => BrowsePluginsState();
}

class BrowsePluginsState extends State<BrowsePlugins> {
  late PluginsClient _pluginsClient;

  final _focusNode = FocusNode();
  bool _sugsErr = false;

  void _addPluginsServerUrl(String s) {
    config.saveProperty(
        'pluginsServerUrlList', config.pluginsServerUrlList..add(s));
  }

  void _removePluginsServerUrl(int idx) {
    var arr = config.pluginsServerUrlList;
    arr.removeAt(idx - 1);
    config.saveProperty('pluginsServerUrlList', arr);
    if (idx < config.pluginsServerUrlIdx) {
      _selectPluginsServerUrl(config.pluginsServerUrlIdx - 1);
    } else if (idx == config.pluginsServerUrlIdx) {
      _selectPluginsServerUrl(0);
    }
  }

  void _selectPluginsServerUrl(int idx) {
    config.saveProperty('pluginsServerUrlIdx', idx);

    Uri url = Uri.parse(config.pluginsServerUrl);
    _pluginsClient = PluginsClient(url);
  }

  @override
  void initState() {
    super.initState();
    gLogger.view('BrowsePlugins initState');

    // TODO: add multiple choice
    // FIXME: handle exception
    Uri url = Uri.parse(config.pluginsServerUrl);
    _pluginsClient = PluginsClient(url);

    bool isAutoloadPluginHomePage =
        config.getProperty('isAutoLoadPluginHomePage', orElse: true);
    if (isAutoloadPluginHomePage) {
      var appState = Provider.of<AppState>(context, listen: false);
      final pluginsPages = appState.pluginsPages;
      if (pluginsPages.pluginsObj.data == null) {
        _loadHomePage();
      }
    }
  }

  Future<void> _onDownload(String name) async {
    return await downloadPluginAndExtract(context, _pluginsClient, name);
  }

  Future<void> _loadHomePage() => _getPlugins('', 1);

  Future<void> _getPlugins(String name, int page) async {
    var appState = Provider.of<AppState>(context, listen: false);
    final pluginsPages = appState.pluginsPages;

    var data = await _safeCallAsync<dynamic>(
        () async => await _pluginsClient.getPlugins(name, page), null);
    gLogger.view('_getPlugins: $data');

    pluginsPages.pluginsObj = PluginsObj(data, name, page);
    appState.update();
  }

  Future<List<(IconData, String)>?> _getSuggestionsForStatefullWidget(
      String s) async {
    gLogger.view('_getSuggestionsForStatefullWidget: $s');

    final relevant = makeRelevantCall<SuggestionsType>(_getSuggestions);
    return await _safeCallAsync<List<(IconData, String)>?>(() async {
      return await relevant(s);
    }, []);
  }

  /// Throws
  Future<SuggestionsType> _getSuggestions(String query) async {
    gLogger.view('_getSuggestions: $query');
    final List<String> options =
        (await _pluginsClient.getSuggestions(query)).cast<String>();
    gLogger.view('_getSuggestions options: $options');

    return options
        .map<(IconData, String)>(
            (el) => (PhosphorIconsThin.magnifyingGlass, el))
        .toList();
  }

  Future<T> _safeCallAsync<T>(Future<T> Function() f, T orVal) async {
    try {
      final v = await f();
      if (_sugsErr) {
        setState(() {
          _sugsErr = false;
        });
      }
      return v;
    } catch (e) {
      gLogger.warn('Exception in safeError(): $e');
      if (!_sugsErr) {
        setState(() {
          _sugsErr = true;
        });
      }
      return orVal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);

    final colorScheme = ColorScheme.of(context);

    // To update
    context.select<AppState, String>((s) => s.pluginsPages.currPage);
    var appState = Provider.of<AppState>(context, listen: false);
    final pluginsPages = appState.pluginsPages;

    final pluginsObj =
        context.select<AppState, PluginsObj>((s) => s.pluginsPages.pluginsObj);

    if (pluginsPages.currPage == PluginsPages.infoPage) {
      gLogger.blue('infoPage');
      return _InfoPage(pluginsPages.pluginInfo, onDownloadTap: (name) {
        _onDownload(name);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang.Install_from_the_server),
        const SizedBox(height: 8),
        Row(
          children: [
            Flexible(
              child: SelectInput(
                elements: config.allPluginsServerUrlList.indexed.toList(),
                initial: config.pluginsServerUrlIdx,
                onSelect: (int? idx) {
                  _selectPluginsServerUrl(idx!);
                  setState(() {});
                },
                trailingIconData: PhosphorIconsLight.minus,
                trailingIconOnTap: (idx) {
                  _removePluginsServerUrl(idx);
                  setState(() {});
                },
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
                icon: const Icon(PhosphorIconsLight.plus),
                iconSize: 22,
                onPressed: () async {
                  String? name = await showDialog<String>(
                    context: context,
                    builder: (context) => TextDialog(
                      title: lang.Add_url,
                      hintText: lang.Url,
                    ),
                  );
                  if (name != null && name.isNotEmpty) {
                    _addPluginsServerUrl(name);
                    setState(() {});
                  }
                }),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            OutlinedStandardButton(
              lang.Home,
              fgColor: colorScheme.onSurface,
              onTap: () {
                _loadHomePage();
              },
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: SearchAutocomplete(
                initial: pluginsObj.search,
                focusNode: _focusNode,
                isWideSuggestions: false,
                hintText: lang.Search,
                onSubmitted: (s) => _getPlugins(s, 1),
                getSuggestions: _getSuggestionsForStatefullWidget,
                prefixIcon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    PhosphorIconsThin.magnifyingGlass,
                    size: 24,
                    color: ColorScheme.of(context).onSurface,
                  ),
                ),
                boxBg: appearanceState.lerpBgColor(0.05),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_sugsErr)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(lang.Network_error, // Error getting suggestions
                style: TextStyle(color: ColorScheme.of(context).tertiary)),
          ),
        const SizedBox(height: 12),
        pluginsObj.data != null
            ? PluginsList(
                pluginsObj.data,
                pluginsObj.currPage,
                onDownloadTap: (name) {
                  _onDownload(name);
                },
                onInfoTap: (name) async {
                  pluginsPages.pluginInfo =
                      await _pluginsClient.getPlugin(name);
                  pluginsPages.currStack.add(PluginsPages.infoPage);
                  appState.update();
                },
                onPageTap: (page) {
                  _getPlugins(pluginsObj.search, page);
                },
              )
            : Center(
                child: IconButton(
                    icon: const Icon(PhosphorIconsThin.arrowClockwise),
                    onPressed: () {
                      _loadHomePage();
                    }),
              ),
      ],
    );
  }
}

class _InfoPage extends StatelessWidget {
  const _InfoPage(
    this.pluginInfo, {
    required this.onDownloadTap,
  });

  final dynamic pluginInfo;
  final void Function(String name) onDownloadTap;

  @override
  Widget build(BuildContext context) {
    final d = pluginInfo;
    final unpacked_size = utils.formatBytes(d['unpacked_size']);
    final colorScheme = ColorScheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SelectableText(
              "${d['name']}",
              style: const TextStyle(fontSize: 16),
            ),
            if (d['approved_by'] != null && d['approved_by'] != '')
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(
                  "${lang.Approved_by} ${d['approved_by']}",
                  style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      // letterSpacing: 0.75,
                      color: colorScheme.primary),
                ),
              ),
            const SizedBox(width: 22.0),
            AllOutlinedStandardButton(
              Icon(PhosphorIconsLight.downloadSimple,
                  color: ColorScheme.of(context).onSurface),
              onTap: () {
                onDownloadTap(d['name']);
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        _Tile(lang.Title, d['langs_title'] ?? d['title']),
        _Tile(lang.Long_title, d['langs_longtitle'] ?? d['longtitle'],
            optional: true),
        _Tile(lang.Description, d['langs_descr'] ?? d['descr'], optional: true),
        _Tile(lang.Version, "${d['version']}"),
        _Tile(lang.Minimum_app_version, "${d['minimum_app_version']}"),
        _Tile(lang.Permissions, d['permissions']),
        _Tile(lang.Homepage, d['homepage'], optional: true),
        _Tile(lang.Repository, d['repository'], optional: true),
        _Tile(lang.Author, d['author'] ?? '<${lang.Deleted_User}>',
            optional: true),
        _Tile(lang.Published_at, d['published_at'], optional: true),
        _Tile(lang.Unpacked_size, unpacked_size, optional: true),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.name, this.value, {this.optional = false});

  final String name;
  final String? value;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    if (optional == true && (value == null || value == ''))
      return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2.0),
        SelectableText(value ?? '<Bad_value>',
            style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 16.0),
      ],
    );
  }
}

Future<void> downloadPluginAndExtract(
    BuildContext context, PluginsClient pluginsClient, String name) async {
  var messengerFunc = getSnackBarMessangerFunc(context);
  gLogger.view('Download plugin: "$name"');

  // Download
  String zipPath = '${config.pluginsArchivesDir}/$name.zip';
  int code = await pluginsClient.downloadPlugin(name, zipPath);
  if (code != 0) {
    String err = pluginsClient.explain(code);
    messengerFunc(err);
    return;
  }

  // Extract
  String targetDir = config.pluginsInstalledDir;
  try {
    await extractFileToDisk(zipPath, targetDir);
  } catch (e) {
    gLogger.view('Exception extracting plugin: $e');
    String err = lang.Error_occurred_while_extracting_zip_archive;
    messengerFunc(err);
    return;
  }

  gLogger.view('Succeded downloading plugin: $zipPath -> $targetDir');
  onSuccessfulPluginInstall(context);
}
