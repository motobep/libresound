import 'dart:io';
import 'package:music_player/config.dart' as CONFIG;
import 'package:music_player/logger.dart';

Future<List<NetworkInterface>> getAllIpV4Interfaces() async {
  List<NetworkInterface> interfaces =
      await NetworkInterface.list(type: InternetAddressType.IPv4);
  gLogger.log('interfaces=$interfaces');
  return interfaces;
}

List<String> interfacesToStrings(List<NetworkInterface> ips) {
  List<String> strs = [];
  for (var int in ips) {
    for (var addr in int.addresses) {
      strs.add(addr.address);
    }
  }
  return strs;
}

int ips_192_168_first(String a, String b) {
  bool aAddr = a.startsWith('192.168');
  bool bAddr = b.startsWith('192.168');

  if (aAddr && !bAddr) return -1;
  if (!aAddr && bAddr) return 1;
  return 0;
}

List<String> filterPrivateAddresses(List<String> addrs) {
  return addrs.where(isPrivateIpAddress).toList();
}

bool isPrivateIpAddress(String addr) {
  var ip = addr.split('.').toList();
  int ip1 = int.parse(ip[0]);
  int ip2 = int.parse(ip[1]);
  if (ip1 == 10) return true;
  if (ip1 == 172 && 16 <= ip2 && ip2 <= 31) return true;
  if (ip1 == 192 && ip2 == 168) return true;
  return false;
}

int getWsServerPort() {
  return CONFIG.wsServerPort;
}

int getWsClientPort() {
  return CONFIG.wsClientPort;
}

Future<int> getUnusedPort(String ip) async {
  var addr = InternetAddress(ip);
  var socket = await ServerSocket.bind(addr, 0);
  int port = socket.port;
  socket.close();
  return port;
}

HttpClient makeHttpClient({
  Map<String, String>? proxy,
  bool useEnv = true,
  isTls1_3 = false,
}) {
  gLogger.debug('makeHttpClient');
  SecurityContext? securityContext;
  if (isTls1_3) {
    securityContext = SecurityContext(withTrustedRoots: true);
    securityContext.minimumTlsProtocolVersion = TlsProtocolVersion.tls1_3;
    gLogger.warn(
        'Set tls 1.3:\n\tminimumTlsProtocolVersion: ${securityContext.minimumTlsProtocolVersion}');
  }
  var client = HttpClient(context: securityContext);
  client.userAgent = null;
  client.connectionTimeout = CONFIG.connectionTimeout;
  return setProxy(client, proxy: proxy);
}

HttpClient setProxy(HttpClient client,
    {Map<String, String>? proxy, bool useEnv = true}) {
  // gLogger.log('setProxy: ${proxy}');
  proxy = pickProxyConfig(proxy, useEnv);
  client.findProxy = (url) {
    // gLogger.warn('findProxy');
    return HttpClient.findProxyFromEnvironment(url, environment: proxy);
  };
  return client;
}

Map<String, String> pickProxyConfig(Map<String, String>? proxy, bool useEnv) {
  if (Platform.environment['use_mitm_proxy'] == '1') {
    // gLogger.blue('Mitm proxy set');

    proxy = {
      'http_proxy': CONFIG.mitm_proxy_url,
      'https_proxy': CONFIG.mitm_proxy_url,
    };
  } else {
    // Use env proxy if proxy param is null
    proxy ??= useEnv
        ? {
            'http_proxy': Platform.environment['http_proxy'] ?? '',
            'https_proxy': Platform.environment['https_proxy'] ?? '',
            'no_proxy': Platform.environment['no_proxy'] ?? '',
          }
        : {};
  }
  return proxy;
}
