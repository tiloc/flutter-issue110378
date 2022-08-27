import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:issue110378/capture_sign_board.dart';

List<CameraDescription> cameras = <CameraDescription>[];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize
  cameras = await availableCameras();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CaptureSignBoard(cameras: cameras),
    );
  }
}
