// lib/screen/home/home_page.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer' as devtools;

import 'package:my_tflit_app/models/flower.dart';
import 'package:my_tflit_app/screen/camera/camera_page.dart';
import 'package:my_tflit_app/widgets/card_widgets.dart';
import 'package:my_tflit_app/widgets/detection_widgets.dart';
import 'package:my_tflit_app/widgets/flower_widgets.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? filePath;
  String label = '';
  double confidence = 0.0;
  Flower? detectedFlower;

  @override
  void initState() {
    super.initState();
    _tfLteInit();
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  Future<void> _tfLteInit() async {
    await Tflite.loadModel(
      model: "assets/model_unquant.tflite",
      labels: "assets/labels.txt",
      numThreads: 1,
      isAsset: true,
      useGpuDelegate: false
    );
  }

  Future<void> _processImage(File imageFile) async {
    var recognitions = await Tflite.runModelOnImage(
      path: imageFile.path,
      imageMean: 0.0,
      imageStd: 255.0,
      numResults: 2,
      threshold: 0.2,
      asynch: true
    );

    if (recognitions == null) {
      devtools.log("recognitions is Null");
      return;
    }
    
    devtools.log(recognitions.toString());
    setState(() {
      confidence = (recognitions[0]['confidence'] * 100);
      label = recognitions[0]['label'].toString();
      detectedFlower = Flower.findByName(label);
    });
  }

  Future<void> pickImageGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    var imageFile = File(image.path);

    setState(() {
      filePath = imageFile;
    });

    await _processImage(imageFile);
  }

  Future<void> pickImageCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image == null) return;

    var imageFile = File(image.path);

    setState(() {
      filePath = imageFile;
    });

    await _processImage(imageFile);
  }

  void _showAboutDialog() {
  showAboutDialog(
    context: context,
    applicationName: 'Flower Detection App',
    applicationVersion: '1.0.0',
    applicationIcon: const Icon(Icons.local_florist, color: Color(0xFF4CAF50)),
    applicationLegalese: '© 2023 Flower Detection\nMade by Riyan Studio',
    children: [
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Color(0xFF4CAF50)),
            SizedBox(width: 8),
            Text(
              'Made by Riyan Studio',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [

            GradientHeader(
              child: Column(
                children: [
                  GradientAppBar(
                    title: 'Flower Detection',
                    onInfoPressed: _showAboutDialog,
                  ),
                  const SizedBox(height: 16),
                  DetectionCard(
                    imageFile: filePath,
                    label: label,
                    confidence: confidence,
                    onCameraPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CameraPage()),
                    ),
                    onGalleryPressed: pickImageGallery,
                  ),
                ],
              ),
            ),
            

            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Panduan penggunaan
                  const SectionTitle(title: 'Cara Penggunaan'),
                  Column(
                    children: Flower.getUsageGuides().map(
                      (guide) => GuideCard(
                        icon: guide['icon'],
                        title: guide['title'],
                        steps: List<String>.from(guide['steps']),
                      ),
                    ).toList(),
                  ),
                  

                  const SectionTitle(title: 'Bunga yang Dapat Dideteksi'),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 165),
                    child: FlowerGallery(
                      flowers: Flower.getAllFlowers(),
                      onFlowerSelected: (flower) {
                        setState(() {
                          detectedFlower = flower;
                          label = flower.name;
                          confidence = 100;
                        });
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  

                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'Mulai deteksi bunga sekarang!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 10),
                        CallToActionButton(
                          text: "Deteksi Real-time",
                          icon: Icons.camera_alt,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CameraPage()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}