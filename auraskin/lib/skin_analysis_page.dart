import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;

class SkinAnalysisPage extends StatefulWidget {
  @override
  _SkinAnalysisPageState createState() => _SkinAnalysisPageState();
}

class _SkinAnalysisPageState extends State<SkinAnalysisPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String? _analysisResult;

  final String flaskApiUrl = "https://firstly-popular-bunny.ngrok-free.app/analyze_skin"; // Updated with Ngrok URL

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        print("No cameras available");
        return;
      }

      _controller = CameraController(cameras.first, ResolutionPreset.high, enableAudio: false);
      _initializeControllerFuture = _controller.initialize();
      await _initializeControllerFuture;

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  Future<void> _analyzeFace() async {
    if (!_isCameraInitialized || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _analysisResult = null;
    });

    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      final File imageFile = File(image.path);
      final response = await _sendImageToFlask(imageFile);

      setState(() {
        _analysisResult = response;
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Analysis complete!")),
      );
    } catch (e) {
      print("Error capturing or sending image: $e");
      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error processing image")),
      );
    }
  }

  Future<String> _sendImageToFlask(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(flaskApiUrl));
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        return await response.stream.bytesToString();
      } else {
        print("Error: ${response.reasonPhrase}");
        return "Error: ${response.reasonPhrase}";
      }
    } catch (e) {
      print("Failed to connect to Flask: $e");
      return "Failed to connect to server";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Skin Analysis')),
      body: _isCameraInitialized
          ? Stack(
        alignment: Alignment.center,
        children: [
          CameraPreview(_controller),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          Positioned(
            bottom: 50,
            child: FloatingActionButton(
              child: Icon(Icons.camera),
              onPressed: _analyzeFace,
            ),
          ),
          if (_analysisResult != null)
            Positioned(
              top: 80,
              child: Container(
                padding: EdgeInsets.all(10),
                color: Colors.white,
                child: Text(
                  _analysisResult!,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      )
          : Center(child: CircularProgressIndicator()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}