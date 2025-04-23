// lib/models/flower.dart
import 'package:flutter/material.dart';

class Flower {
  final String name;
  final String latinName;
  final String image;
  final String description;
  final List<String> facts;
  final String habitat;
  final List<String> benefits;

  Flower({
    required this.name,
    this.latinName = '',
    required this.image,
    required this.description,
    required this.facts,
    this.habitat = '',
    this.benefits = const [],
  });

  static List<Flower> getAllFlowers() {
    return [
      Flower(
        name: 'Dandelion',
        latinName: 'Taraxacum officinale',
        image: 'assets/flowers/dandelion.png',
        description: 'Tanaman herba yang memiliki bunga kuning kecil dengan biji yang mudah terbang.',
        facts: ['Bisa dimakan', 'Memiliki khasiat obat', 'Bijinya menyebar dengan angin'],
        habitat: 'Padang rumput, taman, dan area terbuka',
        benefits: ['Digunakan sebagai obat tradisional', 'Daun muda bisa dibuat salad', 'Teh dari akar dandelion'],
      ),
      Flower(
        name: 'Iris',
        latinName: 'Iris germanica',
        image: 'assets/flowers/iris.png',
        description: 'Bunga dengan kelopak yang indah, seringkali berwarna ungu, biru, atau kuning.',
        facts: ['Lambang kerajaan Prancis', 'Memiliki 300 spesies', 'Berasal dari nama dewi Yunani'],
        habitat: 'Daerah beriklim sedang',
        benefits: ['Digunakan dalam parfum', 'Tanaman hias populer', 'Beberapa bagian digunakan dalam pengobatan'],
      ),
      Flower(
        name: 'Rose',
        latinName: 'Rosa sp.',
        image: 'assets/flowers/rose.png',
        description: 'Bunga yang terkenal dengan keindahan dan aromanya yang wangi.',
        facts: ['Simbol cinta', 'Memiliki duri untuk perlindungan', 'Lebih dari 100 spesies'],
        habitat: 'Tumbuh di berbagai iklim',
        benefits: ['Minyak esensial', 'Air mawar untuk kosmetik', 'Kelopak bunga bisa dimakan'],
      ),
      Flower(
        name: 'Sunflower',
        latinName: 'Helianthus annuus',
        image: 'assets/flowers/sunflower.png',
        description: 'Bunga besar dengan kelopak kuning cerah yang mengikuti arah matahari.',
        facts: ['Mengikuti gerakan matahari', 'Bijinya bisa dimakan', 'Tanaman asli Amerika'],
        habitat: 'Daerah dengan banyak sinar matahari',
        benefits: ['Minyak biji bunga matahari', 'Biji kaya nutrisi', 'Tanaman hias'],
      ),
      Flower(
        name: 'Carnation',
        latinName: 'Dianthus caryophyllus',
        image: 'assets/flowers/carnation.png', 
        description: 'Bunga dengan kelopak bergerigi yang tersedia dalam berbagai warna.',
        facts: ['Simbol kasih sayang', 'Tahan lama sebagai bunga potong', 'Berasal dari kawasan Mediterania'],
        habitat: 'Kawasan Mediterania dan Asia',
        benefits: ['Digunakan dalam rangkaian bunga', 'Minyak esensial', 'Beberapa varian bisa dimakan'],
      ),
      Flower(
        name: 'Water Lily',
        latinName: 'Nymphaea sp.',
        image: 'assets/flowers/lily.png',
        description: 'Bunga akuatik dengan daun yang mengapung di permukaan air.',
        facts: ['Tumbuh di air', 'Bunga mekar di pagi hari', 'Simbol kemurnian dalam beberapa budaya'],
        habitat: 'Kolam, danau, dan perairan tenang',
        benefits: ['Menjaga ekosistem air', 'Tanaman hias akuatik', 'Bunga dekoratif'],
      ),
    ];
  }
  
  static List<Map<String, dynamic>> getUsageGuides() {
    return [
      {
        'title': 'Deteksi Real-time',
        'icon': Icons.videocam,
        'steps': [
          'Tekan tombol "Real-time Detection"',
          'Arahkan kamera ke bunga',
          'Tunggu beberapa detik untuk hasil',
          'Hasil dengan akurasi tinggi akan ditampilkan'
        ]
      },
      {
        'title': 'Deteksi dari Galeri',
        'icon': Icons.photo_library,
        'steps': [
          'Tekan tombol "Pick From Gallery"',
          'Pilih foto bunga dari galeri',
          'Sistem akan menganalisis gambar',
          'Hasil deteksi akan ditampilkan'
        ]
      },
      {
        'title': 'Tips Deteksi Akurat',
        'icon': Icons.lightbulb_outline,
        'steps': [
          'Pastikan pencahayaan cukup',
          'Fokuskan pada bunga (bukan daun/batang)',
          'Hindari latar belakang yang rumit',
          'Bunga harus terlihat jelas dalam frame'
        ]
      }
    ];
  }

  static Flower? findByName(String name) {
    try {
      return getAllFlowers().firstWhere(
        (flower) => flower.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
}