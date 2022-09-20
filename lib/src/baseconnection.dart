import 'package:eventify/eventify.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:peerdart/src/enums.dart';
import 'package:peerdart/src/peer.dart';
import 'package:peerdart/src/servermessage.dart';

/// > Emitted when either you or the remote peer closes the connection.
abstract class BaseConnectionEvents {
  late Function() close;
  late Function(Exception error) error;
  late Function(RTCIceConnectionState state) iceStateChanged;
}

abstract class BaseConnection extends EventEmitter {
  bool open = false;
  late String connectionId;
  late RTCPeerConnection peerConnection;
  dynamic metadata;
  ConnectionType get type;
  Peer provider;
  String peer;
  dynamic options;

  BaseConnection(this.peer, this.provider, this.options) {
    metadata = options.metadata;
  }

  void close();
  void handleMessage(ServerMessage message);
}
