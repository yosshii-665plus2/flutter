import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: WaveformScreen(),
    );
  }
}

class WaveformScreen extends StatefulWidget {
  const WaveformScreen({super.key});

  @override
  State<WaveformScreen> createState() => _WaveformScreenState();
}

class _WaveformScreenState extends State<WaveformScreen> {
  String _fileName = 'ファイルが選択されていません';
  List<double> _samples = []; // 0.0 ～ 1.0 に正規化した振幅データ

  // ファイルを選択して波形データを抽出する処理
  Future<void> _pickAndDrawWaveform() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.single.path != null) {
      String filePath = result.files.single.path!;
      
      // ファイルから直接バイトデータを読み込む
      File file = File(filePath);
      Uint8List bytes = await file.readAsBytes();

      setState(() {
        _fileName = result.files.single.name;
        // バイトデータを波形用に間引く（画面幅に合わせて200個のデータ点にする）
        _samples = _extractSamples(bytes, 200);
      });
    }
  }

  // バイト配列から簡易的に振幅値を取り出す関数
  List<double> _extractSamples(Uint8List bytes, int targetCount) {
    if (bytes.isEmpty) return [];

    List<double> samples = [];
    int step = (bytes.length / targetCount).floor();
    if (step < 1) step = 1;

    for (int i = 0; i < bytes.length && samples.length < targetCount; i += step) {
      // バイト値 (0〜255) を 0.0〜1.0 の高さ情報として正規化
      double amplitude = bytes[i] / 255.0;
      samples.add(amplitude);
    }
    return samples;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DAW 波形表示プロトタイプ')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _pickAndDrawWaveform,
                child: const Text('音声ファイルを選択して波形を描画'),
              ),
              const SizedBox(height: 20),
              Text(_fileName),
              const SizedBox(height: 30),
              
              // 波形を表示する領域
              if (_samples.isNotEmpty)
                Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E), // DAW風のダーク背景
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomPaint(
                    painter: WaveformPainter(_samples),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// 波形を描画するカスタムペインター
class WaveformPainter extends CustomPainter {
  final List<double> samples;

  WaveformPainter(this.samples);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent // 波形の色
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    double widthPerSample = size.width / samples.length;
    double centerY = size.height / 2;

    for (int i = 0; i < samples.length; i++) {
      double x = i * widthPerSample + (widthPerSample / 2);
      // 振幅に応じた高さを計算
      double barHeight = samples[i] * size.height * 0.8;

      // 上下に線を描画して波形を作る
      canvas.drawLine(
        Offset(x, centerY - (barHeight / 2)),
        Offset(x, centerY + (barHeight / 2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}