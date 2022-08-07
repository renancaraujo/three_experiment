import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gl/flutter_gl.dart';

import 'package:three_dart/three_dart.dart' as three;

typedef CameraInitializer = three.Camera Function(Size availableSize);
typedef StageWidgetBuilder = Widget Function(
  BuildContext buildContext,
  StageContext stageContext,
);

class Stage extends StatefulWidget {
  const Stage.builder({
    Key? key,
    required this.cameraInitializer,
    required this.stageBuilder,
  }) : super(key: key);

  final CameraInitializer cameraInitializer;
  final StageWidgetBuilder stageBuilder;

  @override
  State<Stage> createState() => _StageState();
}

class _StageState extends State<Stage> {
  Size? availableSize;
  late double pixelRatio;

  // flags
  bool initStarted = false;
  bool renderLock = false;

  // three stuff
  late FlutterGlPlugin flutterGlPlugin;
  three.WebGLRenderer? renderer;
  late int sourceTexture;
  late three.Camera camera;
  late three.Scene scene;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.of(context);
    pixelRatio = mediaQuery.devicePixelRatio;
  }

  @override
  void dispose() {
    flutterGlPlugin.dispose();
    super.dispose();
  }

  void digestSize(Size newSize) {
    final availableSize = this.availableSize;
    if (newSize == availableSize) {
      return;
    }
    this.availableSize = newSize;
    tryInitGl();
  }

  Future<void> tryInitGl() async {
    final availableSize = this.availableSize!;
    if (initStarted) {
      return;
    }
    initStarted = true;
    flutterGlPlugin = FlutterGlPlugin();
    scene = three.Scene();
    camera = widget.cameraInitializer(availableSize);

    await flutterGlPlugin.initialize(options: {
      "antialias": true,
      "alpha": true,
      "width": availableSize.width.toInt(),
      "height": availableSize.height.toInt(),
      "dpr": pixelRatio,
    });

    await flutterGlPlugin.prepareContext();

    // init renderer
    final renderer = this.renderer = three.WebGLRenderer({
      "width": availableSize.width,
      "height": availableSize.height,
      "gl": flutterGlPlugin.gl,
      "antialias": true,
      "canvas": flutterGlPlugin.element,
      "alpha": true,
    });
    renderer.setPixelRatio(pixelRatio);
    renderer.setSize(availableSize.width, availableSize.height);
    renderer.shadowMap.enabled = true;
    renderer.background.alpha = true;

    setState(() {});

    // init props
    final pars = three.WebGLRenderTargetOptions({"format": three.RGBAFormat});
    final renderTarget = three.WebGLMultisampleRenderTarget(
      (availableSize.width * pixelRatio).toInt(),
      (availableSize.height * pixelRatio).toInt(),
      pars,
    );

    renderTarget.samples = 4;
    renderer.setRenderTarget(renderTarget);
    sourceTexture = renderer.getRenderTargetGLTexture(renderTarget);
  }

  void render() {
    if (renderLock) return;

    renderLock = true;

    final gl = flutterGlPlugin.gl;
    int t = DateTime.now().millisecondsSinceEpoch;
    renderer!.clear();
    renderer!.render(scene, camera);
    int dt = DateTime.now().millisecondsSinceEpoch - t;

    if (kDebugMode) {
      print("render cost: $dt ");
    }

    gl.finish();

    flutterGlPlugin.updateTexture(sourceTexture);

    Future.delayed(const Duration(milliseconds: 20), () {
      renderLock = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (buildContext, constraints) {
        digestSize(constraints.biggest);
        final availableSize = this.availableSize;
        if (!flutterGlPlugin.isInitialized ||
            availableSize == null ||
            renderer == null) {
          return const SizedBox.shrink();
        }

        final stageContext = StageContext(
          requestRender: render,
          scene: scene,
          camera: camera,
          availableSize: availableSize,
          pixelRatio: pixelRatio,
          textureId: flutterGlPlugin.textureId!,
          renderer: renderer!,
        );
        return widget.stageBuilder(buildContext, stageContext);
      },
    );
  }
}

@immutable
class StageContext {
  final VoidCallback requestRender;
  final three.Camera camera;
  final three.Scene scene;
  final double pixelRatio;
  final Size availableSize;
  final int textureId;
  final three.WebGLRenderer renderer;

  const StageContext({
    required this.requestRender,
    required this.camera,
    required this.scene,
    required this.pixelRatio,
    required this.availableSize,
    required this.textureId,
    required this.renderer,
  });
}
