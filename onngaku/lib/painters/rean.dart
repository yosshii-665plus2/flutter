import 'package:flutter/material.dart';

class Rean extends CustomPainter{
  
  @override
  void paint(Canvas canvas, Size size){
    final paint = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke; // PaintingStyle.fill で塗りつぶし
      Offset p1;
      Offset p2;

      for(int j=0;j<size.width;j+=100){
        paint.color = const Color.fromARGB(154, 108, 108, 108);
        for(int i=1;i<=4;i++){
          p1= Offset(j+i*20,0);
          p2 =Offset(j+i*20,size.height);
          canvas.drawLine(p1, p2, paint);
        }

        paint.color=.fromARGB(185, 135, 135, 135);
        p1=Offset(j/1, 0);
        p2=Offset(j/1, size.height);
        canvas.drawLine(p1, p2, paint);
      }
    paint.strokeWidth=1;
    p1=Offset(0,size.height);
    p2=Offset(size.width,size.height);
    canvas.drawLine(p1, p2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false; // 値の変更に伴う再描画が不要な場合は false
  }
}