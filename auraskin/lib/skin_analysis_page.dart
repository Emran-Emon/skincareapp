import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'product_recommendations_page.dart';

class SkinAnalysisPage extends StatefulWidget {
  @override
  _SkinAnalysisPageState createState() => _SkinAnalysisPageState();
}

class _SkinAnalysisPageState extends State<SkinAnalysisPage> {
  late List<CameraDescription> _allCameras;
  List<CameraDescription> _rearCameras = [];
  CameraDescription? _frontCamera;
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String? _analysisResult;
  List<dynamic>? _productRecommendations;

  bool _isFrontCamera = false;
  int _selectedRearCameraIndex = 0;

  final String flaskApiUrl = "https://firstly-popular-bunny.ngrok-free.app/analysis/analyze_skin";

  @override
  void initState() {
    super.initState();
    _setupCameras();
  }

  Future<void> _setupCameras() async {
    _allCameras = await availableCameras();

    _rearCameras = _allCameras
        .where((cam) => cam.lensDirection == CameraLensDirection.back)
        .toList();
    _frontCamera = _allCameras
        .firstWhere((cam) => cam.lensDirection == CameraLensDirection.front, orElse: () => _allCameras.first);

    _startCamera(_rearCameras[_selectedRearCameraIndex]);
  }

  void _startCamera(CameraDescription cameraDescription) async {
    _controller = CameraController(cameraDescription, ResolutionPreset.high, enableAudio: false);
    _initializeControllerFuture = _controller.initialize();

    await _initializeControllerFuture;
    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  Future<void> _switchToFrontCamera() async {
    setState(() {
      _isCameraInitialized = false;
      _isFrontCamera = true;
    });
    _startCamera(_frontCamera!);
  }

  Future<void> _switchToRearCamera(int index) async {
    setState(() {
      _isCameraInitialized = false;
      _isFrontCamera = false;
      _selectedRearCameraIndex = index;
    });
    _startCamera(_rearCameras[index]);
  }

  Future<void> _analyzeFace() async {
    if (!_isCameraInitialized || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _analysisResult = null;
      _productRecommendations = null;
    });

    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      final File imageFile = File(image.path);

      var request = http.MultipartRequest('POST', Uri.parse(flaskApiUrl));
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      var response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final Map<String, dynamic> jsonResponse = jsonDecode(responseBody);

        if (jsonResponse['face_detected'] == true) {
          final analysis = jsonResponse['analysis'];
          final recommendations = jsonResponse['recommended_products'];

          setState(() {
            _analysisResult = (analysis is List)
                ? analysis.join(', ')
                : analysis?.toString() ?? 'No analysis';
            _productRecommendations = List<dynamic>.from(recommendations ?? []);
            _isProcessing = false;
          });

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Skin Analysis Result"),
              content: Text("You have $_analysisResult"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductRecommendationsPage(
                          products: _productRecommendations!,
                          modelOutput: Map<String, dynamic>.from(jsonResponse['analysis']),
                        ),
                      ),
                    );
                  },
                  child: const Text("See recommended products to overcome your skin problem"),
                ),
              ],
            ),
          );
        } else {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No face detected')),
          );
        }
      } else {
        throw Exception("Error: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Error capturing or sending image: $e");
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error processing image")),
      );
    }
  }

  Widget _buildLensButtons() {
    if (_isFrontCamera) return SizedBox();

    return Positioned(
      bottom: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLensButton('0.5x', 2),
          SizedBox(width: 5),
          _buildLensButton('1x', 0),
          SizedBox(width: 5),
          _buildLensButton('3x', 1),
        ],
      ),
    );
  }

  Widget _buildLensButton(String label, int index) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedRearCameraIndex == index ? Colors.white : Colors.black54,
        foregroundColor: _selectedRearCameraIndex == index ? Colors.black : Colors.white,
        shape: CircleBorder(),
        padding: EdgeInsets.all(15),
      ),
      onPressed: () {
        _switchToRearCamera(index);
      },
      child: Text(label),
    );
  }

  Widget _buildFlipButton() {
    return Positioned(
      bottom: 50,
      right: 30,
      child: GestureDetector(
        onTap: () {
          if (_isFrontCamera) {
            _switchToRearCamera(0);
          } else {
            _switchToFrontCamera();
          }
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2)),
            ],
          ),
          child: Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
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
              child: Center(child: CircularProgressIndicator()),
            ),
          Positioned(
            bottom: 40,
            child: GestureDetector(
              onTap: _analyzeFace,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  color: Colors.white.withOpacity(0.2),
                ),
                child: Center(
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _buildFlipButton(),
          _buildLensButtons(),
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