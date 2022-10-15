import 'package:events_emitter/emitters/stream_event_emitter.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:peerdart/src/api.dart';
import 'package:peerdart/src/baseconnection.dart';
import 'package:peerdart/src/config.dart';
import 'package:peerdart/src/dataconnection.dart';
import 'package:peerdart/src/enums.dart';
import 'package:peerdart/src/logger.dart';
import 'package:peerdart/src/mediaconnection.dart';
import 'package:peerdart/src/optionInterfaces.dart';
import 'package:peerdart/src/servermessage.dart';
import 'package:peerdart/src/socket.dart';
import 'package:peerdart/src/util.dart';

class Peer extends StreamEventEmitter {
  Peer({String? id, PeerOptions? options}) {
    String? userId = id;

    PeerOptions initOptions = PeerOptions(
        debug: LogLevel.Disabled,
        host: PeerConfig.CLOUD_HOST,
        port: PeerConfig.CLOUD_PORT,
        path: "/",
        key: _DEFAULT_KEY,
        token: util.randomToken(),
        config: PeerConfig.defaultConfig);

    if (options != null) {
      initOptions = initOptions.merge(options);
    }

    print(initOptions.port);
    _options = initOptions;

    // Set path correctly.
    if (_options.path != '/') {
      _options.path = '/${_options.path}';
    }

    // Set a custom log function if present
    if (_options.logFunction != null) {
      logger.setLogFunction(_options.logFunction!);
    }

    logger.logLevel = this.options.debug ?? LogLevel.Disabled;

    _api = API(options: _options);
    _socket = _createServerConnection();

    if (userId != null) {
      _initialize(userId);
    } else {
      _api
          .retrieveId()
          .then((value) => _initialize(value))
          .catchError((error) => _abort(PeerErrorType.ServerError, error));
    }
  }

  static const _DEFAULT_KEY = PeerConfig.DEFAULT_KEY;
  late PeerOptions _options;
  late API _api;
  late Socket _socket;

  String? _id;
  String? _lastServerId;

  // States.
  bool _destroyed = false;
  bool _disconnected = false;
  bool _open = false;
  final Map<String, List<dynamic>> _connections = {};
  final Map<String, List<ServerMessage>> _lostMessages = {};

  String? get id {
    return _id;
  }

  PeerOptions get options {
    return _options;
  }

  bool get open {
    return _open;
  }

  Socket get socket {
    return _socket;
  }

  bool get destroyed {
    return _destroyed;
  }

  bool get disconnected {
    return _disconnected;
  }

  void _initialize(String id) {
    _id = id;
    _socket.start(id, _options.token ?? "ssdsew");
  }

  Socket _createServerConnection() {
    final socket = Socket(_options);

    socket
        .on<Map<String, dynamic>>(SocketEventType.Message.type)
        .listen((data) {
      final ctx = ServerMessage.fromMap(data);

      _handleMessage(ctx);
    });

    socket.on<String>(SocketEventType.Error.type).listen((event) {
      _abort(PeerErrorType.SocketError, event);
    });

    socket.on(SocketEventType.Disconnected.type).listen((event) {
      if (disconnected) {
        return;
      }

      emitError(PeerErrorType.Network, 'Lost connection to server.');
      disconnect();
    });

    socket.on(SocketEventType.Close.type).listen((event) {
      if (disconnected) {
        return;
      }

      _abort(
        PeerErrorType.SocketClosed,
        'Underlying socket is already closed.',
      );
    });

    return socket;
  }

