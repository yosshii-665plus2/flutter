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
  
  const HakeiShori({super.key, required this.audioPlayer, required this.hakeistate, required this.hakeiList, required this.isPlaying, required this.onRemove});

  @override
  State<HakeiShori> createState() => _HakeiShoriState();
}

class _HakeiShoriState extends State<HakeiShori> {

  double _progress = 0.0; // 再生位置（0.0 〜 1.0）
  StreamSubscription<Duration>? _listener1;
  StreamSubscription<void>? _listener2;

  @override
  void initState() {
    super.initState();

    // 再生位置の変化を監視して波形のプログレスバーを更新
    _listener1 = widget.audioPlayer.onPositionChanged.listen((position) async {
      final duration = await widget.audioPlayer.getDuration();
      if (duration != null && duration.inMilliseconds > 0) {
        if(widget.hakeistate.canPlaying) {
          setState(() {
            _progress = position.inMilliseconds / duration.inMilliseconds;
          });
        }
      }
    });

    _listener2 = widget.audioPlayer.onPlayerComplete.listen((event) {
      // 2. 再生終了時に実行したい処理をここに書く
      setState(() {
        _progress = 0.0; // 再生位置をリセット
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
    widget.audioPlayer.stop();
    _listener1?.cancel();
    _listener2?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row( children: [ 
                  Container(
                    width: 135,
                    height: 100,
                    color: const Color(0xFF2D2D3C),
                    child: 
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Checkbox(
                          value: widget.hakeistate.stoped,
                          onChanged: (bool? value) {
                            setState(() {
                              widget.hakeistate.stoped = value;
                            });
                          },
                        ),
                        IconButton(
                          iconSize:20,
                          color: Colors.red,
                          icon:Icon(Icons.delete),
                          onPressed: () => widget.onRemove(widget.hakeistate),
                        ),
                        IconButton(
                          iconSize: 20,
                          color: Colors.cyanAccent,
                          icon: Icon(widget.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
                          onPressed: widget.hakeistate.canPlaying&&!(widget.hakeistate.stoped ?? false) ? _togglePlay : null,
                        )
                    ])
                  ),
                  Stack(
                    children: [
                      Container(
                        width: 700,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CustomPaint(
                          painter: PcmWaveformPainter(widget.hakeistate),
                        ),
                      ),
                      // 再生位置を示すバー（プレイヘッド）
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: 700 * _progress,
                        child: Container(
                          width: 2,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],),
              ]);
  }
}