import 'dart:io';

void main(List<String> args) {
  final rootDir = Directory.current.path;
  final configPath = '$rootDir/lib/config.dart';
  final pubspecPath = '$rootDir/pubspec.yaml';

  var configStr = File(configPath).readAsStringSync();
  var pubspecStr = File(pubspecPath).readAsStringSync();

  var v1 = getVersionConfig(configStr);
  var v2 = getVersionPubspec(pubspecStr);

  // print('($v1, $v2)');
  if (v1 != v2) {
    print('Error: versions (config != pubspec): $v1 != $v2');
    exit(1);
  }
}

String getVersionConfig(String str) {
  RegExp exp = RegExp(r"const version = '(\d+\.\d+\.\d+)'");
  Match? m = exp.firstMatch(str);
  if (m != null && m.groupCount == 1) {
    return m[1]!;
  } else {
    throw Exception('Bad format');
  }
}

String getVersionPubspec(String str) {
  RegExp exp = RegExp(r'version: (\d+\.\d+\.\d+)\+');
  Match? m = exp.firstMatch(str);
  if (m != null && m.groupCount == 1) {
    return m[1]!;
  } else {
    throw Exception('Bad format');
  }
}
