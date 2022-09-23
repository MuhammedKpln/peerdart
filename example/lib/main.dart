import 'package:example/call_example.dart';
import 'package:example/data_connection_example.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PeerDart Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: "/",
      routes: {
        '/': (context) => const MyHomePage(title: "PeerDart Demo"),
        '/callExample': (context) => const CallExample(),
        '/dataConnectionExample': (context) => const DataConnectionExample(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void onPressCall() async {
    await Navigator.of(context).pushNamed("/callExample");
  }

  void onPressData() async {
    await Navigator.of(context).pushNamed("/dataConnectionExample");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              ElevatedButton(
                  onPressed: onPressCall,
                  child: const Text("Navigate to call example")),
              ElevatedButton(
                  onPressed: onPressData,
                  child: const Text("Navigate to data example"))
            ],
          ),
        ));
  }
}
