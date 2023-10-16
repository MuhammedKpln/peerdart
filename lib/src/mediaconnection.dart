import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sb_peerdart/sb_peerdart.dart';
import 'package:sb_peerdart/src/baseconnection.dart';
import 'package:sb_peerdart/src/logger.dart';
import 'package:sb_peerdart/src/negotiator.dart';
import 'package:sb_peerdart/src/servermessage.dart';
import 'package:sb_peerdart/src/util.dart';

class MediaConnection extends BaseConnection {
  MediaConnection(super.peerId, super.provider, super.options) {
    _localStream = options?.stream;
    connectionId = options?.connectionId ?? _idPrefix + util.randomToken();
    _negotiator = Negotiator(this);

    if (_localStream != null) {
      _negotiator?.startConnection(
          options!.copyWith(originator: true, stream: _localStream));
    }
  }
  final _idPrefix = 'mc_';
  late Negotiator? _negotiator;
  late MediaStream? _localStream;
  // ignore: unused_field
  late MediaStream? _remoteStream;

  void addStream(MediaStream remoteStream) {
    logger.log('Receiving stream $remoteStream');

    _remoteStream = remoteStream;
    // provider?.emit('stream', null, remoteStream); // Should we call this `open`?
    // emit('stream', null, remoteStream); // Should we call this `open`?
    super.emit<MediaStream>(
        'stream', remoteStream); // Should we call this `open`?
  }

  @override
  void dispose() {
    _negotiator?.cleanup();
    _negotiator = null;

    // This make local stream stop when disconnect from other peer
    // _stopMediaDevice();

    _localStream = null;
    _remoteStream = null;

    // TODO: set stream to null when done.
    // if (this.options && this.options._stream) {
    // 	this.options._stream = null;
    // }

    if (!open) {
      return;
    }

    open = false;
  }

  // void _stopMediaDevice() {
  //   final tracks = _localStream?.getTracks();
  //
  //   tracks?.forEach((track) async => await track.stop());
  // }

  @override
  ConnectionType get type => ConnectionType.Media;

  @override
  void handleMessage(ServerMessage message) {
    final payload = message.payload;

    switch (message.type) {
      case ServerMessageType.Answer:
        // Forward to negotiator
        _negotiator?.handleSDP(payload["sdp"]["type"], payload["sdp"]);
        open = true;
        break;
      case ServerMessageType.Candidate:
        _negotiator?.handleCandidate(RTCIceCandidate(
            payload["candidate"]["candidate"],
            payload["candidate"]["sdpMid"],
            payload["candidate"]["sdpMLineIndex"]));
        break;

      default:
        logger.warn(
          "Unrecognized message type:${message.type.type} from peer: $peer",
        );
        break;
    }
  }

  void answer(MediaStream stream, {AnswerOption? callOptions}) {
    if (_localStream != null) {
      logger.warn(
        "Local stream already exists on this MediaConnection. Are you answering a call twice?",
      );
      return;
    }

    _localStream = stream;

    if (callOptions?.sdpTransform != null) {
      callOptions?.sdpTransform = callOptions.sdpTransform;
    }
    final op = PeerConnectOption(
        payload: PeerConnectOption(
            stream: _localStream,
            sdp: options!.payload!.sdp,
            connectionId: options!.payload!.connectionId,
            metadata: options!.payload!.metadata));
    _negotiator?.startConnection(op.payload!);

    // Retrieve lost messages stored because PeerConnection not set up.
    final messages = provider?.getMessages(connectionId);

    if (messages != null) {
      for (var message in messages) {
        handleMessage(message);
      }

      open = true;
    }
  }
}
