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
    return const MaterialApp(
      title: 'Lets try some 3d stuff',
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  double rotationX = 0;

  void handleVerticalDrag(DragUpdateDetails details) {
    setState(() {
      rotationX += details.delta.dy / 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    return GestureDetector(
      onVerticalDragUpdate: handleVerticalDrag,
      child: Scaffold(
        body: Controller3d(
          accentColor: Colors.orange,
          secondaryColor: const Color(0xFFE36A00),
          rotationX: rotationX,
        ),
      ),
    );
  }
}
