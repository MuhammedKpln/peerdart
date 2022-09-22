import 'package:eventify/eventify.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:peerdart/src/enums.dart';
import 'package:peerdart/src/optionInterfaces.dart';
import 'package:peerdart/src/peer.dart';
import 'package:peerdart/src/servermessage.dart';

abstract class BaseConnection extends EventEmitter {
  BaseConnection(this.peer, this.provider, this.options) {
    metadata = options?.metadata;
  }
  bool open = false;
  late String connectionId;
  late RTCPeerConnection peerConnection;
  dynamic metadata;
  late Peer provider;
  late String peer;
  late PeerConnectOption? options;
  late ConnectionType type;

  void close();
  void handleMessage(ServerMessage message);
}
