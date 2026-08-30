import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'ffi/mp3_decoder.dart';
import 'utils/audio_utils.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';


void main() {
  runApp(const MainApp());
}

class HakeiState {
  String? filePath;
  List<double> peaks;
  bool canPlaying;
  bool? stopped = false;

  HakeiState({required this.filePath, required this.peaks, required this.canPlaying});
}


class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
      backgroundColor: Colors.black,
      body:Base()
      ),
    );
  }
}


class Base extends StatelessWidget {
  const Base({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}


class Rean extends StatefulWidget {
  Rean({super.key});

  @override
  State<Rean> createState() => _ReanState();
}

class _ReanState extends State<Rean>{
  final Mp3Decoder _decoder = Mp3Decoder();
  final AudioPlayer _audioPlayer = AudioPlayer(); // オーディオプレーヤー本体
  bool _isPlaying = false;
  List<HakeiState> hakeiList = [];
  HakeiState hakeiState = HakeiState(filePath: null, peaks: [], canPlaying: false);


  Future<void> _kaitou() async{

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'flac', 'ogg'],
    );


if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      
      // miniaudio 側に渡してデコード（ファイル形式を自動認識して解析）
      final audioData = _decoder.decode(path);

      if (audioData != null) {
        final peaks = extractPeaks(audioData.samples);

        setState(() {
          hakeiList.add(HakeiState(filePath: path, peaks:  peaks, canPlaying: true));
        });

        await _audioPlayer.setSource(DeviceFileSource(path));
      }
    }  }

  @override
  void  dispose(){

    super.dispose();
  }


  @override
  build(BuildContext context) {
    return Container();
  }
}