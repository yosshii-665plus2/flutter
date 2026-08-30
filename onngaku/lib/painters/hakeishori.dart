import 'dart:async';
import 'package:flutter/material.dart';
import 'pcm_waveform_painter.dart';
import 'package:audioplayers/audioplayers.dart';
import '../main.dart';


class HakeiShori extends StatefulWidget{
  final AudioPlayer audioPlayer;
  final HakeiState hakeistate;
  final List<HakeiState> hakeiList;
  final bool isPlaying;
  final Function(HakeiState) onRemove;
  
  
  const HakeiShori({
    super.key, 
    required this.audioPlayer, 
    required this.hakeistate, 
    required this.hakeiList, 
    required this.isPlaying, 
    required this.onRemove
    });

  @override
  State<HakeiShori> createState() => _HakeiShoriState();
}

class _HakeiShoriState extends State<HakeiShori> {

  double location=0.0;
  Duration? duration=null;
  StreamSubscription<Duration>? _listener1;
  StreamSubscription<void>? _listener2;

  @override
  void initState() {
    super.initState();

    // 再生位置の変化を監視して波形のプログレスバーを更新
    _listener1 = widget.audioPlayer.onDurationChanged.listen((position) async {
            duration = await widget.audioPlayer.getDuration();
            if(widget.hakeistate.length!=duration?.inMilliseconds)
            {
              widget.hakeistate.length=duration?.inMilliseconds ?? 0;
            }
    });


    _listener2 = widget.audioPlayer.onPlayerComplete.listen((event) {
      // 2. 再生終了時に実行したい処理をここに書く
      setState(() {
        widget.hakeiList.map((hakei) {
          hakei.canPlaying = true; 
          return hakei;
        }).toList();
      });
    });
  }

  // 再生 / 一時停止のトグル
  Future<void> _togglePlay() async {
    String? _filePath=widget.hakeistate.filePath;
    if (_filePath == null || _filePath.isEmpty) return;
    
      if (widget.isPlaying) {
        widget.hakeiList.map((hakei) {
          if(!hakei.stoped!)
          {
            hakei.canPlaying = true; 
          }
          return hakei;
          }).toList();
        await widget.audioPlayer.pause();
      } else {
        widget.hakeiList.map((hakei) {
           hakei.canPlaying = false; 
           return hakei;
           }).toList(); // 他の波形の再生を停止
        widget.hakeistate.canPlaying = true;
        await widget.audioPlayer.play(DeviceFileSource(_filePath));
      }
    
  }

  @override
  void dispose() {
    _listener1?.cancel();
    _listener2?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: widget.hakeistate.length/10,
      child:Column( children: [ 
        Row(
          children: [
            IconButton(
              iconSize: 13,
              padding: EdgeInsets.all(4),
              constraints: const BoxConstraints(), // 48x48 の最小サイズ制限を解除
              color: Colors.cyanAccent,
              icon: Icon(widget.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
              onPressed: widget.hakeistate.canPlaying&&!(widget.hakeistate.stoped ?? false) ? _togglePlay : null,
            ),
            IconButton(
              iconSize:13,
              padding: EdgeInsets.all(4),
              constraints: const BoxConstraints(), // 48x48 の最小サイズ制限を解除
              color: Colors.red,
              icon:Icon(Icons.delete),
              onPressed: () => widget.onRemove(widget.hakeistate),
            ),
            Transform.translate(
              offset: const Offset(0, 1.07), 
              child: Container(
                height: 17,
                color: Color.fromARGB(0, 0, 0, 0),
                child: Transform.scale(
                  scale: 0.7,
                  child: Checkbox(
                    visualDensity: const VisualDensity(horizontal:-4, vertical: 2),
                    value: widget.hakeistate.stoped,
                    onChanged: (bool? value) {
                      setState(() {
                        widget.hakeistate.stoped = value;
                      });
                    },
                  ),
                )
              )
            )
            
          ]),
          Stack(
            children: [
              Container(
                width: widget.hakeistate.length/10,
                height: 80,
                color: Color.fromARGB(255, 33, 35, 46),
              ),
              CustomPaint(
                size: Size(widget.hakeistate.length/10, 80),
                painter: PcmWaveformPainter(widget.hakeistate),
              )
            ],),
        ])
    );
  }
}