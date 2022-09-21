import 'package:peerdart/src/enums.dart';

class ServerMessage {
  ServerMessage({
    required this.type,
    this.src,
    this.payload,
  });

  ServerMessageType type;
  dynamic payload;
  String? src;

  factory ServerMessage.fromMap(Map<String, dynamic> json) => ServerMessage(
        type: ServerMessageType.values
            .singleWhere((element) => element.type == json["type"]),
        payload: json["payload"],
        src: json["src"],
      );

  Map<String, dynamic> toMap() => {
        "type": type,
        "payload": payload,
        "src": src,
      };
}
