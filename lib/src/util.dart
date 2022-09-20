import 'dart:math';
import 'dart:typed_data';
import 'package:messagepack/messagepack.dart' as msgpack;

class Util {
  unpack(Uint8List data) {
    return msgpack.Unpacker(data).unpackBinary();
  }

  ByteBuffer binaryStringToArrayBuffer(String binary) {
    final byteArray = Uint8List(binary.length);

    for (int i = 0; i < binary.length; i++) {
      byteArray[i] = binary.codeUnitAt(i) & 0xff;
    }

    return byteArray.buffer;
  }

  String randomToken() {
    String generateRandomString(int len) {
      var r = Random();
      const chars =
          'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
      return List.generate(len, (index) => chars[r.nextInt(chars.length)])
          .join()
          .toLowerCase();
    }

    return generateRandomString(10);
  }
}

final util = Util();
