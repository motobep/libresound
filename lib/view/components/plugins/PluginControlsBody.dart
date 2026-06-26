import 'package:flutter/material.dart';

import 'package:music_player/logic/MpJsRuntime.dart';
import 'package:music_player/view/components/inputs.dart';

List<Widget> buildControls(
    List<dynamic> settingsControls, JsRuntimeI mpJsRuntime, String poolName) {
  List<Widget> ws = [];
  for (var el in settingsControls) {
    final idFunc = (el['id'] != null)
        ? _makeIdOneFunc(mpJsRuntime, poolName, el['id'])
        : null;

    final w = switch (el['type']) {
      'textInput' => TextInput.fromJson(el, idFunc!),
      'selectInput' => SelectInput.fromJson(el, idFunc!),
      'radioGroupInput' => RadioGroupInput.fromJson(el, idFunc!),
      'checkboxInput' => CheckboxInput.fromJson(el, idFunc!),
      'switchInput' => CheckboxInput.fromJson(el, idFunc!, isToggler: true),
      'buttonInput' => ButtonInput.fromJson(
          el, _makeIdVoidFunc(mpJsRuntime, poolName, el['id'])),
      'text' => Text(el['text'],
          style: TextStyle(fontSize: el['fontSize']?.toDouble())),
      'space' => SizedBox(
          width: el['width']?.toDouble(), height: el['height']?.toDouble()),
      _ => throw 'Controls type error',
    };
    ws.add(w);
  }
  return ws;
}

Future<void> Function(dynamic) _makeIdOneFunc(
  JsRuntimeI mpJsRuntime,
  String poolName,
  String id,
) {
  return (v) async {
    await mpJsRuntime.runCodeInAsyncFunc('''// js
            musicPlayer.logger.warn('idOneFunc getting "$poolName"')
            var pool = musicPlayer._poolManager.getPool("$poolName");
            var f = pool.get("${id}")
            return await f($v);
        ''');
  };
}

Future<void> Function() _makeIdVoidFunc(
  JsRuntimeI mpJsRuntime,
  String poolName,
  String id,
) {
  return () async {
    await mpJsRuntime.runCodeInAsyncFunc('''// js
            musicPlayer.logger.warn('idVoidFunc getting "$poolName"')
            var pool = musicPlayer._poolManager.getPool("$poolName");
            var f = pool.get("${id}")
            return await f();
        ''');
  };
}
