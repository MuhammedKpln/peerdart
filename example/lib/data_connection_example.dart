import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:peerdart/peerdart.dart';

class DataConnectionExample extends StatefulWidget {
  const DataConnectionExample({Key? key}) : super(key: key);

  @override
  State<DataConnectionExample> createState() => _DataConnectionExampleState();
}

class _DataConnectionExampleState extends State<DataConnectionExample> {
  Peer peer = Peer(options: PeerOptions(debug: LogLevel.All));
  final TextEditingController _controller = TextEditingController();
  String? peerId;
  late DataConnection conn;
  bool connected = false;

  @override
  void dispose() {
    peer.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    peer.on("open").listen((id) {
      setState(() {
        peerId = peer.id;
      });
    });

    peer.on<DataConnection>("connection").listen((event) {
      conn = event;

      conn.on("data").listen((data) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(data)));
      });

      conn.on("binary").listen((data) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Got binary")));
      });

      conn.on("close").listen((event) {
        setState(() {
          connected = false;
        });
      });

      setState(() {
        connected = true;
      });
    });
  }

  void connect() {
    final connection = peer.connect(_controller.text);
    conn = connection;

    conn.on("open").listen((event) {
      setState(() {
        connected = true;
      });

      connection.on("close").listen((event) {
        setState(() {
          connected = false;
        });
      });

      conn.on("data").listen((data) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(data)));
      });
      conn.on("binary").listen((data) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Got binary!")));
      });
    });
  }

  void sendHelloWorld() {
    conn.send("Hello world!");
  }

  void sendBinary() {
    final bytes = Uint8List(30);
    conn.sendBinary(bytes);
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
              ElevatedButton(
                  onPressed: sendBinary,
                  child: const Text("Send binary to peer")),
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
