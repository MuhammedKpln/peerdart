import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:peerdart/src/baseconnection.dart';
import 'package:peerdart/src/enums.dart';
import 'package:peerdart/src/negotiator.dart';
import 'package:peerdart/src/servermessage.dart';
import 'package:peerdart/src/util.dart';

import 'logger.dart';

class MediaConnection extends BaseConnection {
  static const ID_PREFIX = "mc_";
  late Negotiator _negotiator;
  late MediaStream _localStream;
  late MediaStream _remoteStream;

  MediaConnection(super.peerId, super.provider, super._options) {
    _localStream = options._stream;
    connectionId =
        options.connectionId ?? MediaConnection.ID_PREFIX + util.randomToken();
    _negotiator = Negotiator(this);

    _negotiator.startConnection({
      "_stream": _localStream,
      "originator": true,
    });
  }

  addStream(remoteStream) {
    logger.log("Receiving stream $remoteStream");

    _remoteStream = remoteStream;
    super.emit("stream", remoteStream); // Should we call this `open`?
  }

  @override
  void close() {
    // TODO: implement close
  }

  @override
  void handleMessage(ServerMessage message) {
    // TODO: implement handleMessage
  }

  @override
  // TODO: implement type
  ConnectionType get type => throw UnimplementedError();
}
