import 'dart:convert';

import 'package:music_player/config.dart' show fileSystem;
import 'package:music_player/logger.dart';
import 'package:music_player/logic/KeyValue.dart';
import 'package:music_player/logic/enums.dart';
import 'package:music_player/logic/fs/files.dart' as fs;
import 'package:music_player/logic/bindings/defaultMappings.dart';

import 'package:music_player/states/focus_states/FocusStateInterface.dart';
import 'package:music_player/view/App.dart' show keyboardHandler;

typedef KeyBindingsMap = Map<String, KeyBinding>;

class BindingsHandler {
  /// name -> keyBinding
  final KeyBindingsMap keyBindingsMap = {};
  final String keyMappingsFilepath;

  KeyValue mappings = {};
  bool isWriteDefaultMappingsFailed = false;

  BindingsHandler(this.keyMappingsFilepath) {
    loadMappings();
  }

  void loadMappings() {
    // Read Config Mappings
    final f = fileSystem.file(keyMappingsFilepath);

    try {
      final contents = f.readAsStringSync();
      mappings = jsonDecode(contents);
    } catch (e) {
      logger.error(e);
      logger.error('Using defaultMappings');
      mappings = defaultMappings;
      const enc = JsonEncoder.withIndent('  ');
      try {
        f.writeAsStringSync(enc.convert(mappings));
      } catch (e) {
        logger.error(e);
        isWriteDefaultMappingsFailed = true;
      }
    }
  }

  Map<String, List<String>> getUserMappings() {
    Map<String, List<String>> map = {};
    for (var kb in keyBindingsMap.values) {
      final name = kb.fullname.split('.')[1];
      final codes = kb.keyCodesList;
      map[name] = codes;
    }
    return map;
  }

  List<String> getMappingNamesByKeyCodes(String keyCodes) {
    // return getNames()
    final List<String> list = [];
    for (var key in keyBindingsMap.keys) {
      final kb = keyBindingsMap[key];
      if (kb!.keyCodesList.contains(keyCodes)) {
        final name = kb.fullname.split('.').last;
        if (!list.contains(name)) {
          list.add(name);
        }
      }
    }
    return list;
  }

  void addMapping(String mappingName, String keyCodes) {
    final kbs = _findKeyBindings(mappingName);
    for (var kb in kbs) {
      kb.addKeyCodes(keyCodes);
    }
    _saveMappings();
  }

  void removeMapping(String mappingName, String keyCodes) {
    final kbs = _findKeyBindings(mappingName);
    for (var kb in kbs) {
      kb.removeKeyCodes(keyCodes);
    }
    _saveMappings();
  }

  void changeMapping(
      String mappingName, String oldKeyCodes, String newKeyCodes) {
    final kbs = _findKeyBindings(mappingName);
    for (var kb in kbs) {
      kb.changeKeyCodes(oldKeyCodes, newKeyCodes);
    }
    _saveMappings();
  }

  List<KeyBinding> _findKeyBindings(String mappingName) {
    List<KeyBinding> list = [];
    for (var key in keyBindingsMap.keys) {
      if (key.endsWith('.$mappingName')) {
        list.add(keyBindingsMap[key]!);
      }
    }
    return list;
  }

  void _saveMappings() {
    final Map<String, List<String>> map = {};
    for (var kb in keyBindingsMap.values) {
      map[kb.getName()] = kb.keyCodesList;
    }
    const enc = JsonEncoder.withIndent('  ');
    String contents = enc.convert(map);
    // log(keyMappingsFilepath, color: 'green');
    fs.writeToFile(keyMappingsFilepath, contents);
  }

  void addMappedBindingsByName(
      KeyValue mappings, List<KeyBinding> keyBindings) {
    for (var e in mappings.entries) {
      final name = e.key;
      final val = e.value;
      try {
        final kbs = keyBindings.where((kb) => kb.getName() == name);
        if (kbs.isEmpty) {
          logger.warn('not found name=$name');
          continue;
        }
        for (final kb in kbs) {
          kb.keyCodesList.addAll(val.cast<String>());

          // log('Registered ${kb.fullname} -> ${kb.keyCodesList}',
          //     color: 'green');
          keyBindingsMap[kb.fullname] = kb;
        }
      } catch (_) {
        logger.error('Bindings: name=${name}');
        rethrow;
      }
    }
  }

  void mapBindings(List<List<String>> mappings, List<KeyBinding> keyBindings) {
    for (var el in mappings) {
      final name = el[1];
      final kb = keyBindings.firstWhere((kb) => kb.fullname == name);
      kb.keyCodesList.add(el[0]);
    }
  }

  void addKeyBindings(List<KeyBinding> keyBindings) {
    for (var kb in keyBindings) {
      keyBindingsMap[kb.fullname] = kb;
    }
  }

  void activate(String namespace) {
    logger.debug('namespace=$namespace');
    for (var key in keyBindingsMap.keys) {
      if (key.startsWith(namespace)) {
        final kb = keyBindingsMap[key];
        assert(kb != null, 'KeyBinding is null');
        kb!.activate();
      }
    }
  }

  void deactivate(String namespace) {
    for (var key in keyBindingsMap.keys) {
      if (key.startsWith(namespace)) {
        final kb = keyBindingsMap[key];
        assert(kb != null, 'KeyBinding is null');
        kb!.deactivate();
      }
    }
  }

  List<String> disable() {
    logger.green('disable');
    List<String> list = [];
    for (var e in keyBindingsMap.entries) {
      final kb = e.value;
      if (kb.isActive) {
        kb.deactivate();
        list.add(e.key);
      }
    }
    return list;
  }

  void enable(List<String> list) {
    logger.green('enable');
    for (var key in list) {
      final kb = keyBindingsMap[key]!;
      kb.activate();
    }
  }

  static final Logger logger = Logger(prefix: 'BindingsHandler: ');
}

class KeyBinding {
  KeyBinding({
    required this.fullname,
    required this.keyEvents,
    required this.handler,
    List<String>? keyCodes,
  }) : keyCodesList = keyCodes ?? [];

  String fullname;
  List<KeyEventType> keyEvents;
  KeyboardStateBase? Function() handler;
  List<String> keyCodesList;

  String getName() {
    return fullname.split('.').last;
  }

  bool isActive = false;

  List<String> _keyCodesWithEvent() {
    assert(keyEvents.isNotEmpty, 'KeyBinding.keyEvents is empty');

    List<String> l = [];
    for (var e in keyEvents) {
      for (var kc in keyCodesList) {
        l.add('[${e.name}] $kc');
      }
    }
    return l;
  }

  void addKeyCodes(String keyCodes) {
    keyCodesList.add(keyCodes);
    if (isActive) {
      activate();
    }
  }

  void removeKeyCodes(String keyCodes) {
    keyCodesList.remove(keyCodes);
    if (isActive) {
      deactivate();
      activate();
    }
  }

  void changeKeyCodes(String oldKeyCodes, String newKeyCodes) {
    final idx = keyCodesList.indexOf(oldKeyCodes);
    assert(idx != -1, 'KeyCodes not found');

    keyCodesList[idx] = newKeyCodes;
    if (isActive) {
      activate();
    }
  }

  void activate() {
    _keyCodesWithEvent()
        .forEach((codes) => keyboardHandler.register(codes, handler));
    isActive = true;
  }

  void deactivate() {
    _keyCodesWithEvent().forEach((codes) => keyboardHandler.unregister(codes));
    isActive = false;
  }
}
