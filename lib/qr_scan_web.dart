import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:zxing2/qrcode.dart';
import 'package:zxing2/zxing2.dart';
import 'dart:typed_data';

class QRScanWebPage extends StatefulWidget {
  final String username;
  final String salonName;

  const QRScanWebPage({
    super.key,
    required this.username,
    required this.salonName,
  });

  @override
  State<QRScanWebPage> createState() => _QRScanWebPageState();
}

class _QRScanWebPageState extends State<QRScanWebPage> {
  CameraController? _controller;
  bool _isScanning = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.first;

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();

      setState(() {
        _isInitialized = true;
      });

      _startScanning();
    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  void _startScanning() {
    if (_controller == null) return;

    _controller!.startImageStream((CameraImage image) {
      if (_isScanning) return;
      _isScanning = true;

      _decodeImage(image).then((result) {
        if (result != null) {
          Navigator.pop(context, result);
        } else {
          _isScanning = false;
        }
      });
    });
  }

  Future<String?> _decodeImage(CameraImage image) async {
    try {
      // Convert YUV → grayscale
      final width = image.width;
      final height = image.height;
      final buffer = image.planes[0].bytes;

      final luminance = Uint8List(width * height);
      for (int i = 0; i < luminance.length; i++) {
        luminance[i] = buffer[i];
      }

      final source = RGBLuminanceSource(
  width,
  height,
  Int32List.fromList(luminance.map((e) => e.toInt()).toList()),
);


      final bitmap = BinaryBitmap(HybridBinarizer(source));
      final reader = QRCodeReader();

      final result = reader.decode(bitmap);
      return result.text;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("QR-Code scannen"),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: _isInitialized
            ? CameraPreview(_controller!)
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}