import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'dart:developer' as devtools;

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? controller;
  String label = '';
  double confidence = 0.0;
  bool isDetecting = false;
  bool isFrontCamera = false;
  
  // Optimized parameters
  int _frameSkip = 0;
  static const int PROCESS_EVERY_N_FRAMES = 3;  // Proses lebih sering
  final Map<String, List<double>> _predictionHistory = {};
  static const int HISTORY_LENGTH = 4;  // Track lebih banyak history
  static const double MIN_CONFIDENCE = 0.25;
  
  // Stabilitas deteksi
  Map<String, int> _stableDetectionCounter = {};
  static const int STABLE_DETECTION_COUNT = 2;
  Timer? _displayTimer;
  bool _isDisplayUpdating = false;

  @override
  void initState() {
    super.initState();
    _initTflite();
    _initializeCamera();
  }

  Future<void> _initTflite() async {
    try {
      await Tflite.loadModel(
        model: "assets/model_unquant.tflite",
        labels: "assets/labels.txt",
        numThreads: 4,  // Increase threads for better performance
        isAsset: true,
        useGpuDelegate: false
      );
      devtools.log("Model loaded successfully");
    } catch (e) {
      devtools.log("Error loading model: $e");
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      devtools.log("No cameras available");
      return;
    }

    controller = CameraController(
      cameras[isFrontCamera ? 1 : 0],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await controller!.initialize();
      if (!mounted) return;
      
      setState(() {});
      await controller!.setExposureMode(ExposureMode.auto);
      await controller!.setFocusMode(FocusMode.auto);
      await controller!.setExposureOffset(0.0);  // Prevent overexposure
      await controller!.setFlashMode(FlashMode.auto);  // Auto flash in low light
      
      _startImageStream();
    } catch (e) {
      devtools.log("Error initializing camera: $e");
    }
  }

  void _updatePredictionHistory(String detectedLabel, double detectedConfidence) {
    // Add new prediction to history
    if (!_predictionHistory.containsKey(detectedLabel)) {
      _predictionHistory[detectedLabel] = [];
    }
    
    _predictionHistory[detectedLabel]!.add(detectedConfidence);
    
    // Limit history length
    if (_predictionHistory[detectedLabel]!.length > HISTORY_LENGTH) {
      _predictionHistory[detectedLabel]!.removeAt(0);
    }
    
    // Clean inactive labels
    final keysToRemove = <String>[];
    for (final key in _predictionHistory.keys) {
      if (key != detectedLabel) {
        if (_predictionHistory[key]!.length < HISTORY_LENGTH) {
          _predictionHistory[key]!.add(0);
        } else {
          _predictionHistory[key]!.removeAt(0);
          _predictionHistory[key]!.add(0);
        }
        
        // Remove if all confidences are 0
        if (_predictionHistory[key]!.every((element) => element == 0)) {
          keysToRemove.add(key);
        }
      }
    }
    
    for (final key in keysToRemove) {
      _predictionHistory.remove(key);
    }
  }
  
  String _getMostConfidentLabel() {
    String bestLabel = '';
    double bestAverage = 0;
    
    _predictionHistory.forEach((key, values) {
      if (values.isNotEmpty) {
        // Prioritize recent predictions (weighted average)
        double sum = 0;
        double weight = 0;
        for (int i = 0; i < values.length; i++) {
          double multiplier = 1.0 + (i / values.length); // More weight to recent predictions
          sum += values[i] * multiplier;
          weight += multiplier;
        }
        double weightedAvg = sum / weight;
        
        if (weightedAvg > bestAverage && weightedAvg >= MIN_CONFIDENCE * 100) {
          bestAverage = weightedAvg;
          bestLabel = key;
        }
      }
    });
    
    return bestLabel;
  }
  
  double _getAverageConfidence(String labelToCheck) {
    if (!_predictionHistory.containsKey(labelToCheck) || 
        _predictionHistory[labelToCheck]!.isEmpty) {
      return 0.0;
    }
    
    // Weighted average prioritizing recent predictions
    double sum = 0;
    double weight = 0;
    List<double> values = _predictionHistory[labelToCheck]!;
    
    for (int i = 0; i < values.length; i++) {
      double multiplier = 1.0 + (i / values.length);
      sum += values[i] * multiplier;
      weight += multiplier;
    }
    
    return sum / weight;
  }

  void _startImageStream() {
    controller!.startImageStream((CameraImage img) async {
      _frameSkip++;
      if (_frameSkip % PROCESS_EVERY_N_FRAMES != 0) return;
      
      if (!isDetecting) {
        isDetecting = true;
        try {
          var recognitions = await Tflite.runModelOnFrame(
            bytesList: img.planes.map((plane) => plane.bytes).toList(),
            imageHeight: img.height,
            imageWidth: img.width,
            imageMean: 127.5,  // Match Teachable Machine settings
            imageStd: 127.5,   // Match Teachable Machine settings
            rotation: 90,
            numResults: 2,
            threshold: 0.1,    // Lower threshold for better detection
            asynch: true,
          );

          if (recognitions != null && 
              recognitions.isNotEmpty && 
              mounted) {
            
            String currentLabel = recognitions[0]['label'].toString();
            double currentConfidence = recognitions[0]['confidence'] * 100;
            
            // Reset counters for other labels
            _stableDetectionCounter.keys.toList().forEach((key) {
              if (key != currentLabel) {
                _stableDetectionCounter[key] = 0;
              }
            });
            
            // Increment counter for current label if confidence is high enough
            if (recognitions[0]['confidence'] >= MIN_CONFIDENCE) {
              _stableDetectionCounter[currentLabel] = (_stableDetectionCounter[currentLabel] ?? 0) + 1;
              
              // Update prediction history
              _updatePredictionHistory(currentLabel, currentConfidence);
              
              // Only update UI when detection is stable
              if (_stableDetectionCounter[currentLabel]! >= STABLE_DETECTION_COUNT) {
                if (!_isDisplayUpdating) {
                  _isDisplayUpdating = true;
                  _displayTimer?.cancel();
                  
                  _displayTimer = Timer(const Duration(milliseconds: 300), () {
                    String bestLabel = _getMostConfidentLabel();
                    if (bestLabel.isNotEmpty) {
                      double avgConfidence = _getAverageConfidence(bestLabel);
                      setState(() {
                        label = bestLabel;
                        confidence = avgConfidence;
                      });
                    }
                    _isDisplayUpdating = false;
                  });
                }
              }
            }
          }
        } catch (e) {
          devtools.log("Error during detection: $e");
        } finally {
          isDetecting = false;
        }
      }
    });
  }

  Future<void> _switchCamera() async {
    final cameras = await availableCameras();
    if (cameras.length < 2) return;

    setState(() {
      isFrontCamera = !isFrontCamera;
      label = '';
      confidence = 0.0;
      _predictionHistory.clear();
      _stableDetectionCounter.clear();
    });

    await controller?.stopImageStream();
    await controller?.dispose();
    await _initializeCamera();
  }

  @override
  void dispose() {
    _displayTimer?.cancel();
    controller?.stopImageStream();
    controller?.dispose();
    Tflite.close();
    super.dispose();
  }

  Color _getColorForConfidence(double confidenceValue) {
    if (confidenceValue >= 85) return Colors.green;
    if (confidenceValue >= 70) return Colors.lightGreen;
    if (confidenceValue >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          CameraPreview(controller!),
          
          // Guide overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.all(50),
            ),
          ),
          
          // Header with back button and title
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        controller?.stopImageStream();
                        Navigator.pop(context);
                      },
                    ),
                    const Text(
                      'Real-time Detection',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                      onPressed: _switchCamera,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Prediction Result
          if (label.isNotEmpty && confidence > MIN_CONFIDENCE * 100)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.only(bottom: 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getColorForConfidence(confidence),
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _getColorForConfidence(confidence).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.local_florist,
                                color: _getColorForConfidence(confidence),
                                size: 36,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getColorForConfidence(confidence).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${confidence.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        color: _getColorForConfidence(confidence),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: confidence / 100,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getColorForConfidence(confidence),
                            ),
                            minHeight: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}