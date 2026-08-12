// ignore_for_file: prefer_is_empty
// ignore_for_file: prefer_interpolation_to_compose_strings
import 'dart:typed_data';
import 'dart:convert' show utf8;

import 'package:m4a_tags_handler/Tags.dart';

import './Atom.dart';
import './AtomData.dart';

const int flagAndNullLen = 8;

bool isRoll = false;

class M4aTagsHandler {
  late AtomData fileAtomData;
  late Atom root;

  /// Throws exception
  M4aTagsHandler(Uint8List input) {
    fileAtomData = AtomData(input);

    root = Atom('root');
    _recursiveParse(root, fileAtomData);
  }

  /// Throws exception
  void _recursiveParse(Atom atom, AtomData atomData) {
    // Minimum atom size is 8 bytes
    while (atomData.lengthInBytes >= 8) {
      atomData.seek(0);
      int tagLength = (atomData.getUint32(0));
      final tagName = (atomData.getString(4, 4));

      RegExp re = RegExp(r'[\xA9\w]{4}');
      if (re.hasMatch(tagName) &&
          tagLength <= atomData.lengthInBytes &&
          atom.name != 'sbgp') {
        if (tagLength == 0 || tagLength == 1) {
          var msg = '0 and 1 length not supported. Tag "$tagName" [$tagLength]';
          log(msg);
          throw M4aException(msg);
        } else if (1 < tagLength && tagLength < 8) {
          var msg = 'Erorr in mpeg encoding. Tag "$tagName" [$tagLength]';
          log(msg);
          throw M4aException(msg);
        }

        // Handle current child
        final child = Atom(tagName, atom);
        if (tagName == 'meta') child.padding = 4;
        atom.children.add(child);
        _recursiveParse(child, atomData.sublist(8 + child.padding, tagLength));

        // Proceeding with next child
        atomData = atomData.sublist(tagLength, atomData.lengthInBytes);
      } else {
        // Atom contains only data
        atom.data = atomData;
        return;
      }
    }
  }

  bool isValid() {
    return root.hasChild('ftyp');
  }

  /// renders an atom-tree to a AtomData buffer.
  AtomData build() {
    // log('build()');
    return _recursiveBuilder(root);
  }

  AtomData _recursiveBuilder(Atom atom) {
    if (atom.data != null) {
      return atom.data!;
    }

    // otherwise we got children to parse.
    var output = AtomData(Uint8List(0));

    for (var child in atom.children) {
      int headerLen = child.getHeaderLength();
      final headerData = AtomData(Uint8List(
          headerLen)); // NOTE: can be optimized with allocating memory for entire atom

      final data = _recursiveBuilder(child);
      int atomLen = data.lengthInBytes + headerLen;
      headerData.setUint32(0, atomLen);

      // Writing control chars
      for (var j = 0; j < 4; j++) {
        headerData.setUint8(4 + j, child.name.codeUnitAt(j));
      }

      AtomData mgegAtom = concatBuffers(headerData, data);
      output = concatBuffers(output, mgegAtom);
    }

    return output;
  }

  AtomData build2() {
    return _recursiveBuilder2(root);
  }

  AtomData _recursiveBuilder2(Atom atom) {
    if (atom.data != null) {
      return atom.data!;
    }

    // Flatten tree and collect metadata
    final List<(int headerLen, AtomData data, Atom child)> childInfo = [];
    int totalSize = 0;

    for (var child in atom.children) {
      int headerLen = child.getHeaderLength();
      final data = _recursiveBuilder2(child);
      childInfo.add((headerLen, data, child));
      totalSize += headerLen + data.lengthInBytes;
    }

    final output = AtomData(Uint8List(totalSize));
    int offset = 0;

    // Write sequentially
    for (var (headerLen, data, child) in childInfo) {
      final atomLen = data.lengthInBytes + headerLen;

      // Fill length
      output.setUint32(offset, atomLen);

      // Fill header
      for (var j = 0; j < 4; j++) {
        output.setUint8(offset + 4 + j, child.name.codeUnitAt(j));
      }
      offset += headerLen;

      // Fill body
      output.buffer.setRange(offset, offset + data.lengthInBytes, data.buffer);
      offset += data.lengthInBytes;
    }

    return output;
  }

