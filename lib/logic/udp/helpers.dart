import 'dart:convert';

import 'package:music_player/consts.dart' show APP_MSG_PREFIX;

String makeJsonStr(obj) {
  var encoded = jsonEncode(obj);

  return '$APP_MSG_PREFIX:json:$encoded';
}

List<int> makeJsonEncoded(Map obj) {
  var sendStr = makeJsonStr(obj);
  return utf8.encode(sendStr);
}
