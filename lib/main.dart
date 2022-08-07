import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'controller.dart';

import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lets try some 3d stuff',
      home: Home(),
    );
  }
}

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: ScrollsRoll(),
      ),
    );
  }
}

class ScrollsRoll extends StatelessWidget {
  const ScrollsRoll({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, boxConstraints) {
      return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverLayoutBuilder(builder: (context, sliverConstraints) {
            final height = boxConstraints.biggest.height;
            final sOffset = sliverConstraints.scrollOffset;
            final cleber = sOffset / (height / 2);
            final spread = cleber * (pi * 0.5);
            return SliverToBoxAdapter(
              child: SizedBox(
                height: height,
                child: GyroRoll(
                  rotationX: ((-pi * 0.2) + spread),
                ),
              ),
            );
          }),
          const SliverToBoxAdapter(
            child: WTFIsThis(),
          )
        ],
      );
    });
  }
}

class GyroRoll extends StatefulWidget {
  const GyroRoll({
    Key? key,
    required this.rotationX,
  }) : super(key: key);

  final double rotationX;

  @override
  State<GyroRoll> createState() => _GyroRollState();
}

class _GyroRollState extends State<GyroRoll> {
  StreamSubscription<GyroscopeEvent>? subscription;

  @override
  void initState() {
    super.initState();

    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      subscription = gyroscopeEvents.listen(handleGyro);
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  double rotationX = pi * 0.1;
  double rotationY = 0.0;
  bool renderLock = false;

  @override
  void didUpdateWidget(covariant GyroRoll oldWidget) {
    super.didUpdateWidget(oldWidget);
    final deltaX = widget.rotationX - oldWidget.rotationX;

    if (deltaX.abs() > (pi * 0.001)) {
      setState(() {
        rotationX = widget.rotationX;
      });
      renderLock = true;
      Future.delayed(const Duration(milliseconds: 1000), () {
        renderLock = false;
      });
    }
  }

  void handleGyro(GyroscopeEvent event) {
    if (renderLock) return;
    renderLock = true;

    setState(() {
      rotationX += (event.x * 100).toInt() / 500;
      rotationY += (event.y * 100).toInt() / 500;
    });

    Future.delayed(const Duration(milliseconds: 60), () {
      renderLock = false;
    });
  }

  void handlePan(DragUpdateDetails details) {
    final deltaX = details.delta.dx;
    final deltaY = details.delta.dy;

    setState(() {
      rotationX += deltaY / 100;
      rotationY += deltaX / 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: handlePan,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 150),
        tween: Tween<double>(begin: 0.0, end: rotationX),
        builder: (context, valueX, _) => TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 150),
          tween: Tween<double>(begin: 0.0, end: rotationY),
          builder: (context, valueY, _) => Controller3d(
            accentColor: Colors.orange,
            secondaryColor: const Color(0xFFE36A00),
            rotationX: valueX,
            rotationY: valueY,
          ),
        ),
      ),
    );
  }
}

class WTFIsThis extends StatelessWidget {
  const WTFIsThis({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: GoogleFonts.kanit(),
      textAlign: TextAlign.center,
      child: ColoredBox(
        color: const Color(0xFFE36A00),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
          child: Column(
            children: const [
              Text(
                "What the hell is this?",
                style: TextStyle(
                  fontSize: 32.0,
                  fontWeight: FontWeight.w900,
                  height: 1.4,
                ),
              ),
              SizedBox(
                height: 30,
              ),
              Text(
                "This is a Experiment of getting 3D elements to work on Flutter. "
                "Powered by three_dart and flutter_gl, this is in experimental phase.",
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w300,
                  height: 1.2,
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                "NES Controller Free by donnichols "
                    "(https://sketchfab.com/donnichols) is licensed under "
                    "Creative Commons Attribution.",
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w300,
                  height: 1.2,
                ),
              ),
              SizedBox(
                height: 100,
              )
            ],
          ),
        ),
      ),
    );
  }
}
