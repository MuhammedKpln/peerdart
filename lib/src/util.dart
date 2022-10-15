import 'dart:math';
import 'dart:typed_data';

const _defaultConfig = {
  "iceServers": [
    {"urls": "stun:stun.l.google.com:19302"},
    {
      "urls": [
        "turn:eu-0.turn.peerjs.com:3478",
        "turn:us-0.turn.peerjs.com:3478",
      ],
      "username": "peerjs",
      "credential": "peerjsp",
    },
  ],
  "sdpSemantics": "unified-plan",
};

class Util {
  Map<String, dynamic> get defaultConfig => _defaultConfig;

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
