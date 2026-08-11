import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'ffi/mp3_decoder.dart';
import 'utils/audio_utils.dart';
import 'painters/hakeishori.dart';

void main() {
  runApp(const MaterialApp(home: AudioApp()));
}

class AudioApp extends StatefulWidget {
  const AudioApp({super.key});

  @override
  State<AudioApp> createState() => _AudioAppState();
}

class HakeiState {
  String filePath;
  List<double> peaks;
  bool canPlaying;
  double progress=0;

  HakeiState({required this.filePath, required this.peaks, required this.canPlaying, this.progress = 0});
}

class _AudioAppState extends State<AudioApp> {
  final Mp3Decoder _decoder = Mp3Decoder();
  final AudioPlayer _audioPlayer = AudioPlayer(); // オーディオプレーヤー本体
  bool _isPlaying = false;
  List<HakeiState> hakeiList = [];
  HakeiState hakeiState = HakeiState(filePath: '', peaks: [], canPlaying: false);

  void initState() {
    super.initState();

    // 再生状態の変化を監視
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _pickAndProcess() async {
    // ここを置き換え
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'flac', 'ogg'],
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      
      // miniaudio 側に渡してデコード（ファイル形式を自動認識して解析）
      final pcmData = _decoder.decode(path);

      if (pcmData != null) {
        final peaks = extractPeaks(pcmData, 300);

        setState(() {
          hakeiList.add(HakeiState(filePath: path, peaks: peaks, canPlaying: true, progress: 0.0));
        });

        await _audioPlayer.setSource(DeviceFileSource(path));
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 50, 50, 50),
      body:Row(
        children: [
          Container(
            width: 130,
            color: const Color(0xFF1E1E2E),
          ),
          Column(
            crossAxisAlignment:CrossAxisAlignment.start,
            children: [
              ElevatedButton.icon(
                onPressed: _pickAndProcess,
                icon: const Icon(Icons.folder_open),
                label: const Text('音声ファイルを選択'),
            ),
            // 波形表示エリア
            for(hakeiState in hakeiList)...[
              HakeiShori(
                key: ValueKey(hakeiState.peaks),
                audioPlayer: _audioPlayer,
                hakeiList: hakeiList,
                hakeistate: hakeiState,
                isPlaying: _isPlaying,
                onRemove: (HakeiState state) {
                  setState(() {
                    hakeiList.remove(state);
                  });
                },
              ),
            ],
          ]),
      ])
    );
  }
}