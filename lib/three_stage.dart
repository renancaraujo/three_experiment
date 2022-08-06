import 'package:flutter/material.dart';

class ThreeStage extends StatelessWidget {
  const ThreeStage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Color(0xFF00FF00),
      child: SizedBox.expand(),
    );
  }
}
