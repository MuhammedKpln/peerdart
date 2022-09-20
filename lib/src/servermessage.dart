import 'package:peerdart/src/enums.dart';

abstract class ServerMessage {
  late ServerMessageType type;
  dynamic payload;
  late String src;
}
