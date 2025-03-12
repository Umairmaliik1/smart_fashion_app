import 'dart:io';
import 'dart:math';
import 'dart:ui'; // For Color
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;  // Using version 3.0.2 ideally

class FaceAnalysisScreen extends StatefulWidget {
  const FaceAnalysisScreen({super.key});

  @override
  State<FaceAnalysisScreen> createState() => _FaceAnalysisScreenState();
}

class _FaceAnalysisScreenState extends State<FaceAnalysisScreen> {
  File? _image;
  String? _recommendation;
  bool _isProcessing = false;

  final ImagePicker _picker = ImagePicker();
  final FaceDetector _faceDetector = GoogleMlKit.vision.faceDetector(
    FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
    ),
  );

  // Function to select an image from the gallery.
  Future<void> _getImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _recommendation = null; // Reset previous recommendation.
        debugPrint("New image selected: ${pickedFile.path}");
      });
    }
  }

  // Function to analyze the face and determine skin tone from the cheeks.
  Future<void> _analyzeFace() async {
    debugPrint("Starting face analysis...");
    if (_image == null) return;
    setState(() {
      _isProcessing = true;
      _recommendation = null;
    });

    final inputImage = InputImage.fromFile(_image!);
    final List<Face> faces = await _faceDetector.processImage(inputImage);

    String recommendation;
    if (faces.isNotEmpty) {
      // Use the first detected face.
      final face = faces.first;
      final bytes = await _image!.readAsBytes();
      final originalImage = img.decodeImage(bytes);
      if (originalImage != null) {
        // Use the face bounding box.
        final rect = face.boundingBox;
        int x = rect.left.toInt().clamp(0, originalImage.width - 1);
        int y = rect.top.toInt().clamp(0, originalImage.height - 1);
        int width = rect.width.toInt().clamp(1, originalImage.width - x);
        int height = rect.height.toInt().clamp(1, originalImage.height - y);

        // Approximate the cheek region.
        // For instance, crop a region from the lower middle of the face:
        int cheekX = (x + width * 0.25).toInt();
        int cheekY = (y + height * 0.6).toInt();
        int cheekWidth = (width * 0.5).toInt();
        int cheekHeight = (height * 0.3).toInt();

        // Ensure the cheek region is within the image bounds.
        cheekX = cheekX.clamp(0, originalImage.width - 1);
        cheekY = cheekY.clamp(0, originalImage.height - 1);
        cheekWidth = cheekWidth.clamp(1, originalImage.width - cheekX);
        cheekHeight = cheekHeight.clamp(1, originalImage.height - cheekY);

        final croppedCheeks = img.copyCrop(
          originalImage,
          x: cheekX,
          y: cheekY,
          width: cheekWidth,
          height: cheekHeight,
        );

        // Calculate average color from the cropped cheek region.
        int rTotal = 0, gTotal = 0, bTotal = 0;
        for (int i = 0; i < croppedCheeks.width; i++) {
          for (int j = 0; j < croppedCheeks.height; j++) {
            final pixel = croppedCheeks.getPixel(i, j); // pixel is of type Pixel
            rTotal += pixel.r.toInt();
            gTotal += pixel.g.toInt();
            bTotal += pixel.b.toInt();
          }
        }
        int count = croppedCheeks.width * croppedCheeks.height;
        int avgR = rTotal ~/ count;
        int avgG = gTotal ~/ count;
        int avgB = bTotal ~/ count;

        final avgColor = Color.fromARGB(255, avgR, avgG, avgB);

        // Compute luminance using the Rec. 709 formula:
        double luminance = (0.2126 * avgR + 0.7152 * avgG + 0.0722 * avgB) / 255.0;
        debugPrint("Computed luminance from cheeks: ${luminance.toStringAsFixed(2)}");

        // Determine skin tone based on luminance.
        String skinTone;
        if (luminance <= 0.45) {
          skinTone = "Dark";
        } else if (luminance < 0.6) {
          skinTone = "Brown";
        } else {
          skinTone = "Light";
        }

        recommendation = "Our analysis indicates your skin tone is $skinTone. " +
            (skinTone == "Dark"
                ? "Bright and bold colors will provide excellent contrast. The combination mentioned is for top and bottoms."
                : skinTone == "Brown"
                ? "A balanced mix of warm and cool colors may suit you well.  The combination mentioned is for top and bottoms."
                : "Soft, subtle colors can enhance your natural look.  The combination mentioned is for top and bottoms.");
      } else {
        recommendation = "Face detected, but the image could not be processed properly.";
      }
    } else {
      recommendation = "No face detected. Please try another image.";
    }

    setState(() {
      _recommendation = recommendation;
      _isProcessing = false;
    });
    debugPrint("Analysis complete: $_recommendation");
  }

  @override
  void dispose() {
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Face Analysis"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                "Analyze Your Face for Skin Tone \n For better predictions upload ",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _image != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.file(
                  _image!,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
                  : Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.image,
                  size: 100,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _getImage,
                icon: const Icon(Icons.photo_library),
                label: const Text("Select Image"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _analyzeFace,
                icon: const Icon(Icons.search),
                label: _isProcessing
                    ? const Text("Analyzing...")
                    : const Text("Analyze Face"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 30),
              if (_recommendation != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    _recommendation!,
                    style:
                    const TextStyle(fontSize: 18, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
