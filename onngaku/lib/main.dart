import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:typed_data';
import 'dart:math';
import 'package:ongaku/okiba/menuebutton.dart';
import 'ffi/mp3_decoder.dart';
import 'utils/audio_utils.dart';
import 'painters/hakeishori.dart';
import 'painters/reanback.dart';
import 'package:flutter/gestures.dart';
import 'change.dart';
import 'utils/hakei_toFile.dart';

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
  Float32List peaks;
  int length=0;

  HakeiState({required this.filePath, required this.peaks});
}

class ReanState {
  HakeiState hakeistate;
  List<Changes>changes=[];
  int starttime;
  

  ReanState({required this.hakeistate,this.starttime=0});
}

class PickupState{
  String name="";
  HakeiState hakeistate;
  List<Changes> changes=[];
  AudioPlayer audioPlayer = AudioPlayer();
  Offset? realOffset=Offset.zero;
  Offset? newoffset=Offset.zero;
  Offset? dragOffset=Offset.zero;
  bool draged = false;
  int reanNumber=-1;

  PickupState({required this.hakeistate});
}

class Rean{
  AudioPlayer? audioPlayer;
  List<ReanState> reanStateList=[];
  bool? locked = false;
  bool isPlaying=false;

  Float32List combiningRean(){
    List<Float32List> _float32Lists=reanStateList.map((reanState){return Changes.pushToFloat32List(reanState.hakeistate, reanState.changes);}).toList();
    int end=0;
    for(int i=0;i<reanStateList.length;i++)
    {
      if(end<(reanStateList[i].starttime+_float32Lists[i].length*1000/44100).round())
      {
        end=(reanStateList[i].starttime+_float32Lists[i].length*1000/44100).round();
      }
    }
    Float32List sum=Float32List(((10+end)*44100/1000).round());
    for(int i=0;i<_float32Lists.length;i++)
    {
      for(int j=0;j<_float32Lists[i].length;j++)
      {
        sum[j+(reanStateList[i].starttime*44100/1000).round()]+=_float32Lists[i][j];
      }
    }
    return sum;
  }

}


class _AudioAppState extends State<AudioApp> {
  final Mp3Decoder _decoder = Mp3Decoder();
  final AudioPlayer _audioPlayer = AudioPlayer(); // オーディオプレーヤー本体
  List<HakeiState> hakeiList = [];
  List<PickupState> pickupList = [];
  final double reanhight=100*pow(0.9,1).toDouble();
  final ScrollController _controller = ScrollController();
  List<AudioPlayer> _audioPlayers = [AudioPlayer(), AudioPlayer(), AudioPlayer(), AudioPlayer(), AudioPlayer()]; // 複数のオーディオプレーヤーを管理するリスト
  int playerNumber=0;
  int seek=0;

