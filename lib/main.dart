import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:three_tryout/three_stage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lets try some 3d stuff',
      home: Builder(builder: (context) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        return const Scaffold(
          body: ThreeStage(),
        );
      }),
    );
  }
}
