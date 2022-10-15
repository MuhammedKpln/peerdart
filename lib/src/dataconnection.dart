import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:peerdart/src/baseconnection.dart';
import 'package:peerdart/src/config.dart';
import 'package:peerdart/src/enums.dart';
import 'package:peerdart/src/logger.dart';
import 'package:peerdart/src/negotiator.dart';
import 'package:peerdart/src/optionInterfaces.dart';
import 'package:peerdart/src/servermessage.dart';

class DataConnection extends BaseConnection {
  DataConnection(super.peerId, super.provider, super.options) {
    connectionId = options?.connectionId ??
        DataConnection.ID_PREFIX + PeerConfig.RANDOM_TOKEN();

    label = options?.label ?? connectionId;
    serialization = options?.serialization ?? SerializationType.JSON;
    reliable = options?.reliable ?? false;

    // this._encodingQueue.on("done", (ab: ArrayBuffer) => {
    // 	this._bufferedSend(ab);
    // });

    // this._encodingQueue.on("error", () => {
    // 	logger.error(
    // 		`DC#${this.connectionId}: Error occured in encoding from blob to arraybuffer, close DC`,
    // 	);
    // 	this.close();
    // });

    _negotiator = Negotiator(this);

    _negotiator?.startConnection(
        options?.payload ?? PeerConnectOption(originator: true));
  }

  static const ID_PREFIX = 'dc_';
  static const MAX_BUFFERED_AMOUNT = 8 * 1024 * 1024;
  late String label;
  late bool reliable;
  late Negotiator? _negotiator;

  SerializationType serialization = SerializationType.JSON;

  late RTCDataChannel? _dc;

  RTCDataChannel? get dataChannel {
    return _dc;
  }

  @override
  void dispose() {
    if (_negotiator != null) {
      _negotiator?.cleanup();
      _negotiator = null;
    }

    dataChannel?.onDataChannelState = null;
    dataChannel?.onMessage = null;
    _dc = null;

    if (!open) {
      return;
    }

    open = false;

    close();
  }

  @override
  void handleMessage(ServerMessage message) {
    final payload = message.payload;

    switch (message.type) {
      case ServerMessageType.Answer:
        logger.log("Got answer");
        _negotiator?.handleSDP(message.type.type, payload["sdp"]);
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

  @override
  ConnectionType get type => ConnectionType.Data;

  /// Called by the Negotiator when the DataChannel is ready. */
  void initialize(RTCDataChannel dc) {
    _dc = dc;
    _configureDataChannel();
  }

  void _configureDataChannel() {
    dataChannel?.onDataChannelState = (state) {
      switch (state) {
        case RTCDataChannelState.RTCDataChannelOpen:
          logger.log('DC#$connectionId dc connection success');
          open = true;
          super.emit<void>('open', null);
          break;

        case RTCDataChannelState.RTCDataChannelClosed:
          logger.log('DC#$connectionId dc closed for:$peer');
          closeRequest();
          dispose();
          break;
      }

      dataChannel?.onMessage = (message) {
        logger.log('DC#$connectionId dc onmessage:${message.text}');
        _handleDataMessage(message);
      };
    };
  }

  void _handleDataMessage(RTCDataChannelMessage message) {
    final datatype = message.type;

    if (datatype == MessageType.text) {
      dynamic deserializedData = jsonDecode(message.text);

      provider?.emit('data', deserializedData);
    }
  }

  void send(dynamic data, {bool? chunked}) {
    if (!open) {
      logger.error(
        "Connection is not open. You should listen for the `open` event before sending messages.",
      );
      super.emit(
        "error",
        Exception(
          "Connection is not open. You should listen for the `open` event before sending messages.",
        ),
      );
      return;
    }

    if (serialization == SerializationType.JSON) {
      dataChannel?.send(RTCDataChannelMessage(jsonEncode(data)));
    }
  }
}