  @override
  void dispose() {
    _audioPlayer.dispose();
    for (var player in _audioPlayers) {
      player.dispose();
    }
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
        final newHakeiState = HakeiState(filePath: path, peaks: peaks);
        hakeiList.add(newHakeiState);
        final newPick = PickupState(hakeistate: newHakeiState);
        pickupList.add(newPick);
        setState(() {});

        debugPrint('hakeiList.length = ${hakeiList.length}');
        await newPick.audioPlayer.setSource(DeviceFileSource(path));
        debugPrint(hakeiList.map((h) => h.length).toList().toString());
      }
    }
  }

  ReanState _sethakei(PickupState pickupState,Offset iti){
    ReanState reanState =ReanState(hakeistate: pickupState.hakeistate,starttime: (iti.dx/1+100).round());

    return reanState;
  }

  void restChecker(){
    hakeiList.removeWhere(
      (hakei) => !pickupList.any((pick) => pick.hakeistate == hakei)
      && !reanList.any((rean) => rean.reanStateList.any((reanstate) => reanstate.hakeistate == hakei))
    );
  }

  // 再生 / 一時停止のトグル
  Future<void> _rean_togglePlay(Rean rean) async {
    String path = await HakeiToFile.hakeiToFile(rean);
    if (path.isEmpty) return;
    if(playerNumber>=_audioPlayers.length) return;
    AudioPlayer _subAudioPlayer = _audioPlayers[playerNumber];
    playerNumber = playerNumber+1;
    
      if (rean.isPlaying) {
        await _subAudioPlayer.stop();
        rean.isPlaying=false;
      } else {
        await _subAudioPlayer.play(DeviceFileSource(path));
        await _subAudioPlayer.seek(Duration(milliseconds: seek));
        rean.isPlaying=true;
      }
    if (!mounted) return;
    setState(() {});
  }


  double leftWidth=130;
  double topHight=140;
  List<Rean> reanList=[];
  double x=0;
  double zoom=1;
  final ScrollController _scrollController = ScrollController();

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
                      reanList.add(Rean());
                    });
                  },
                  child: const Icon(Icons.add,size:13),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Row(
                  children:[
                    Column(children: [
                      SizedBox(width: leftWidth,height: 0),
                      for(int i=0;i<reanList.length;i++)
                      Container(
                        color: Color.fromARGB(255, 13, 4, 38),
                        height: reanhight,
                        width: leftWidth,
                        child: Row(children: [
                          Checkbox(
                            value: reanList[i].locked,
                            onChanged: (bool? value) {
                              setState(() {
                                reanList[i].locked = value;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,color: Colors.red,size: 15),
                            onPressed: () {
                              setState(() {
                                Changes.log();
                                reanList.removeAt(i);
                              });
                            },
                          ),
                          SizedBox(width: 15),
                          IconButton(
                            iconSize: 17,
                            padding: EdgeInsets.all(4),
                            constraints: const BoxConstraints(), // 48x48 の最小サイズ制限を解除
                            color: Colors.cyanAccent,
                            icon: Icon(reanList[i].isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
                            onPressed:() => _rean_togglePlay(reanList[i]),
                          ),
                        ]),
                      ),
                    ]),
                    GestureDetector(
                      child:CustomPaint(
                        size: Size(max(screenSize.width-leftWidth, 0),max(reanhight*reanList.length,0)),
                        painter:ReanBack(listSize: reanList.length),
                      )
                    ),
                  ]
                )
              )
            )
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
                      bool _draged=pickupList.any((_hakeiState) => _hakeiState.draged);
                      if(_draged)
                      return Clip.none;
                      else
                      return Clip.hardEdge;
                    })(),
                    scrollDirection: Axis.horizontal,
                    itemCount: pickupList.length,
                    itemBuilder: (context, index) {
                      final pickupState = pickupList[index];
                      return Transform.translate(
                        offset: pickupState.dragOffset ?? const Offset(0, 0),
                        child: GestureDetector(
                          onPanStart:(details){
                            setState(() {
                              pickupState.draged=true;
                            });
                          },
                          onPanUpdate:(details){
                            Offset realoffset = (pickupState.realOffset ?? Offset.zero) + details.delta;
                            Offset newoffset=realoffset;
                            for(int i=0;i<reanList.length;i++){
                              if(realoffset.dy>topHight-15-reanhight+i*(reanhight) && realoffset.dy<topHight-15-reanhight+(i+1)*(reanhight)){
                                newoffset=Offset(realoffset.dx,topHight-15+i*(reanhight));
                                pickupState.reanNumber=i;
                              }
                            }
                            setState(() {
                              pickupState.realOffset = realoffset;
                              pickupState.dragOffset = reanList.length!=0?newoffset:realoffset;
                            });
                          },
                          supportedDevices: const {
                            PointerDeviceKind.mouse,
                            PointerDeviceKind.touch,
                            PointerDeviceKind.stylus,
                          },
                          onPanEnd:(details){
                            if(pickupState.reanNumber!=-1){
                              reanList[pickupState.reanNumber].reanStateList.add(_sethakei(pickupState,pickupState.dragOffset??Offset.zero));
                            }

                            setState(() {
                              pickupState.realOffset = Offset.zero;
                              pickupState.dragOffset = Offset.zero;
                              pickupState.draged=false;
                              pickupState.reanNumber = -1;
                            });
                          },
                          onPanCancel:(){
                            setState(() {
                              pickupState.realOffset = Offset.zero;
                              pickupState.dragOffset = Offset.zero;
                              pickupState.draged=false;
                              pickupState.reanNumber = -1;
                            });
                          },
                          child:PickHakeiShori(
                            key: ObjectKey(pickupState),
                            pickupList: pickupList,
                            pickupState: pickupState,
                            draged: pickupState.draged,
                            onRemove: (PickupState state) async {
                              await state.audioPlayer.stop();
                              await state.audioPlayer.dispose();
                              pickupList.remove(state);
                              restChecker();
                              setState(() {});
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