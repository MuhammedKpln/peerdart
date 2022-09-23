import 'package:flutter/material.dart';
import 'package:peerdart/peerdart.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallExample extends StatefulWidget {
  const CallExample({Key? key}) : super(key: key);

  @override
  State<CallExample> createState() => _CallExampleState();
}

class _CallExampleState extends State<CallExample> {
  final TextEditingController _controller = TextEditingController();
  final Peer peer = Peer(options: PeerOptions(debug: LogLevel.All));
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  bool inCall = false;
  String? peerId;

  @override
  void initState() {
    super.initState();
    _localRenderer.initialize();
    _remoteRenderer.initialize();

    peer.on("open", null, (ev, context) {
      setState(() {
        peerId = peer.id;
      });
    });

    peer.on("call", null, (ev, context) async {
      final call = ev.eventData as MediaConnection;
      final mediaStream = await navigator.mediaDevices
          .getUserMedia({"video": true, "audio": false});

      call.answer(mediaStream);

      call.on("stream", null, (ev, _) async {
        _localRenderer.srcObject = mediaStream;
        _remoteRenderer.srcObject = ev.eventData as MediaStream;

        setState(() {
          inCall = true;
        });
      });
    });
  }

  @override
  void dispose() {
    peer.destroy();
    _controller.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  void connect() async {
    final mediaStream = await navigator.mediaDevices
        .getUserMedia({"video": true, "audio": false});

    final conn = peer.call(_controller.text, mediaStream);

    conn.on("stream", null, (ev, _) {
      _remoteRenderer.srcObject = ev.eventData as MediaStream;
      _localRenderer.srcObject = mediaStream;

      setState(() {
        inCall = true;
      });
    });

    // });
  }

  void send() {
    // conn.send('Hello!');
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _renderState(),
              const Text(
                'Connection ID:',
              ),
              SelectableText(peerId ?? ""),
              TextField(
                controller: _controller,
              ),
              ElevatedButton(onPressed: connect, child: const Text("connect")),
              ElevatedButton(
                  onPressed: send, child: const Text("send message")),
              if (inCall)
                Expanded(
                  child: RTCVideoView(
                    _localRenderer,
                  ),
                ),
              if (inCall)
                Expanded(
                  child: RTCVideoView(
                    _remoteRenderer,
                  ),
                ),
            ],
          ),
        ));
  }

  Widget _renderState() {
    Color bgColor = inCall ? Colors.green : Colors.grey;
    Color txtColor = Colors.white;
    String txt = inCall ? "Connected" : "Standby";
    return Container(
      decoration: BoxDecoration(color: bgColor),
      child: Text(
        txt,
        style:
            Theme.of(context).textTheme.titleLarge?.copyWith(color: txtColor),
      ),
    );
  }
}
