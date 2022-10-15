import 'dart:convert';

import 'package:events_emitter/emitters/stream_event_emitter.dart';
import 'package:peerdart/src/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'enums.dart';
import 'option_interfaces.dart';

class Socket extends StreamEventEmitter {
  bool _disconnected = true;
  late String? _id;
  late List<Map<String, dynamic>> _messagesQueue = [];
  late WebSocketChannel? _socket;
  late Uri _baseUrl;
  PeerOptions options;

  Socket(this.options) {
    options.pingInterval = options.pingInterval ?? 5000;

    final wsProtocol = options.secure ? "wss" : "ws";

    _baseUrl = Uri(
        scheme: wsProtocol,
        host: options.host,
        port: options.port,
        path: "${options.path}peerjs",
        queryParameters: {"key": options.key});
  }

  void start(String id, String token) {
    _id = id;

    final wsUrl = "$_baseUrl&id=$id&token=$token&version=1";

    if (!_disconnected) {
      return;
    }

    _socket = WebSocketChannel.connect(Uri.parse(wsUrl));
    _disconnected = false;

    _socket?.stream.listen((event) {
      dynamic data;

      try {
        data = jsonDecode(event);
        logger.log("Server message received:$data");
      } catch (e) {
        logger.error("Invalid server message: $event");
        return;
      }

      emit<Map<String, dynamic>>(SocketEventType.Message.type, data);
    }, onDone: () {
      if (_disconnected) {
        return;
      }

      logger.log("Socket closed.");

      _cleanup();

      emit<void>(SocketEventType.Disconnected.type, null);
    });

    _sendQueuedMessages();

    logger.log("Socket open");

    _scheduleHeartbeat();
  }

  void _scheduleHeartbeat() {
    Future.delayed(Duration(milliseconds: options.pingInterval ?? 5000),
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

  void dispose() {
    if (_disconnected) {
      return;
    }

    _cleanup();

    _disconnected = true;
  }

  void send(Map<String, dynamic> data) {
    if (_disconnected) {
      logger.error("Socket disconnected!");

      return;
    }

    // If we didn't get an ID yet, we can't yet send anything so we should queue
    // up these messages.
    if (_id == null) {
      _messagesQueue.add(data);
      return;
    }

    if (data["type"] == null) {
      emit<String>(SocketEventType.Error.type, "Invalid message");
      return;
    }

    if (!_wsOpen()) {
      logger.error("Socket not open!");
      return;
    }

    final message = jsonEncode(data);

    _socket?.sink.add(message);
  }

  bool _wsOpen() {
    return !_disconnected;
  }

  void _sendQueuedMessages() {
    final copiedQueue = [..._messagesQueue];
    _messagesQueue = [];

    for (var message in copiedQueue) {
      send(message);
    }
  }

  void _cleanup() {
    _disconnected = true;
    _socket?.sink.close();

    // Close all the emitters
    close();
  }
}
