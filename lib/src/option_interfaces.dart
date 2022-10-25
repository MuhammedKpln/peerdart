import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:peerdart/peerdart.dart';
import 'package:peerdart/src/util.dart';

import 'config.dart';

class PeerOptions {
  void Function(LogLevel level, dynamic message)? logFunction;
  String? host;
  int? port;
  LogLevel? debug;
  String? path;
  String? key;
  String? token;
  Map<String, dynamic>? config;
  bool secure = true;
  int? pingInterval;

  PeerOptions({
    this.logFunction,
    this.host = PeerConfig.CLOUD_HOST,
    this.port = PeerConfig.CLOUD_PORT,
    this.debug = LogLevel.Disabled,
    this.path = '/',
    this.key = PeerConfig.DEFAULT_KEY,
    this.token,
    this.config = PeerConfig.defaultConfig,
    this.secure = true,
    this.pingInterval,
  }) {
    token = util.randomToken();
  }

  PeerOptions merge(PeerOptions options) => PeerOptions(
      debug: options.debug ?? debug,
      host: options.host ?? host,
      port: options.port ?? port,
      path: options.path ?? path,
      key: options.key ?? key,
      token: options.token ?? token,
      secure: options.secure ?? secure,
      pingInterval: options.pingInterval ?? pingInterval,
      logFunction: options.logFunction ?? logFunction,
      config: options.config ?? config);
}

class PeerConnectOption {
  PeerConnectOption(
      {this.label,
      this.metadata,
      this.reliable,
      this.serialization,
      this.payload,
      this.connectionId,
      this.stream,
      this.sdpTransform,
      this.constraints,
      this.originator,
      this.sdp});

  String? connectionId;
  String? label;
  dynamic metadata;
  SerializationType? serialization;
  bool? reliable;
  PeerConnectOption? payload;
  MediaStream? stream;
  Function? sdpTransform;
  Map<String, dynamic>? constraints;
  bool? originator;
  Map<String, dynamic>? sdp;

  PeerConnectOption copyWith(
      {String? connectionId,
      String? label,
      dynamic metadata,
      SerializationType? serialization,
      bool? reliable,
      PeerConnectOption? payload,
      MediaStream? stream,
      Function? sdpTransform,
      Map<String, dynamic>? constraints,
      bool? originator}) {
    return PeerConnectOption(
      connectionId: connectionId ?? this.connectionId,
      label: label ?? this.label,
      metadata: metadata ?? this.metadata,
      serialization: serialization ?? this.serialization,
      reliable: reliable ?? this.reliable,
      payload: payload ?? this.payload,
      stream: stream ?? this.stream,
      sdpTransform: sdpTransform ?? this.sdpTransform,
      constraints: constraints ?? this.constraints,
      originator: originator ?? this.originator,
    );
  }

  factory PeerConnectOption.fromMap(Map<String, dynamic> json) =>
      PeerConnectOption(
        label: json["label"],
        metadata: json["metadata"],
        serialization: json["serialization"] != null
            ? SerializationType.values
                .singleWhere((element) => element.type == json["serialization"])
            : null,
        reliable: json["reliable"],
        sdp: json["sdp"],
        payload: json["payload"] != null
            ? PeerConnectOption.fromMap(json["payload"])
            : null,
        originator: json["originator"],
      );

  Map<String, dynamic> toMap() => {
        "label": label,
        "metadata": metadata,
        "serialization": serialization,
        "reliable": reliable,
        "payload": payload,
        "stream": stream,
        "constraints": constraints,
        "originator": originator,
        "sdp": sdp
      };
}

abstract class CallOption {
  dynamic metadata;
  Function? sdpTransform;

  Map<String, dynamic> toMap() => {
        "metadata": metadata,
        "sdpTransform": sdpTransform,
      };
}

abstract class AnswerOption {
  Function? sdpTransform;
}
