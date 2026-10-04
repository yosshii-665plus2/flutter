import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';
import 'package:ongaku/okiba/menuebutton.dart';
import 'ffi/mp3_decoder.dart';
import 'utils/audio_utils.dart';
import 'painters/hakeishori.dart';
import 'painters/rean.dart';
import 'painters/reanshori.dart';
import 'package:flutter/gestures.dart';

void main() {
  runApp(const MaterialApp(home: AudioApp()));
}

class AudioApp extends StatefulWidget {
  const AudioApp({super.key});

  @override
  State<AudioApp> createState() => _AudioAppState();
}

class HakeiState {
  String? filePath;
  List<double> peaks;
  bool canPlaying;
  bool? stoped = false;
  int length=0;
  AudioPlayer audioPlayer;
  Offset? realOffset=Offset.zero;
  Offset? newoffset=Offset.zero;
  Offset? dragOffset=Offset.zero;
  bool draged = false;

  HakeiState({required this.filePath, required this.peaks, required this.canPlaying, required this.audioPlayer});
}


class _AudioAppState extends State<AudioApp> {
  final Mp3Decoder _decoder = Mp3Decoder();
  final AudioPlayer _audioPlayer = AudioPlayer(); // オーディオプレーヤー本体
  bool _isPlaying = false;
  List<HakeiState> hakeiList = [];
  double reanhight=100*pow(0.9,1).toDouble();
  final ScrollController _controller = ScrollController();



  @override
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

      debugPrint('decode result: ${pcmData == null ? "null (失敗)" : "${pcmData.length} サンプル"}');

      if (pcmData != null) {
        final peaks = extractPeaks(pcmData, 300);
        final newHakeiState = HakeiState(filePath: path, peaks: peaks, canPlaying: true, audioPlayer: AudioPlayer());
        setState(() {
          hakeiList.add(newHakeiState);
        });

        debugPrint('hakeiList.length = ${hakeiList.length}');
        await newHakeiState.audioPlayer.setSource(DeviceFileSource(path));
        debugPrint(hakeiList.map((h) => h.length).toList().toString());
      }
    }
  }

  HakeiState add_rean(){ {
    HakeiState newHakeiState = HakeiState(filePath: null, peaks: [], canPlaying: true, audioPlayer:_audioPlayer);
    return newHakeiState;
  }}

  double leftWidth=130;
  double topHight=140;
  List<HakeiState> reanList=[];

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 50, 50, 50),
      body:Stack (
        children: [
          Container(
            width: leftWidth,
            color:const Color(0xFF1E1E2E),
          ),
          Column(children: [
            Container(
              height: topHight,
              width: screenSize.width,
              color: Color.fromARGB(255, 24, 21, 26),
              alignment: Alignment.bottomLeft,
              child: Transform.translate(
                offset: const Offset(40, -3),
                child:ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    // 1. 角丸をなくして直角（四角形）にする
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                    fixedSize: const Size(23, 15),
                  ),
                  onPressed: () {
                    setState(() {
                      reanList.add(add_rean());
                    });
                  },
                  child: const Icon(Icons.add,size:13),
                ),
              ),
            ),
            for( var (i,hakei)in reanList.indexed)
            Row(
              children: [  
                Container(
                  height: reanhight,
                  width: leftWidth,
                  color: const Color(0xFF1E1E2E),
                  child:Row(children: [
                    Checkbox(
                      value: hakei.stoped,
                      onChanged: (bool? value) {
                        setState(() {
                          hakei.stoped = value;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete,color: Colors.red,size: 15),
                      onPressed: () {
                        setState(() {
                          reanList.removeAt(i);
                        });
                      },
                    ),
                  ]),
                ),
                Stack(children:[
                  CustomPaint(
                    size: Size(max(screenSize.width-leftWidth,0), reanhight),
                    painter: Rean(),
                  ),
                  Reanshori(
                    hakeiState: hakei,
                    highth: reanhight,
                    wideth: max(screenSize.width - leftWidth,0),
                    reanList: reanList,
                  ),
                ])
            ])
          ]),
          Menuebutton(
            pickAndProcess: _pickAndProcess
          ),

          Positioned(
            left: 150,
            top: 15,
            child: SizedBox(
              width: 1000,
              height: 128,
              child:Theme(
                data: Theme.of(context).copyWith(
                  scrollbarTheme: ScrollbarThemeData(
                    thumbColor: WidgetStateProperty.all(const Color.fromARGB(41, 255, 255, 255)),
                    trackColor: WidgetStateProperty.all(const Color.fromARGB(24, 255, 255, 255)),
                    trackBorderColor: WidgetStateProperty.all(Colors.transparent),
                    radius: const Radius.circular(4),
                  ),
                ),
                child:Scrollbar(
                  controller: _controller,
                  thumbVisibility: true,
                  interactive: true,
                  child:ListView.builder(
                    controller: _controller,
                    clipBehavior: ((){
                      bool _draged=hakeiList.any((_hakeiState) => _hakeiState.draged);
                      if(_draged)
                      return Clip.none;
                      else
                      return Clip.hardEdge;
                    })(),
                    scrollDirection: Axis.horizontal,
                    itemCount: hakeiList.length,
                    itemBuilder: (context, index) {
                      final hakeiState = hakeiList[index];
                      return Transform.translate(
                        offset: hakeiState.dragOffset ?? const Offset(0, 0),
                        child: GestureDetector(
                          onPanStart:(details){
                            setState(() {
                              hakeiState.draged=true;
                            });
                          },
                          onPanUpdate:(details){
                            Offset realoffset = (hakeiState.realOffset ?? Offset.zero) + details.delta;
                            Offset newoffset=realoffset;
                            for(int i=0;i<reanList.length;i++){
                              if(realoffset.dy>topHight-15-reanhight+i*(reanhight) && realoffset.dy<topHight-15-reanhight+(i+1)*(reanhight)){
                                newoffset=Offset(realoffset.dx,topHight-15+i*(reanhight));
                              }
                            }
                            setState(() {
                              hakeiState.realOffset = realoffset;
                              hakeiState.dragOffset = reanList.length!=0?newoffset:realoffset;
                            });
                          },
                          supportedDevices: const {
                            PointerDeviceKind.mouse,
                            PointerDeviceKind.touch,
                            PointerDeviceKind.stylus,
                          },
                          onPanEnd:(details){
                            setState(() {
                              hakeiState.realOffset = Offset.zero;
                              hakeiState.dragOffset = Offset.zero;
                              hakeiState.draged=false;
                            });
                          },
                          onPanCancel:(){
                            setState(() {
                              hakeiState.realOffset = Offset.zero;
                              hakeiState.dragOffset = Offset.zero;
                              hakeiState.draged=false;
                            });
                          },
                          child:HakeiShori(
                            key: ObjectKey(hakeiState),
                            hakeiList: hakeiList,
                            hakeistate: hakeiState,
                            isPlaying: _isPlaying,
                            draged: hakeiState.draged,
                            onRemove: (HakeiState state) async {
                                await state.audioPlayer.stop();
                                await state.audioPlayer.dispose();
                              setState(() {
                                hakeiList.remove(state);
                              });
                            },
                          ),
                        )
                      );
                    }, 
                  )
                ),
              )
            )
          )
      ])
    );
  }
}