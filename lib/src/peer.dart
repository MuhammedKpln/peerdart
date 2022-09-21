import 'package:eventify/eventify.dart';
import 'package:peerdart/src/api.dart';
import 'package:peerdart/src/config.dart';
import 'package:peerdart/src/dataconnection.dart';
import 'package:peerdart/src/enums.dart';
import 'package:peerdart/src/logger.dart';
import 'package:peerdart/src/optionInterfaces.dart';
import 'package:peerdart/src/servermessage.dart';
import 'package:peerdart/src/socket.dart';
import 'package:peerdart/src/util.dart';

class Peer extends EventEmitter {
  Peer({String? id, PeerOptions? options}) {
    String? userId = id;

    PeerOptions initOptions = PeerOptions(
        debug: 0,
        host: PeerConfig.CLOUD_HOST,
        port: PeerConfig.CLOUD_PORT,
        path: "/",
        key: _DEFAULT_KEY,
        token: util.randomToken(),
        config: PeerConfig.defaultConfig);

    if (options != null) {
      initOptions = initOptions.merge(options);
    }

    _options = initOptions;

    // Set path correctly.
    if (_options.path != '/') {
      _options.path = '/${_options.path}';
    }

    // Set a custom log function if present
    if (_options.logFunction != null) {
      logger.setLogFunction(_options.logFunction!);
    }

    logger.logLevel = this.options.debug ?? 0;

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
  late Map<String, List<dynamic>> _connections;
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

    socket.on(SocketEventType.Message.type, null, (ev, context) {
      final ctx = ServerMessage.fromMap(ev.eventData as Map<String, dynamic>);

      _handleMessage(ctx);
    });

    socket.on(SocketEventType.Error.type, null, (ev, context) {
      _abort(PeerErrorType.SocketError, context);
    });

    socket.on(SocketEventType.Disconnected.type, null, (ev, context) {
      if (disconnected) {
        return;
      }

      emitError(PeerErrorType.Network, 'Lost connection to server.');
      disconnect();
    });

    socket.on(SocketEventType.Close.type, null, (ev, context) {
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
        emit('open', id);
        break;
    }
  }

  // MediaConnection call(String peer, MediaStream stream, {CallOption? options}) {
  //   if (disconnected) {
  //     logger.warn(
  //       "You cannot connect to a new Peer because you called .disconnect() on this Peer and ended your connection with the server. You can create a new Peer to reconnect.",
  //     );
  //     emitError(
  //       PeerErrorType.Disconnected,
  //       "Cannot connect to new Peer after disconnecting from server.",
  //     );
  //   }

  //   dynamic organizedOptions = {"_stream": stream};

  //   if (options != null) {
  //     organizedOptions = {"_stream": stream, ...options.toMap()};
  //   }

  //   final mediaConnection = MediaConnection(peer, this, organizedOptions);
  //   _addConnection(peer, mediaConnection);
  //   return mediaConnection;
  // }

  void _abort(PeerErrorType type, dynamic message) {
    logger.error('Aborting!');

    emitError(type, message);

    if (_lastServerId != null) {
      destroy();
    } else {
      disconnect();
    }
  }

  void emitError(PeerErrorType type, dynamic err) {
    logger.error('Error: $err');

    emit(SocketEventType.Error.type, err);
  }

  void destroy() {
    if (destroyed) {
      return;
    }
    logger.log('Destroy peer with ID:$id');

    disconnect();
    _cleanup();

    _destroyed = true;

    emit('close');
  }

  void _cleanup() {
    for (final event in SocketEventType.values) {
      socket.removeAllByEvent(event.type);
    }
  }

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

    emit(SocketEventType.Disconnected.type, currentId);
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
    _addConnection(peer, dataConnection);
    return dataConnection;
  }

  /// Add a data/media connection to this peer. */
  /// connection: DataConnection / MediaConnection
  void _addConnection(String peerId, dynamic connection) {
    logger.log(
      'add connection ${connection.type}:${connection.connectionId} to peerId:$peerId',
    );

    if (!_connections.containsKey(peerId)) {
      _connections[peerId] = [];
    }

    _connections[peerId]?.add(connection);
  }

  /// connection: DataConnection / MediaConnection
  void _removeConnection(dynamic connection) {
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
}
