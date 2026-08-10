import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'ffi/mp3_decoder.dart';
import 'utils/audio_utils.dart';
import 'painters/pcm_waveform_painter.dart';

void main() {
  runApp(const MaterialApp(home: AudioApp()));
}

class AudioApp extends StatefulWidget {
  const AudioApp({super.key});

  @override
  State<AudioApp> createState() => _AudioAppState();
}

class _AudioAppState extends State<AudioApp> {
  final Mp3Decoder _decoder = Mp3Decoder();
  List<double> _peaks = [];
  String _fileName = 'ファイル未選択';

  Future<void> _pickAndProcess() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      
      // 1. C++経由でPCMデータを取得
      final pcmData = _decoder.decode(path);
      
      if (pcmData != null) {
        // 2. ピーク値を抽出（200本分）
        final peaks = extractPeaks(pcmData, 200);

        setState(() {
          _fileName = result.files.single.name;
          _peaks = peaks;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _pickAndProcess,
              child: const Text('MP3を選択して高精度波形を表示'),
            ),
            const SizedBox(height: 20),
            Text(_fileName),
            const SizedBox(height: 20),
            if (_peaks.isNotEmpty)
              Container(
                width: 600,
                height: 150,
                color: const Color(0xFF1E1E2E),
                // 3. 切り出したPainterで描画
                child: CustomPaint(
                  painter: PcmWaveformPainter(_peaks),
                ),
              ),
          ],
        ),
      ),
    );
  }
}