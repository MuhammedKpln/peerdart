import 'package:http/http.dart';
import 'package:peerdart/src/config.dart';
import 'package:http/http.dart' as http;
import 'package:peerdart/src/logger.dart';
import 'package:peerdart/src/option_interfaces.dart';

class API {
  late PeerOptions _options;

  API({PeerOptions? options}) {
    if (options != null) {
      _options = options;
    }
  }

  Future<Response> _buildRequest(String method) async {
    final url = _buildUrl(method);

    return await http.get(url);
  }

  Future<String> retrieveId() async {
    try {
      final response = await _buildRequest("id");

      if (response.statusCode != 200) {
        throw Exception('Error. Status:${response.statusCode}');
      }

      return response.body;
    } catch (err) {
      logger.error("Error retrieving ID $err");

      var pathError = "";

      if (_options.path == "/" && _options.host != PeerConfig.CLOUD_HOST) {
        pathError =
            " If you passed in a `path` to your self-hosted PeerServer, you'll also need to pass in that same path when creating a new Peer.";
      }

      throw Exception("Could not get an ID from the server.$pathError");
    }
  }

  String _setProtocol() {
    if (_options.secure) {
      return "https";
    }

    return "http";
  }

  Uri _buildUrl(String method) {
    final protocol = _setProtocol();
    final path = '${_options.path}${_options.key}/$method';

    return Uri(
        scheme: protocol,
        host: _options.host,
        port: _options.port,
        path: path,
        queryParameters: {
          "ts": DateTime.now().microsecondsSinceEpoch.toString(),
          "version": PeerConfig.VERSION.toString()
        });
  }
}
