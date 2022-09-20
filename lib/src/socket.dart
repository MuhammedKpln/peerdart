import 'dart:convert';

import 'package:eventify/eventify.dart';
import 'package:peerdart/src/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'enums.dart';
import 'optionInterfaces.dart';

class Socket extends EventEmitter {
  late bool _disconnected = true;
  late String? _id;
  late List<Object> _messagesQueue = [];
  late WebSocketChannel? _socket;
  late dynamic _wsPingTimer;
  late String _baseUrl;
  late PeerOptions options;

  Socket(this.options) {
    options.pingInterval = options.pingInterval ?? 5000;

    final wsProtocol = options.secure ? "wss://" : "ws://";

    _baseUrl =
        "$wsProtocol${options.host}:${options.port}${options.path}peerjs?key=${options.key}";
  }

  void start(String id, String token) {
    _id = id;

    final wsUrl = "$_baseUrl&id=$id&token=$token";

    if (_socket != null || !_disconnected) {
      return;
    }

    _socket = WebSocketChannel.connect(Uri.parse(_baseUrl));
    _disconnected = false;

    _socket?.stream.listen((event) {
      dynamic data;

      try {
        data = jsonDecode(event.data);

        logger.log("Server message received:$data");
      } catch (e) {
        logger.log("Invalid server message: $event");
        return;
      }

      emit(SocketEventType.Message.type, data);
    }, onDone: () {
      if (_disconnected) {
        return;
      }

      logger.log("Socket closed.");

      _cleanup();
      _disconnected = true;

      emit(SocketEventType.Disconnected.type);
    });

    _sendQueuedMessages();

    logger.log("Socket open");

    _scheduleHeartbeat();
  }

  void _scheduleHeartbeat() {
    _wsPingTimer = Future.delayed(
        Duration(milliseconds: options.pingInterval ?? 5000),
        () => _sendHeartbeat());
  }

  void _sendHeartbeat() {
    if (!_wsOpen()) {
      logger.log("Cannot send heartbeat, because socket closed");
      return;
    }

    final message = jsonEncode({"type": ServerMessageType.Heartbeat.type});

    _socket?.sink.add(message);

    _scheduleHeartbeat();
  }

  void close() {
    if (_disconnected) {
      return;
    }

    _cleanup();

    _disconnected = true;
  }

  void send(dynamic data) {
    if (_disconnected) {
      return;
    }

    // If we didn't get an ID yet, we can't yet send anything so we should queue
    // up these messages.
    if (_id != null) {
      _messagesQueue.add(data);
      return;
    }

    if (!data.type) {
      emit(SocketEventType.Error.type, "Invalid message");
      return;
    }

    if (!_wsOpen()) {
      return;
    }

    final message = jsonEncode(data);

    _socket?.sink.add(message);
  }

  bool _wsOpen() {
    return _socket != null && _socket?.protocol != null;
  }

  void _sendQueuedMessages() {
    final copiedQueue = [..._messagesQueue];
    _messagesQueue = [];

    for (var message in copiedQueue) {
      send(message);
    }
  }

  void _cleanup() {
    _socket?.sink.close();

    super.clear();
  }
}
