import 'package:eventify/eventify.dart';
import 'package:peerdart/src/api.dart';
import 'package:peerdart/src/config.dart';
import 'package:peerdart/src/enums.dart';
import 'package:peerdart/src/optionInterfaces.dart';
import 'package:peerdart/src/servermessage.dart';
import 'package:peerdart/src/socket.dart';

import 'logger.dart';

class Peer extends EventEmitter {
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

  // final Map<String, List<M>> _connections =
  //     {}; // All connections for this peer.
  // final Map<String, List<ServerMessage>> _lostMessages =
  //     {}; // src => [list of messages]}

  get id {
    return _id;
  }

  get options {
    return _options;
  }

  get open {
    return _open;
  }

  Socket get socket {
    return _socket;
  }

  get destroyed {
    return _destroyed;
  }

  get disconnected {
    return _disconnected;
  }

  Peer({String? id, PeerOptions? options}) {
    String? userId;

    if (options != null) {
      _options = options;

      if (id != null && id is PeerOptions) {
        _options = id as PeerOptions;
      } else if (id != null) {
        userId = id.toString();
      }

      // Set path correctly.
      if (_options.path != "/") {
        _options.path = "/${_options.path}";
      }

      // Set a custom log function if present
      if (_options.logFunction != null) {
        logger.setLogFunction(_options.logFunction!);
      }

      logger.logLevel = this.options.debug ?? 0;

      _api = API(options: _options);
      // _socket = this._createServerConnection();

      Socket _createServerConnection() {
        final socket = Socket(_options);

        socket.on(SocketEventType.Message.type, null, (ev, context) {
          final ctx = context as ServerMessage;

          _handleMessage(ctx);
        });

        socket.on(SocketEventType.Error.type, null, (ev, context) {
          _abort(PeerErrorType.SocketError, context);
        });

        socket.on(SocketEventType.Disconnected.type, null, (ev, context) {
          if (disconnected) {
            return;
          }

          emitError(PeerErrorType.Network, "Lost connection to server.");
          disconnect();
        });

        socket.on(SocketEventType.Close.type, null, (ev, context) {
          if (disconnected) {
            return;
          }

          _abort(
            PeerErrorType.SocketClosed,
            "Underlying socket is already closed.",
          );
        });

        return socket;
      }
    }
  }

  void _handleMessage(ServerMessage message) {
    final type = message.type;
    final payload = message.payload;
    final peerId = message.src;

    switch (type) {
      case ServerMessageType.Heartbeat:
        // TODO: Handle this case.
        break;
      case ServerMessageType.Candidate:
        // TODO: Handle this case.
        break;
      case ServerMessageType.Offer:
        // TODO: Handle this case.
        break;
      case ServerMessageType.Answer:
        // TODO: Handle this case.
        break;
      case ServerMessageType.Open:
        _lastServerId = id;
        _open = true;
        emit("open", id);
        break;
      case ServerMessageType.Error:
        // TODO: Handle this case.
        break;
      case ServerMessageType.IdTaken:
        // TODO: Handle this case.
        break;
      case ServerMessageType.InvalidKey:
        // TODO: Handle this case.
        break;
      case ServerMessageType.Leave:
        // TODO: Handle this case.
        break;
      case ServerMessageType.Expire:
        // TODO: Handle this case.
        break;
    }
  }

  void _abort(PeerErrorType type, dynamic message) {
    logger.error("Aborting!");

    emitError(type, message);

    if (_lastServerId != null) {
      destroy();
    } else {
      disconnect();
    }
  }

  void emitError(PeerErrorType type, dynamic err) {
    logger.error("Error: $err");

    emit(SocketEventType.Error.type, err);
  }

  void destroy() {
    if (destroyed) {
      return;
    }
    logger.log("Destroy peer with ID:$id");

    disconnect();
    _cleanup();

    _destroyed = true;

    emit("close");
  }

  void _cleanup() {
    for (var event in SocketEventType.values) {
      socket.removeAllByEvent(event.type);
    }
  }

  void disconnect() {
    if (disconnected) {
      return;
    }
    final currentId = id;
    logger.log("Disconnect peer with ID:$currentId");

    _disconnected = true;
    _open = false;

    socket.close();

    _lastServerId = currentId;
    _id = null;

    emit(SocketEventType.Disconnected.type, currentId);
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
