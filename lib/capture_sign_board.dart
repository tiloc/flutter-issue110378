import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Capture a sign board
class CaptureSignBoard extends StatefulWidget {
  final List<CameraDescription> _cameras;

  /// Default Constructor
  const CaptureSignBoard({super.key, required List<CameraDescription> cameras})
      : _cameras = cameras;

  @override
  State<CaptureSignBoard> createState() {
    return _CaptureSignBoardState();
  }
}

class _CaptureSignBoardState extends State<CaptureSignBoard>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _controller;
  Future<void>? _ensureControllerFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _ensureControllerFuture = _ensureCameraController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCameraController().ignore();
    super.dispose();
  }

  CameraDescription _findFirstBackCamera() {
    // Find the first back camera.
    final cameraDescription = widget._cameras.firstWhere((currDescription) =>
        currDescription.lensDirection == CameraLensDirection.back);

    return cameraDescription;
  }

  bool get isCameraControllerNotInitialized {
    return !isCameraControllerInitialized;
  }

  bool get isCameraControllerInitialized {
    final CameraController? cameraController = _controller;
    return !(cameraController == null || !cameraController.value.isInitialized);
  }

  Future<void> _disposeCameraController() async {
    final CameraController? oldController = _controller;
    if (oldController != null) {
      // `_controller` needs to be set to null before getting disposed,
      // to avoid a race condition when we use the controller that is being
      // disposed. This happens when camera permission dialog shows up,
      // which triggers `didChangeAppLifecycleState`, which disposes and
      // re-creates the controller.
      _controller = null;
      _ensureControllerFuture = null;

      if (!oldController.value.isInitialized) {
        // Controllers which have not finished initialization cannot be disposed.
        // TODO: Would there be any benefit in waiting for it to initialize and then dispose?
        return;
      }

      await oldController.dispose();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _disposeCameraController().ignore();
    } else if (state == AppLifecycleState.resumed) {
      // Resuming should fully recreate the camera controller
      _ensureControllerFuture =
          _disposeCameraController().then((_) => _ensureCameraController());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: Center(
                  child: _cameraPreviewWidget(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _waitForCameraWidget() {
    return Align(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(),
          Text(
            'Warming up the Camera',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.0,
              fontWeight: FontWeight.w900,
            ),
          )
        ],
      ),
    );
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    final CameraController? cameraController = _controller;

    if (cameraController == null || _ensureControllerFuture == null) {
      return _waitForCameraWidget();
    } else {
      return FutureBuilder<void>(
        future: _ensureControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(
              _controller!,
              child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                );
              }),
            );
          } else {
            // Otherwise, display a loading indicator.
            return _waitForCameraWidget();
          }
        },
      );
    }
  }


  void showInSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _ensureCameraController() async {
    if (isCameraControllerInitialized) {
      return;
    }

    final CameraController cameraController = CameraController(
      _findFirstBackCamera(),
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    // If the controller is updated then update the UI.
    cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (cameraController.value.hasError) {
        showInSnackBar(
            'Camera error ${cameraController.value.errorDescription}');
      }
    });

    try {
      await cameraController.initialize();
    } on CameraException catch (e) {
      print(e);
    }

    _controller = cameraController;

    if (mounted) {
      setState(() {});
    }
  }
}
