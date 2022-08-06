import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';

import 'package:three_dart/three_dart.dart' as three;

class ThreeStage extends StatelessWidget {
  const ThreeStage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ThreeRenderer();
  }
}

class ThreeRenderer extends StatefulWidget {
  const ThreeRenderer({Key? key}) : super(key: key);

  @override
  State<ThreeRenderer> createState() => _ThreeRendererState();
}

const kAmount = 4;

class _ThreeRendererState extends State<ThreeRenderer> {
  late Size screenSize;
  late double pixelRatio;

  late FlutterGlPlugin flutterGlPlugin;
  late three.Camera camera;
  late three.Scene scene;
  late three.WebGLRenderer renderer;
  late three.Mesh cilinder;
  late int sourceTexture;

  bool initStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.of(context);
    screenSize = Size(mediaQuery.size.width, mediaQuery.size.height);
    pixelRatio = mediaQuery.devicePixelRatio;
    initGl();
  }

  @override
  void dispose() {
    flutterGlPlugin.dispose();
    super.dispose();
  }

  Future<void> initGl() async {
    if (initStarted) {
      return;
    }
    initStarted = true;
    flutterGlPlugin = FlutterGlPlugin();

    await flutterGlPlugin.initialize(options: {
      "antialias": true,
      "alpha": false,
      "width": screenSize.width.toInt(),
      "height": screenSize.height.toInt(),
      "dpr": pixelRatio,
    });

    setState(() {});

    await flutterGlPlugin.prepareContext();

    // init renderer

    renderer = three.WebGLRenderer({
      "width": screenSize.width,
      "height": screenSize.height,
      "gl": flutterGlPlugin.gl,
      "antialias": true,
      "canvas": flutterGlPlugin.element
    });
    renderer.setPixelRatio(pixelRatio);
    renderer.setSize(screenSize.width, screenSize.height);

    renderer.shadowMap.enabled = true;

    // init props
    final pars = three.WebGLRenderTargetOptions({"format": three.RGBAFormat});
    final renderTarget = three.WebGLRenderTarget(
      (screenSize.width * pixelRatio).toInt(),
      (screenSize.height * pixelRatio).toInt(),
      pars,
    );

    renderTarget.samples = 4;
    renderer.setRenderTarget(renderTarget);
    sourceTexture = renderer.getRenderTargetGLTexture(renderTarget);

    // init scene

    /// camera
    camera = three.PerspectiveCamera(400, screenSize.aspectRatio, 0.1, 10);
    camera.position.z = 1.5;
    camera.position.multiplyScalar(2);
    camera.lookAt(three.Vector3(0, 0, 0));
    camera.updateMatrixWorld(false);
    camera.position.z = 6;

    scene = three.Scene();

    final ambientLight = three.AmbientLight(0xcccccc, 0.4);
    scene.add(ambientLight);
    camera.lookAt(scene.position);

    final light = three.DirectionalLight(0xffffff, null);
    light.position.set(0.5, 0.5, 1);
    light.castShadow = true;
    light.shadow?.camera?.zoom = 4; // tighter shadow map
    scene.add(light);

    final background = three.Mesh(
      three.PlaneGeometry(100, 100),
      three.MeshPhongMaterial({"color": 0x000000}),
    );
    background.receiveShadow = true;
    background.position.set(0, 0, -1);
    scene.add(background);

    cilinder = three.Mesh(
      three.CylinderGeometry(0.5, 0.5, 1, 90),
      three.MeshPhongMaterial({"color": 0xF84DFF}),
    );

    scene.add(cilinder);

    render();
  }

  bool renderLock = false;

  void render() {
    if (renderLock) return;

    renderLock = true;

    final gl = flutterGlPlugin.gl;
    int t = DateTime.now().millisecondsSinceEpoch;
    renderer.render(scene, camera);
    int dt = DateTime.now().millisecondsSinceEpoch - t;

    if (kDebugMode) {
      print("render cost: $dt ");
    }

    gl.finish();

    flutterGlPlugin.updateTexture(sourceTexture);

    Future.delayed(const Duration(milliseconds: 40), () {
      renderLock = false;
    });
  }

  void drag(DragUpdateDetails dragUpdateDetails) {
    final delta = dragUpdateDetails.delta / 100;

    cilinder.rotation.x += delta.dy;

    render();
  }

  void ontap() {
    cilinder.rotation.x += 500;
    render();
  }

  @override
  Widget build(BuildContext context) {
    if (!flutterGlPlugin.isInitialized) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: ontap,
      onVerticalDragUpdate: drag,
      child: Texture(textureId: flutterGlPlugin.textureId!),
    );
  }
}
