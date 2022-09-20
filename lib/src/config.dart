// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:uuid/uuid.dart';

const _DEFAULT_CONFIG = {
  'iceServers': [
    {'urls': "stun:stun.l.google.com:19302"},
    {
      'urls': "turn:0.peerjs.com:3478",
      'username': "peerjs",
      'credential': "peerjsp"
    }
  ],
  'sdpSemantics': "unified-plan"
};

class PeerConfig {
  static const CLOUD_HOST = "0.peerjs.com";
  static const CLOUD_PORT = 443;
  static const defaultConfig = _DEFAULT_CONFIG;
  static const DEFAULT_KEY = "peerjs";
  static final RANDOM_TOKEN = Uuid().v4();
}
