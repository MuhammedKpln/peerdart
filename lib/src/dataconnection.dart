import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:peerdart/src/baseconnection.dart';
import 'package:peerdart/src/enums.dart';
import 'package:peerdart/src/logger.dart';
import 'package:peerdart/src/servermessage.dart';

class DataConnection extends BaseConnection {
  DataConnection(super.peerId, super.provider, super.options);
  static const ID_PREFIX = 'dc_';
  static const MAX_BUFFERED_AMOUNT = 8 * 1024 * 1024;
  late String label;
  late bool reliable;

  SerializationType serialization = SerializationType.JSON;

  late RTCDataChannel _dc;

  RTCDataChannel get dataChannel {
    return _dc;
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

  /// Called by the Negotiator when the DataChannel is ready. */
  void initialize(RTCDataChannel dc) {
    _dc = dc;
    _configureDataChannel();
  }

  void _configureDataChannel() {
    dataChannel.onDataChannelState = (state) {
      switch (state) {
        case RTCDataChannelState.RTCDataChannelOpen:
          logger.log('DC#$connectionId dc connection success');
          open = true;
          emit('open');
          break;

        case RTCDataChannelState.RTCDataChannelClosed:
          logger.log('DC#$connectionId dc closed for:$peer');
          close();
          break;
      }

      dataChannel.onMessage = (message) {
        logger.log('DC#$connectionId dc onmessage:$message');
        _handleDataMessage(message);
      };
    };
  }

  void _handleDataMessage(RTCDataChannelMessage message) {
    final datatype = message.type;

    dynamic deserializedData;

    if (datatype == MessageType.text) {
      deserializedData = jsonDecode(message.text);
    }

    emit('data', deserializedData);
  }
}
