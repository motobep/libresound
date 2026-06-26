import 'dart:io';

void main(List<String> args) {
  if (args.length < 1) {
    print('Pass path to a file');
    return;
  }

  var file = File(args[0]);
  if (!file.existsSync()) {
      print('File "${file.path}" doesn\'t exist');
      return;
  }

  var lines = File(args[0]).readAsLinesSync();
  String str = '// Auto-generated from dart lang file\n';
  for (var line in lines) {
    String output = line.replaceAllMapped(
        RegExp(r'^\s*String\s+([A-Za-z0-9_]+)\s*=', multiLine: false),
        (m) => '    ${m[1]}: string =')
    .replaceAllMapped(
        RegExp(r'^\s*abstract\s+String\s+([A-Za-z0-9_]+)\s*;'),
        (m) => '    ${m[1]}: string;')
    .replaceAllMapped(
        RegExp(r'^\s*abstract\s+class\s+([A-Za-z0-9_]+)\s*\{'),
        (m) => 'export interface ${m[1]} {')
    .replaceAllMapped(
        RegExp(r'^\s*class\s+([A-Za-z0-9_]+)\s+implements\s+([A-Za-z0-9_]+)\s*\{'),
        (m) => 'export class ${m[1]} implements ${m[2]} {')
    .replaceAllMapped(
        RegExp(r'^\s*Lang\s+lang\s+=\s+\w+\(\);'),
        (m) => '');
    str += '$output\n';
  }
  print(str);
}
