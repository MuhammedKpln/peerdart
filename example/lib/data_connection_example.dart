import 'package:flutter/material.dart';
import 'package:peerdart/peerdart.dart';

class DataConnectionExample extends StatefulWidget {
  const DataConnectionExample({Key? key}) : super(key: key);

  @override
  State<DataConnectionExample> createState() => _DataConnectionExampleState();
}

class _DataConnectionExampleState extends State<DataConnectionExample> {
  Peer peer = Peer();
  final TextEditingController _controller = TextEditingController();
  String? peerId;
  late DataConnection conn;
  bool connected = false;

  @override
  void initState() {
    super.initState();

    peer.on("open", null, (ev, context) {
      setState(() {
        peerId = peer.id;
      });
    });

    peer.on("connection", null, (ev, context) {
      conn = ev.eventData as DataConnection;

      setState(() {
        connected = true;
      });
    });

    peer.on("data", null, (ev, _) {
      final data = ev.eventData as String;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data)));
    });
  }

  void connect() {
    final connection = peer.connect(_controller.text);
    conn = connection;

    conn.on("open", null, (ev, _) {
      setState(() {
        connected = true;
      });

      conn.on("data", null, (ev, _) {
        final data = ev.eventData as String;

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(data)));
      });
    });
  }

  void sendHelloWorld() {
    conn.send("Hello world!");
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
                  onPressed: sendHelloWorld,
                  child: const Text("Send Hello World to peer")),
            ],
          ),
        ));
  }

  Widget _renderState() {
    Color bgColor = connected ? Colors.green : Colors.grey;
    Color txtColor = Colors.white;
    String txt = connected ? "Connected" : "Standby";
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
