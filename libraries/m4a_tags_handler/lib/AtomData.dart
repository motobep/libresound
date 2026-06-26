import 'dart:convert' show utf8;
import 'dart:typed_data';

import 'package:m4a_tags_handler/M4a.dart' show flagAndNullLen;

class AtomData {
  int position = 0;
  Uint8List buffer;

  AtomData(this.buffer);

  int get lengthInBytes {
    return buffer.lengthInBytes;
  }

  seek(int num) {
    position = num;
    return this;
  }

  void writeBytes(Uint8List bytes) {
    setBytes(position, bytes);
    position += bytes.length;
  }

  void setBytes(int pos, Uint8List bytes) {
    assert(0 <= pos && pos + bytes.lengthInBytes <= buffer.lengthInBytes,
        'setBytes() out of range: pos=$pos len=${bytes.lengthInBytes}');
    buffer.setAll(pos, bytes);
  }

  void setUint32(int pos, int num) {
    final bytes = [
      // Note: now this is the proper order of bytes, probably
      num >> 24,
      (num >> 16) & 0xff,
      (num >>> 8) & 0xff,
      num & 0xff,
    ];
    buffer.setAll(pos, bytes);
  }

  void writeUint8(int value) {
    buffer[position] = value;
    position++;
  }

  int getUint32(int offset) {
    final bytes = buffer.sublist(offset, offset + 4);
    int value = 0;
    value += bytes[0] << 24;
    value += bytes[1] << 16;
    value += bytes[2] << 8;
    value += bytes[3];
    return value;
  }

  String getUtfStringOfContent() {
    final subArray = buffer.sublist(flagAndNullLen, lengthInBytes);
    return utf8.decode(subArray);
  }

  String getString(int length, int offset) {
    final subArray =
        buffer.sublist(position + offset, position + length + offset);
    return String.fromCharCodes(subArray);
  }

  Uint8List getBytesOfContent() {
    return buffer.sublist(flagAndNullLen, lengthInBytes);
  }

  void setUint8(int pos, int value) {
    buffer[pos] = value;
  }

  AtomData sublist(int start, int end) {
    return AtomData(buffer.sublist(start, end));
  }
}