  void _handleMessage(ServerMessage message) {
    final type = message.type;
    final payload = message.payload;
    final peerId = message.src;

    switch (type) {
      case ServerMessageType.Open:
        _lastServerId = id;
        _open = true;

        emit<String?>("open", id);
        break;

      case ServerMessageType.Error:
        _abort(PeerErrorType.ServerError, payload.msg);
        break;
      case ServerMessageType.IdTaken: // The selected ID is taken.
        _abort(PeerErrorType.UnavailableID, "ID $id is taken");
        break;
      case ServerMessageType.InvalidKey: // The given API key cannot be found.
        _abort(
          PeerErrorType.InvalidKey,
          'API KEY "${_options.key}" is invalid',
        );
        break;
      case ServerMessageType
          .Leave: // Another peer has closed its connection to this peer.
        logger.log("Received leave message from $peerId");
        if (peerId != null) {
          _cleanupPeer(peerId);
          _connections.removeWhere(((key, value) => key == peerId));
        }
        break;
      case ServerMessageType
          .Expire: // The offer sent to a peer has expired without response.
        emitError(
          PeerErrorType.PeerUnavailable,
          "Could not connect to peer $peerId",
        );
        break;

      case ServerMessageType.Offer:
        {
          // we should consider switching this to CALL/CONNECT, but this is the least breaking option.
          final connectionId = payload["connectionId"];
          if (peerId != null) {
            var connection = getConnection(peerId, connectionId);

            if (connection != null) {
              connection.close();
              logger.warn(
                "Offer received for existing Connection ID:$connectionId",
              );
            }
            // Create a new connection.
            if (payload["type"] == ConnectionType.Media.type) {
              final serializedPayload = PeerConnectOption.fromMap(payload);

              final data = PeerConnectOption(
                  connectionId: connectionId,
                  payload: serializedPayload,
                  metadata: payload["metadata"]);

              final mediaConnection = MediaConnection(peerId, this, data);
              connection = mediaConnection;

              _addConnection(peerId, mediaConnection: connection);
              emit<MediaConnection>("call", mediaConnection);
            } else if (payload["type"] == ConnectionType.Data.type) {
              final serializedPayload = PeerConnectOption.fromMap(payload);

              final data = PeerConnectOption(
                connectionId: connectionId,
                payload: serializedPayload,
                metadata: payload["metadata"],
                label: payload["label"],
                serialization: SerializationType.values.singleWhere(
                    (element) => element.type == payload["serialization"]),
                reliable: payload["reliable"],
              );

              final dataConnection = DataConnection(peerId, this, data);
              connection = dataConnection;
              _addConnection(peerId, dataConnection: connection);
              emit<DataConnection>("connection", dataConnection);
            } else {
              logger.warn("Received malformed connection type:${payload.type}");
              return;
            }

            // Find messages.
            final messages = getMessages(connectionId);

            for (var message in messages) {
              connection.handleMessage(message);
            }
          }
        }
        break;

      default:
        {
          if (payload == null) {
            logger.warn(
              "You received a malformed message from $peerId of type $type",
            );
            return;
          }

          final connectionId = payload["connectionId"];
          final connection = getConnection(peerId!, connectionId);

          if (connection != null && connection.peerConnection != null) {
            // Pass it on.
            connection.handleMessage(message);
          } else if (connectionId != null) {
            // Store for possible later use
            _storeMessage(connectionId, message);
          } else {
            logger.warn("You received an unrecognized message:$message");
          }
        }
    }
  }

  MediaConnection call(String peer, MediaStream stream, {CallOption? options}) {
    if (disconnected) {
      logger.warn(
        "You cannot connect to a new Peer because you called .disconnect() on this Peer and ended your connection with the server. You can create a new Peer to reconnect.",
      );
      emitError(
        PeerErrorType.Disconnected,
        "Cannot connect to new Peer after disconnecting from server.",
      );
    }

    PeerConnectOption organizedOptions = PeerConnectOption(stream: stream);

    if (options != null) {
      organizedOptions = organizedOptions.copyWith(
          metadata: options.metadata, sdpTransform: options.sdpTransform);
    }

    final mediaConnection = MediaConnection(peer, this, organizedOptions);
    _addConnection(peer, mediaConnection: mediaConnection);
    return mediaConnection;
  }

  void _abort(PeerErrorType type, dynamic message) {
    logger.error('Aborting!');

    emitError(type, message);

    if (_lastServerId != null) {
      dispose();
    } else {
      disconnect();
    }
  }

  void emitError(PeerErrorType type, dynamic err) {
    logger.error('Error: $err');

    emit<dynamic>(SocketEventType.Error.type, err);
  }

  void dispose() {
    if (destroyed) {
      return;
    }
    logger.log('Destroy peer with ID:$id');

    disconnect();

    _destroyed = true;

    emit<void>('close', null);

    _cleanup();
  }

