import 'package:flutter/material.dart';
import 'package:ongaku/painters/pcm_waveform_painter.dart';
import '../main.dart';

class Reanshori extends StatefulWidget{
  Reanshori({super.key,required Size this.size ,required Rean this.rean});
  final Size size;
  final Rean rean;

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
    return Stack(children: [
      for(ReanState reanstate in widget.rean.reanStateList)
      Positioned(
        child:CustomPaint(
          size: widget.size,
          painter:PcmWaveformPainter(reanstate.hakeistate,widget.rean.locked),
        ), 
      )
    ],);
  }
}