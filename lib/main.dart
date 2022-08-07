import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'controller.dart';

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
  double rotationX = pi * 0.1;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    return Scaffold(
      body: PartThatScrolls(),
    );
  }
}

class PartThatScrolls extends StatelessWidget {
  const PartThatScrolls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, boxConstraints) {
      return CustomScrollView(
        slivers: [
          SliverLayoutBuilder(builder: (context, sliverConstraints) {
            final height = boxConstraints.biggest.height;
            final sOffset = sliverConstraints.scrollOffset;

            final cleber = sOffset / (height / 2);

            final spread = cleber * (pi * 0.6);

            return SliverToBoxAdapter(
              child: SizedBox(
                height: height,
                child: GyroRoll(
                  rotationX:  - ((-pi * 0.2) + spread),
                ),
              ),
            );
          }),
          SliverToBoxAdapter(
            child: Container(
              color: Color(0xFFE36A00),
              height: 400,
              child: Text("Snes"),
            ),
          )
        ],
      );
    });
  }
}

class GyroRoll extends StatelessWidget {
  const GyroRoll({
    Key? key,
    required this.rotationX,
  }) : super(key: key);

  final double rotationX;

  @override
  Widget build(BuildContext context) {
    return Controller3d(
      accentColor: Colors.orange,
      secondaryColor: const Color(0xFFE36A00),
      rotationX: rotationX,
    );
  }
}
