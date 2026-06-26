import 'dart:convert';
import 'dart:typed_data';

const int SIZE_OF_HEADER = 4; // 4 bytes

class Message {
  // * header_length [4 bytes]
  // * header : json
  // * body (optional) : binary
  // - body_length = Message_length - header_length

  late Map<String, dynamic> header;
  late Uint8List body;

  Message(this.header, this.body) {
    assert(header.isNotEmpty, 'header is empty');
  }

  Message.header(this.header) {
    assert(header.isNotEmpty, 'header is empty');
    body = Uint8List(0);
  }

  /// Throws if application logic has wrong json string.
  Message.fromBytes(Uint8List bytes) {
    // Header_length
    ByteData byteData = ByteData.sublistView(bytes);
    int header_length = byteData.getUint32(0); // be aware of endian

    // Header
    Uint8List bHeader =
        bytes.sublist(SIZE_OF_HEADER, SIZE_OF_HEADER + header_length);
        // bytes.buffer
        //     .asUint8List(SIZE_OF_HEADER, header_length);
    String sHeader = utf8.decode(bHeader);
    header = jsonDecode(sHeader);

    // Contents
    int bodyStart = SIZE_OF_HEADER + header_length;
    body =
        bytes.sublist(bodyStart, bytes.length);
        // bytes.buffer.asUint8List(bodyStart);
  }

  /// Throws if application logic has wrong json obj.
  Uint8List toBytes() {
    String sHeader = jsonEncode(header);
    Uint8List bHeader = utf8.encode(sHeader);

    Uint8List bHeader_length = Uint8List(SIZE_OF_HEADER);
    ByteData byteData = ByteData.sublistView(bHeader_length);
    byteData.setUint32(0, bHeader.length);

    final headerEnd = bHeader_length.length + bHeader.length;
    var bytes = Uint8List(bHeader_length.length + bHeader.length + body.length);
    bytes.setRange(0, bHeader_length.length, bHeader_length);
    bytes.setRange(bHeader_length.length, headerEnd, bHeader);
    bytes.setRange(headerEnd, headerEnd + body.length, body);
    return bytes;
  }

  @override
  String toString() {
    return '''{
	header: $header,
	body.length: ${body.length}
}''';
  }
}
