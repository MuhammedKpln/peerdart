import 'config.dart';

class PeerOptions {
  Function? logFunction;
  String? host;
  int? port;
  int? debug;
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
    this.debug = 0,
    this.path = '/',
    this.key = PeerConfig.DEFAULT_KEY,
    this.token,
    this.config = PeerConfig.defaultConfig,
    this.secure = true,
    this.pingInterval,
  }) {
    token = PeerConfig.RANDOM_TOKEN;
  }
}
