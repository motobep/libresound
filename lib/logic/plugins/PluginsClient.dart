import 'dart:convert' show jsonDecode, utf8;
import 'dart:io' show File, HttpClient;

import 'package:music_player/logger.dart';
import 'package:music_player/logic/lang.dart';

class PluginsClient {
  Uri endpointUrl;
  final HttpClient _client = HttpClient();

  static const int exceptionDownloadingErr = -1;

  PluginsClient(this.endpointUrl) {
    _client.userAgent = null;
    _client.connectionTimeout = const Duration(seconds: 5);
  }

  Future<dynamic> getPluginsVersions(List<String> pluginsNames) async {
    final url = _pluginsVersionsUrl(endpointUrl, pluginsNames);
    logger.log('_pluginsVersionsUrl: $url');
    final obj = await _getJson(url);
    return obj;
  }

  Future<dynamic> getSuggestions(String search) async {
    final url = suggestionUrl(endpointUrl, search);
    final obj = await _getJson(url);
    logger.log('suggestions obj: $obj');
    return obj;
  }

  Future<dynamic> getPlugins(String search, int page) async {
    final url = _searchUrl(endpointUrl, search, page, lang.code_);
    final obj = await _getJson(url);
    return obj;
  }

  Future<dynamic> getPlugin(String name) async {
    final url = _pluginUrl(endpointUrl, name, lang.code_);
    final obj = await _getJson(url);
    return obj;
  }

  Future<int> downloadPlugin(String name, String path) async {
    final url = downloadPluginUrl(endpointUrl, name);

    try {
      int statusCode = await _downloadFile(url, path);
      if (statusCode != 200) {
        logger.error('Bad statusCode: $statusCode');
        return statusCode;
      }
    } catch (e) {
      logger.error('Exception downloading plugin: $e');
      return PluginsClient.exceptionDownloadingErr;
    }
    return 0;
  }

  /// Throws Exception
  Future<int> _downloadFile(Uri uri, String path) async {
    final request = await _client.getUrl(uri);
    final response = await request.close();
    await response.pipe(File(path).openWrite());
    return response.statusCode;
  }

  Future<dynamic> _getJson(Uri url) async {
    final request = await _client.getUrl(url);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final data = jsonDecode(body)['data'];
    if (data == null) throw Exception('_getJson(): No data in json');
    return data;
  }

  static Uri suggestionUrl(Uri url, String search) {
    return url.replace(
      pathSegments: [...url.pathSegments, 'suggestions'],
      queryParameters: {'search': search},
    );
  }

  static Uri _searchUrl(Uri url, String search, int page, String lang) {
    return url.replace(
      pathSegments: [...url.pathSegments, 'plugins'],
      queryParameters: {'search': search, 'page': '$page', 'lang': lang},
    );
  }

  static Uri _pluginUrl(Uri url, String name, String lang) {
    return url.replace(
      pathSegments: [...url.pathSegments, 'plugin'],
      queryParameters: {'name': name, 'lang': lang},
    );
  }

  static Uri downloadPluginUrl(Uri url, String name) {
    return url.replace(
      pathSegments: [...url.pathSegments, 'storage', '$name.zip'],
    );
  }

  static Uri _pluginsVersionsUrl(Uri url, List<String> names) {
    return url.replace(
      pathSegments: [...url.pathSegments, 'plugins_versions'],
      queryParameters: {'plugins_names': names.join(',')},
    );
  }

  String explain(int errCode) {
    if (errCode == PluginsClient.exceptionDownloadingErr) {
      return lang.Error_occurred_while_downloading_plugin;
    }

    return '${lang.Error_occurred_while_downloading_plugin}. ${lang.Error} ($errCode)';
  }
}

final Logger logger = Logger(prefix: 'PluginsClient: ');
