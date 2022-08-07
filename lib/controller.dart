import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:three_dart/three_dart.dart' as three;
import 'package:three_dart_jsm/three_dart_jsm.dart' as three_jsm;
import 'package:three_experiment/utils/stage.dart';

Matrix4 _pmat(num pv) {
  return Matrix4(
    1.0,
    0.0,
    0.0,
    0.0,
    //
    0.0,
    1.0,
    0.0,
    0.0,
    //
    0.0,
    0.0,
    1.0,
    pv * 0.001,
    //
    0.0,
    0.0,
    0.0,
    1.0,
  );
}

final kPerspective = _pmat(1.0);

class Controller3d extends StatelessWidget {
  const Controller3d({
    Key? key,
    required this.accentColor,
    required this.secondaryColor,
    required this.rotationX,
    required this.rotationY,
  }) : super(key: key);

  final Color accentColor;
  final Color secondaryColor;
  final double rotationX;
  final double rotationY;

  @override
  Widget build(BuildContext context) {
    return Stage.builder(
      cameraInitializer: (availableSize) => three.PerspectiveCamera(
        45,
        availableSize.aspectRatio,
        1,
        1000,
      ),
      stageBuilder: (context, stageContext) {
        return ThreeRenderer(
          stageContext: stageContext,
          accentColor: accentColor,
          secondaryColor: secondaryColor,
          rotationX: rotationX,
          rotationY: rotationY,
        );
      },
    );
  }
}

class ThreeRenderer extends StatefulWidget {
  const ThreeRenderer({
    Key? key,
    required this.stageContext,
    required this.accentColor,
    required this.secondaryColor,
    required this.rotationX,
    required this.rotationY,
  }) : super(key: key);

  final StageContext stageContext;
  final Color accentColor;
  final Color secondaryColor;
  final double rotationX;
  final double rotationY;

  @override
  State<ThreeRenderer> createState() => _ThreeRendererState();
}

class _ThreeRendererState extends State<ThreeRenderer> {
  @override
  void initState() {
    super.initState();
    initScene();
  }

  late final three.Group controller;
  late final three.DirectionalLight accLght;

  Future<void> initScene() async {
    final stageContext = widget.stageContext;

    final camera = stageContext.camera;
    camera.position.z = 350;

    final scene = stageContext.scene;
    camera.lookAt(scene.position);
    scene.add(camera);

    controller = three.Group();

    // light
    var pointLight = three.PointLight(0xFFFFFF, 0.1, 15, 15);
    pointLight.position.set(-0.5, 0.5, 1000);
    pointLight.penumbra = 1500.0;
    pointLight.decay = 100;
    camera.add(pointLight);

    final ambientLight = three.AmbientLight(0xffffff, 3);
    scene.add(ambientLight);

    final l1 = three.DirectionalLight(0xffffff, 4);
    l1.position.set(9.5, 0.5, 4);
    l1.castShadow = true;
    l1.shadow?.camera?.zoom = 4; // tighter shadow map
    // scene.add(l1);
    controller.add(l1);

    final l2 = three.DirectionalLight(0xffffff, 2);
    l2.position.set(-0.5, 0.5, 1);
    l2.castShadow = true;
    l2.shadow?.camera?.zoom = 4; // tighter shadow map

    // scene.add(l2);
    controller.add(l2);

    final accColor = 0x00ffffff & widget.accentColor.value;
    final l3 = three.DirectionalLight(accColor, 0.05);
    l3.position.set(0.0, 20, 10);
    l3.castShadow = true;
    l3.shadow?.camera?.zoom = 1; // tighter shadow map
    l3.penumbra = 15.0;
    l3.decay = 10;
    scene.add(l3);

    // texture mtl
    var manager = three.LoadingManager();

    var mtlLoader = three_jsm.MTLLoader(manager);
    mtlLoader.setPath('assets/nes/');
    var materials = await mtlLoader.loadAsync('untitled.mtl');
    await materials.preload();

    var loader = three_jsm.OBJLoader(null);
    loader.setMaterials(materials);
    final obj =
        await loader.loadAsync('assets/nes/untitled.obj') as three.Group;

    const scale = 750.0;
    obj.scale.set(scale, scale, scale);
    obj.rotation.x = pi * 0.5;
    obj.position.z = 5;
    obj.castShadow = true;
    obj.receiveShadow = true;

    controller.add(obj);
    controller.rotation.x = widget.rotationX;
    controller.rotation.y = widget.rotationY;

    scene.add(controller);

    stageContext.renderer.toneMappingExposure = 5.0;

    stageContext.requestRender();
  }

  double rotationX = 0;
  double rotationY = 0;

  @override
  void didUpdateWidget(ThreeRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);

    bool shouldRequestRender = false;
    if (oldWidget.rotationX != widget.rotationX) {
      final delta = widget.rotationX - oldWidget.rotationX;
      final newRotationX = (controller.rotation.x + delta).clamp(
        -pi * 0.4,
        pi * 0.4,
      );
      setState(() {
        rotationX = controller.rotation.x = newRotationX;
      });
      shouldRequestRender = true;
    }
    if (oldWidget.rotationY != widget.rotationY) {
      final delta = widget.rotationY - oldWidget.rotationY;
      final newRotationY = (controller.rotation.y + delta).clamp(
        -pi * 0.4,
        pi * 0.4,
      );
      setState(() {
        rotationY = controller.rotation.y = newRotationY;
      });
      shouldRequestRender = true;
    }

    if (shouldRequestRender) {
      widget.stageContext.requestRender();
    }
  }

  @override
  Widget build(BuildContext context) {
    Matrix4 perspective = _pmat(1.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.accentColor,
                widget.secondaryColor,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Center(
          child: Image.asset(
            'assets/frocks.png',
          ),
        ),
        Center(
          child: Transform(
            alignment: FractionalOffset.center,
            transform: perspective.scaled(1.0, 1.0, 1.0)
              ..rotateX(rotationX)
              ..rotateY(-rotationY)
              ..rotateZ(0.0),
            child: SizedBox(
              width: 310,
              height: 120,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF000000).withOpacity(0.8),
                      spreadRadius: 5,
                      blurRadius: 60,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Builder(builder: (context) {
          if (kIsWeb) {
            return HtmlElementView(
              viewType: widget.stageContext.textureId.toString(),
            );
          }
          return Texture(
            textureId: widget.stageContext.textureId,
            filterQuality: FilterQuality.medium,
          );
        }),
      ],
    );
  }
}
