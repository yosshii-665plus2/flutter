import 'package:flutter/material.dart';
import 'package:ongaku/painters/pcm_waveform_painter.dart';
import '../main.dart';

class Reanshori extends StatefulWidget{
  Reanshori({super.key, required this.hakeiState,required this.highth,required this.wideth,required this.reanList});
  final HakeiState hakeiState;
  final double highth;
  final double wideth;
  final List<HakeiState> reanList;
  @override
  State<Reanshori> createState() => _ReanshoriState();
}

class _ReanshoriState extends State<Reanshori> {
  
  @override
  void dispose() {
    
    super.dispose();
  }
  
  
  
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(widget.wideth, widget.highth),
      painter:PcmWaveformPainter(widget.hakeiState),
    );
  }
}