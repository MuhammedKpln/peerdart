import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:peerdart/src/baseconnection.dart';
import 'package:peerdart/src/enums.dart';
import 'package:peerdart/src/logger.dart';
import 'package:peerdart/src/negotiator.dart';
import 'package:peerdart/src/servermessage.dart';
import 'package:peerdart/src/util.dart';

class MediaConnection extends BaseConnection {
  MediaConnection(super.peerId, super.provider, super.options) {
    _localStream = options!.stream!;
    connectionId =
        options?.connectionId ?? MediaConnection.ID_PREFIX + util.randomToken();
    _negotiator = Negotiator(this);

    _negotiator.startConnection(options!.copyWith(originator: true));
  }
  static const ID_PREFIX = 'mc_';
  late Negotiator _negotiator;
  late MediaStream _localStream;
  late MediaStream _remoteStream;

  addStream(remoteStream) {
    logger.log('Receiving stream $remoteStream');

    _remoteStream = remoteStream;
    super.emit('stream', null, remoteStream); // Should we call this `open`?
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
  ConnectionType get type => ConnectionType.Media;
}