  void _cleanup() {
    final List<String> toRemove = [];
    for (var peer in _connections.keys) {
      toRemove.add(peer);
    }
    for (var peer in toRemove) {
      _cleanupPeer(peer);
      _connections.removeWhere((key, value) => key == peer);
    }

    close();
  }

  /// Attempts to reconnect with the same ID. */
  void reconnect() {
    if (disconnected && !destroyed) {
      logger.log(
        "Attempting reconnection to server with ID $_lastServerId",
      );
      _disconnected = false;
      _initialize(_lastServerId!);
    } else if (destroyed) {
      throw Exception(
        "This peer cannot reconnect to the server. It has already been destroyed.",
      );
    } else if (!disconnected && !open) {
      logger.error(
        "In a hurry? We're still trying to make the initial connection!",
      );
    } else {
      throw Exception(
        "Peer $id cannot reconnect because it is not disconnected from the server!",
      );
    }
  }

  /// Disconnects the Peer's connection to the PeerServer. Does not close any
  ///  active connections.
  /// Warning: The peer can no longer create or accept connections after being
  ///  disconnected. It also cannot reconnect to the server.
  void disconnect() {
    if (disconnected) {
      return;
    }
    final currentId = id;
    logger.log('Disconnect peer with ID:$currentId');

    _disconnected = true;
    _open = false;

    socket.close();

    _lastServerId = currentId;
    _id = null;

    emit<String?>(SocketEventType.Disconnected.type, currentId);
  }

  DataConnection connect(String peer, {PeerConnectOption? options}) {
    if (disconnected) {
      logger.warn(
        'You cannot connect to a new Peer because you called .disconnect() on this Peer and ended your connection with the server. You can create a new Peer to reconnect, or call reconnect on this peer if you believe its ID to still be available.',
      );
      emitError(
        PeerErrorType.Disconnected,
        'Cannot connect to new Peer after disconnecting from server.',
      );
      throw Exception(
        'Cannot connect to new Peer after disconnecting from server.',
      );
    }

    final dataConnection = DataConnection(peer, this, options);
    _addConnection(peer, dataConnection: dataConnection);
    return dataConnection;
  }

  /// Add a data/media connection to this peer. */
  /// connection: DataConnection / MediaConnection
  void _addConnection(String peerId,
      {DataConnection? dataConnection, MediaConnection? mediaConnection}) {
    late BaseConnection connection;

    if (mediaConnection != null) {
      connection = mediaConnection;
    }

    if (dataConnection != null) {
      connection = dataConnection;
    }

    logger.log(
      'add connection ${connection.type}:${connection.connectionId} to peerId:$peerId',
    );

    if (!_connections.containsKey(peerId)) {
      _connections[peerId] = [];
    }

    _connections[peerId]?.add(connection);
  }

  /// connection: DataConnection / MediaConnection

  void removeConnection(dynamic connection) {
    final connections = _connections[connection.peer] as List<dynamic>;

    final index = connections
        .indexWhere((c) => c.connectionId == connection.connectionId);

    connections.removeAt(index);

    //remove from lost messages
    _lostMessages.removeWhere((k, v) => k == connection.connectionId);
  }

  /// Retrieve a data/media connection for this peer. */
  dynamic getConnection(String peerId, String connectionId) {
    if (!_connections.containsKey(peerId)) {
      logger.error("Could not get connection with id: $peerId");
      return null;
    }
    final connections = _connections[peerId];

    if (connections != null) {
      for (final connection in connections) {
        if (connection.connectionId == connectionId) {
          return connection;
        }
      }
    }

    return null;
  }

  void _cleanupPeer(String peerId) {
    final connections = _connections[peerId];

    if (connections == null) return;

    for (var connection in connections) {
      connection?.dispose();
    }
  }

  /// Stores messages without a set up connection, to be claimed later. */
  List<ServerMessage> getMessages(String connectionId) {
    final messages = _lostMessages[connectionId];

    if (messages != null) {
      _lostMessages.removeWhere((key, value) => key == connectionId);

      return messages;
    }

    return [];
  }

  /// Stores messages without a set up connection, to be claimed later. */
  void _storeMessage(String connectionId, ServerMessage message) {
    if (!_lostMessages.containsKey(connectionId)) {
      _lostMessages[connectionId] = [];
    }

    _lostMessages[connectionId]?.add(message);
  }
}
