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

      conn.on("close").listen((event) {
        setState(() {
          connected = false;
        });
      });

      setState(() {
        connected = true;
      });
    });

    peer.on("data").listen((data) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data)));
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