  // Adds/sets iTunes mp4 tags
  M4aTagsHandler setTags(Tags tags) {
    log('setTags()');
    var offset = root.ensureChild('moov.udta').getByteLength();

    final hdlr = root.ensureChild('moov.udta.meta.hdlr');
    var adata = AtomData(Uint8List(25));
    adata.seek(8);
    final strBytes = utf8.encode('mdirappl');
    adata.writeBytes(strBytes);
    hdlr.data = adata;

    final metadata = root.ensureChild('moov.udta.meta.ilst');
    metadata.parent!.padding = 4; // meta atom is an odd one.

    Atom addDataAtom(String name, String str) {
      log('Adding data atom: $name with value "$str"');
      final atom = metadata.ensureChild(name + '.data');
      if (str.length > 0) {
        final strBytes = utf8.encode(str);
        AtomData aData = AtomData(Uint8List(strBytes.length + 8));
        aData.seek(3);
        aData.writeUint8(1);
        aData.seek(8);
        aData.writeBytes(strBytes);
        atom.data = aData;
      }
      return atom;
    }

    Atom addTrknDataAtom(String name, String str) {
      log('Adding data atom: $name with value "$str"');
      final atom = metadata.ensureChild(name + '.data');

      if (str.length > 0) {
        int num = int.parse(str);
        AtomData aData = AtomData(Uint8List(40));
        aData = AtomData(Uint8List(40));
        aData.seek(8);
        aData.setUint32(aData.position, num);
        atom.data = aData;
        return atom;
      }
      return atom;
    }

    Atom addCoverDataAtom(String name, PictureTag picture) {
      log('Adding cover art');
      final atom = metadata.ensureChild(name + '.data');

      AtomData aData =
          AtomData(Uint8List(flagAndNullLen + picture.bytes.length));
      aData.setUint32(aData.position,
          picture.mimeToInt()); // writing 13 Class/Flag for jpeg and 14 for png
      aData.position = flagAndNullLen; // move to actual data position
      aData.buffer.setAll(aData.position, picture.bytes); // writing jpeg bytes

      atom.data = aData;
      return atom;
    }

    if (tags.track != null) addTrknDataAtom('trkn', tags.track!);
    if (tags.title != null) addDataAtom('\xA9nam', tags.title!);
    if (tags.artist != null) addDataAtom('\xA9ART', tags.artist!);
    if (tags.year != null) addDataAtom('\xA9day', tags.year!);
    if (tags.album != null) addDataAtom('\xA9alb', tags.album!);
    if (tags.genre != null) addDataAtom('\xA9gen', tags.genre!);
    if (tags.picture != null) addCoverDataAtom('covr', tags.picture!);

    // Offset the data in 'stco' if was changed/moved 'mdata', otherwise m4a will be unplayable
    int mdatIdx = root.getChildIdx('mdat');
    int moovIdx = root.getChildIdx('moov');
    bool isMdatOffested = mdatIdx > moovIdx;

    if (isMdatOffested) {
      offset = root.ensureChild('moov.udta').getByteLength() - offset;
      final moov = root.getChild('moov');
      final traks = moov.getChildren('trak');

      for (var trak in traks) {
        final stco = trak.ensureChild('mdia.minf.stbl.stco');

        AtomData a = stco.data!;
        a.seek(8);
        while (a.position < a.lengthInBytes) {
          log('Offsetting stco [pos: ${a.position}] data by $offset bytes.');
          final current = offset + a.getUint32(a.position);
          a.setUint32(a.position, current);
          a.position += 4;
        }
      }
    }

    return this;
  }

  Tags getCommonTags() {
    final metadata = root.ensureChild('moov.udta.meta.ilst');

    Tags tags = Tags();

    tags.title =
        getDataAtom(metadata, '\xA9nam')?.getUtfStringOfContent() ?? '';
    tags.artist =
        getDataAtom(metadata, '\xA9ART')?.getUtfStringOfContent() ?? '';
    tags.album =
        getDataAtom(metadata, '\xA9alb')?.getUtfStringOfContent() ?? '';
    tags.year = getDataAtom(metadata, '\xA9day')?.getUtfStringOfContent() ?? '';
    tags.genre =
        getDataAtom(metadata, '\xA9gen')?.getUtfStringOfContent() ?? '';
    tags.picture = getPicture();

    return tags;
  }

  PictureTag? getPicture() {
    final metadata = root.ensureChild('moov.udta.meta.ilst');
    var covrAtom = getDataAtom(metadata, 'covr');
    if (covrAtom == null) {
      return null;
    }
    int mimeInt = covrAtom.getUint32(0);
    if (mimeInt != 13 && mimeInt != 14) {
      return null;
    }
    var bytes = covrAtom.getBytesOfContent();
    return PictureTag.fromMimeInt(mimeInt: mimeInt, bytes: bytes);
  }

  AtomData? getDataAtom(Atom metadata, String name) {
    assert(metadata.name == 'ilst', 'Not ilst atom');

    int leafIdx = metadata.getChildIdx(name);
    if (leafIdx == -1) return null; // no tag

    var leaf = metadata.getChildByIdx(leafIdx);
    if (leaf.children.length == 0) return null; // no data child of the tag

    Atom dataAtom = leaf.children[0];
    assert(dataAtom.name == 'data' && dataAtom.data != null,
        "'data' atom, that always must contain data");

    AtomData data = dataAtom.data!;
    return data;
  }

  void printSelf() {
    Pair pair = root.walk(root, 0);
    print(pair.str);
  }
}

AtomData concatBuffers(AtomData buf1, AtomData buf2) {
  return AtomData(Uint8List.fromList(buf1.buffer + buf2.buffer));
}

class M4aException implements Exception {
  String message;
  M4aException(this.message);

  @override
  String toString() {
    return 'M4aException: $message';
  }
}

void log(s) {
  print('M4aTagsHandler: $s');
}
