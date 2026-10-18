import 'dart:async';
import 'package:flutter/material.dart';
import 'pcm_waveform_painter.dart';
import 'package:audioplayers/audioplayers.dart';
import '../main.dart';


class PickHakeiShori extends StatefulWidget{
  final PickupState pickupState;
  final List<HakeiState> hakeiList;
  final Function(PickupState) onRemove;
  final bool draged;

  
  const PickHakeiShori({
    super.key, 
    required this.pickupState, 
    required this.hakeiList, 
    required this.onRemove
    ,required this.draged
    });

  @override
  State<PickHakeiShori> createState() => _PickHakeiShoriState();
}

class _PickHakeiShoriState extends State<PickHakeiShori> {
  double location=0.0;
  StreamSubscription<Duration>? _listener1;
  StreamSubscription<void>? _listener2;
  bool isPlaying=false;


  @override
  void initState() {
    super.initState();

    _listener1 = widget.pickupState.audioPlayer.onDurationChanged.listen((duration) async {
      setState(() {
        widget.pickupState.hakeistate.length=duration.inMilliseconds;
        _listener1?.cancel();
      });
            
    });


    _listener2 = widget.pickupState.audioPlayer.onPlayerComplete.listen((event) {
      if (!mounted) return;
      // 2. 再生終了時に実行したい処理をここに書く
      setState(() {
        isPlaying=false;
      });
    });
  }

  // 再生 / 一時停止のトグル
  Future<void> _togglePlay() async {
    String? _filePath=widget.pickupState.hakeistate.filePath;
    if (_filePath == null || _filePath.isEmpty) return;
    
      if (isPlaying) {
        await widget.pickupState.audioPlayer.stop();
        isPlaying=false;
      } else {
        await widget.pickupState.audioPlayer.play(DeviceFileSource(_filePath));
        isPlaying=true;
      }
    if (!mounted) return;
    setState(() {});
  }


OverlayEntry? _overlayEntry;
ValueNotifier<Offset> _mousePosition = ValueNotifier(Offset.zero);
void _showOverlay(BuildContext context, String text) {

  _hideOverlay();
  _overlayEntry = OverlayEntry(
    builder: (context) {
        // 位置が更新された時だけ、この ValueListenableBuilder の中身だけが軽量再描画される
        return ValueListenableBuilder<Offset>(
          valueListenable: _mousePosition,
          builder: (context,pos,child) => Positioned(
            top: pos.dy + 10,
            left: pos.dx,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  text,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
    );}
  );
  Overlay.of(context).insert(_overlayEntry!);
}

void _hideOverlay() {
  _overlayEntry?.remove();
  _overlayEntry = null;
}

  @override
  void dispose() {
    _listener1?.cancel();
    _listener2?.cancel();
    _hideOverlay();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: widget.pickupState.hakeistate.length/10,
      color: const Color.fromARGB(0, 50, 50, 50),
      child:Column( children: [ 
        !widget.draged?Row(
          children: [
            IconButton(
              iconSize: 13,
              padding: EdgeInsets.all(4),
              constraints: const BoxConstraints(), // 48x48 の最小サイズ制限を解除
              color: Colors.cyanAccent,
              icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
              onPressed:_togglePlay 
            ),
            IconButton(
              iconSize:13,
              padding: EdgeInsets.all(4),
              constraints: const BoxConstraints(), // 48x48 の最小サイズ制限を解除
              color: Colors.red,
              icon:Icon(Icons.delete),
              onPressed: () => widget.onRemove(widget.pickupState),
            ),
          ]):const SizedBox(
            height: 4.5,
          ),
        MouseRegion(
          onEnter: (_) => setState(() => _showOverlay(context,widget.pickupState.hakeistate.filePath?.split(RegExp(r'[/\\]')).last??'')),
          onExit: (_) => setState(() => _hideOverlay()),
          onHover: (event) {
            _mousePosition.value = event.position; // エリア内のローカル座標を取得
          },
          child:Stack(children: [
            Container(
              width: widget.pickupState.hakeistate.length/10,
              height: 80,
              color: Color.fromARGB(255, 33, 35, 46),
            ),
            CustomPaint(
              size: Size(widget.pickupState.hakeistate.length/10, 80),
              painter: PcmWaveformPainter(widget.pickupState.hakeistate,false),
            ),
        ],),
        )
      ])
    );
  }
}


