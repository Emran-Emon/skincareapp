import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class SkinAnalysisPage extends StatefulWidget {
  @override
  _SkinAnalysisPageState createState() => _SkinAnalysisPageState();
}

class _SkinAnalysisPageState extends State<SkinAnalysisPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late FaceDetector _faceDetector;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _faceDetector = GoogleMlKit.vision.faceDetector();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    _controller = CameraController(firstCamera, ResolutionPreset.high);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Skin Analysis')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera),
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final image = await _controller.takePicture();
            final inputImage = InputImage.fromFilePath(image.path);
            final faces = await _faceDetector.processImage(inputImage);
            if (faces.isNotEmpty) {
              // Perform skin analysis here
              print('Face detected, analyzing skin...');
            }
          } catch (e) {
            print(e);
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _faceDetector.close();
    super.dispose();
  }
}
