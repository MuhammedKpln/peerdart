import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:peerdart/src/baseconnection.dart';
import 'package:peerdart/src/dataconnection.dart';

import 'enums.dart';
import 'logger.dart';
import 'mediaconnection.dart';

class Negotiator<T extends BaseConnection> {
  T connection;
  Negotiator(this.connection);

  Future<void> startConnection(dynamic options) async {
    final peerConnection = await _startPeerConnection();
    connection.peerConnection = peerConnection;

    if (connection.type == ConnectionType.Media && options._stream) {
      _addTracksToConnection(options._stream, peerConnection);
    }

    if (options.originator) {
      if (connection.type == ConnectionType.Data) {
        final dataConnection = connection as DataConnection;

        final RTCDataChannelInit config = RTCDataChannelInit();

        final dataChannel = await peerConnection.createDataChannel(
            dataConnection.label, config);
        dataConnection.initialize(dataChannel);
      }
      await _makeOffer();
    } else {
      await handleSDP("OFFER", options.sdp);
    }
  }

  Future<void> handleSDP(String type, dynamic sdp) async {
    sdp = RTCSessionDescription(sdp, type);

    final peerConnection = connection.peerConnection;
    final provider = connection.provider;
    logger.log("Setting remote description $sdp");

    try {
      await peerConnection.setRemoteDescription(sdp);
      logger.log("Set remoteDescription:$type for:${connection.peer}");
      if (type == "OFFER") {
        await _makeAnswer();
      }
    } catch (err) {
      provider.emitError(PeerErrorType.WebRTC, err);
      logger.log("Failed to setRemoteDescription, $err");
    }
  }

  Future<void> _makeAnswer() async {
    final peerConnection = connection.peerConnection;
    final provider = connection.provider;

    try {
      final answer = await peerConnection.createAnswer();
      logger.log("Created answer.");

      try {
        await peerConnection.setLocalDescription(answer);

        logger.log("Set localDescription: $answer for ${connection.peer}");

        provider.socket.send({
          "type": ServerMessageType.Answer,
          "payload": {
            "sdp": answer,
            "type": connection.type,
            "connectionId": connection.connectionId,
            "browser": "s",
          },
          "dst": connection.peer,
        });
      } catch (err) {
        provider.emitError(PeerErrorType.WebRTC, err);
        logger.log("Failed to setLocalDescription, $err");
      }
    } catch (e) {
      logger.log("Failed to create answer, $e");
    }
  }

  Future<void> _makeOffer() async {
    final peerConnection = connection.peerConnection;
    final provider = connection.provider;

    try {
      final offer = await peerConnection.createOffer(
        connection.options.constraints,
      );
      logger.log("Created offer.");

      try {
        await peerConnection.setLocalDescription(offer);

        logger.log("Set localDescription: $offer for ${connection.peer}");

        dynamic payload = {
          "sdp": offer,
          "type": connection.type,
          "connectionId": connection.connectionId,
          "metadata": connection.metadata,
          "browser": "ds",
        };

        if (connection.type == ConnectionType.Data) {
          final dataConnection = connection as DataConnection;

          payload = {
            ...payload,
            "label": dataConnection.label,
            "reliable": dataConnection.reliable,
            "serialization": dataConnection.serialization,
          };

          provider.socket.send({
            "type": ServerMessageType.Offer,
            "payload": payload,
            "dst": connection.peer,
          });
        }
      } catch (e) {
        provider.emitError(PeerErrorType.WebRTC, e);
        logger.log("Failed to setLocalDescription, $e");
      }
    } catch (err) {
      provider.emitError(PeerErrorType.WebRTC, err);
      logger.log("Failed to createOffer, $err");
    }
  }

  Future<RTCPeerConnection> _startPeerConnection() async {
    logger.log("Creating RTCPeerConnection.");

    final peerConnection =
        await createPeerConnection(connection.provider.options.config);

    // this._setupListeners(peerConnection);

    return peerConnection;
  }

  void _addTracksToConnection(
      MediaStream stream, RTCPeerConnection peerConnection) {
    logger.log("add tracks from stream ${stream.id} to peer connection");

    stream
        .getTracks()
        .forEach((track) => peerConnection.addTrack(track, stream));
  }

  void _setupListeners(RTCPeerConnection peerConnection) {
    final peerId = connection.peer;
    final connectionId = connection.connectionId;
    final connectionType = connection.type;
    final provider = connection.provider;

    // ICE CANDIDATES.
    logger.log("Listening for ICE candidates.");

    peerConnection.onIceCandidate = (candidate) {
      logger.log("Received ICE candidates for $peerId: $candidate");

      provider.socket.send({
        "type": ServerMessageType.Candidate,
        "payload": {
          candidate: candidate,
          "type": connectionType,
          connectionId: connectionId,
        },
        "dst": peerId,
      });
    };

    peerConnection.onIceConnectionState = (state) {
      switch (state) {
        case RTCIceConnectionState.RTCIceConnectionStateCompleted:
          peerConnection.onIceCandidate = (_) {};
          break;

        case RTCIceConnectionState.RTCIceConnectionStateFailed:
          logger.log(
            "iceConnectionState is failed, closing connections to $peerId",
          );
          connection.emit(
            "error",
            Exception("${"Negotiation of connection to $peerId"} failed."),
          );
          connection.close();
          break;
        case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
          logger.log(
            "iceConnectionState changed to disconnected on the connection with $peerId",
          );
          break;
        case RTCIceConnectionState.RTCIceConnectionStateClosed:
          logger.log(
            "iceConnectionState is closed, closing connections to $peerId",
          );
          connection.emit(
            "error",
            Exception("Connection to $peerId closed."),
          );
          connection.close();
          break;
      }

      connection.emit(
        "iceStateChanged",
        peerConnection.iceConnectionState,
      );
    };

    // DATACONNECTION.
    logger.log("Listening for data channel");
    // Fired between offer and answer, so options should already be saved
    // in the options hash.

    peerConnection.onDataChannel = (channel) {
      logger.log("Received data channel");

      final dataChannel = channel;

      final DataConnection connection =
          provider.getConnection(peerId, connectionId);

      connection.initialize(dataChannel);
    };

    // MEDIACONNECTION.
    logger.log("Listening for remote stream");

    peerConnection.onTrack = (track) {
      logger.log("Received remote stream");

      final stream = track.streams[0];
      final connection = provider.getConnection(peerId, connectionId);

      if (connection.type == ConnectionType.Media) {
        final mediaConnection = connection as MediaConnection;

        _addStreamToMediaConnection(stream, mediaConnection);
      }
    };
  }

  void cleanup() {
    logger.log("Cleaning up PeerConnection to ${connection.peer}");

    final peerConnection = connection.peerConnection;
    final peerConnectionNotClosed = peerConnection.signalingState != "closed";
    bool dataChannelNotClosed = false;

    if (peerConnection == null) {
      return;
    }

    if (peerConnectionNotClosed || dataChannelNotClosed) {
      peerConnection.close();
    }

    connection.peerConnection.dispose();
  }

  void _addStreamToMediaConnection(
    MediaStream stream,
    MediaConnection mediaConnection,
  ) {
    logger.log(
        "add stream ${stream.id} to media connection ${mediaConnection.connectionId}");

    mediaConnection.addStream(stream);
  }
}
