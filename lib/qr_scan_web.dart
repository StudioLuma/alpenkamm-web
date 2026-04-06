import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:zxing2/qrcode.dart';
import 'package:zxing2/zxing2.dart';
import 'dart:typed_data';

// Web-spezifisch
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui;
import 'dart:html' as html;
import 'dart:js' as js;

// ------------------------------------------------------------
// Web erkennen
// ------------------------------------------------------------
bool _isWeb() => identical(0, 0.0);

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

  // Web-Variablen
  html.VideoElement? _videoElement;
  html.CanvasElement? _canvas;
  html.CanvasRenderingContext2D? _ctx;
  bool _webInitialized = false;

  @override
  void initState() {
    super.initState();

    if (_isWeb()) {
      _initWebCamera();
    } else {
      _initCamera();
    }
  }

  // ------------------------------------------------------------
  // WEB: Kamera + Canvas + jsQR
  // ------------------------------------------------------------
  Future<void> _initWebCamera() async {
    try {
      _videoElement = html.VideoElement();
      _videoElement!.setAttribute('playsinline', 'true');
      _videoElement!.style.width = '100%';

      final stream = await html.window.navigator.mediaDevices!
          .getUserMedia({'video': {'facingMode': 'environment'}});

      _videoElement!.srcObject = stream;
      await _videoElement!.play();

      // Canvas vorbereiten
      _canvas = html.CanvasElement();
      _ctx = _canvas!.context2D;

      // HTML-Element für Flutter registrieren
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
        'webcamVideo',
        (int viewId) => _videoElement!,
      );

      setState(() {
        _webInitialized = true;
      });

      _scanLoopWeb();
    } catch (e) {
      debugPrint("Web camera error: $e");
    }
  }

  void _scanLoopWeb() {
    html.window.requestAnimationFrame((_) {
      if (!_webInitialized || _videoElement == null) return;

      final video = _videoElement!;
      if (video.videoWidth == 0 || video.videoHeight == 0) {
        _scanLoopWeb();
        return;
      }

      _canvas!.width = video.videoWidth;
      _canvas!.height = video.videoHeight;

      _ctx!.drawImage(video, 0, 0);

      final imageData = _ctx!.getImageData(
        0,
        0,
        _canvas!.width!,
        _canvas!.height!,
      );

      final qr = js.context.callMethod("jsQR", [
        imageData.data,
        _canvas!.width,
        _canvas!.height
      ]);

      if (qr != null) {
        final text = qr["data"];
        Navigator.pop(context, text);
        return;
      }

      _scanLoopWeb();
    });
  }

  // ------------------------------------------------------------
  // MOBILE: zxing2 (unverändert)
  // ------------------------------------------------------------
  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

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
        child: _isWeb()
            ? (_webInitialized
                ? HtmlElementView(viewType: 'webcamVideo')
                : const CircularProgressIndicator(color: Colors.white))
            : (_isInitialized
                ? CameraPreview(_controller!)
                : const CircularProgressIndicator(color: Colors.white)),
      ),
    );
  }
}