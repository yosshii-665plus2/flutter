import 'package:flutter/material.dart';
import '../main.dart';

class PcmWaveformPainter extends CustomPainter {
  final List<double> peaks;
  final bool canPlaying;
  final bool stoped;
  
  PcmWaveformPainter(HakeiState hakeistate)
      : peaks = hakeistate.peaks,
        canPlaying = hakeistate.canPlaying,
        stoped = hakeistate.stoped ?? false;

  @override
  void paint(Canvas canvas, Size size) {
    if (peaks.isEmpty) return;

    final paint = Paint()
      ..color = canPlaying && !stoped ? Colors.cyanAccent : Color.fromARGB(255, 87, 87, 87)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final double widthPerSample = size.width / peaks.length;
    final double centerY = size.height / 2;

    for (int i = 0; i < peaks.length; i++) {
      double x = i * widthPerSample + (widthPerSample / 2);
      double amplitudeHeight = peaks[i] * (size.height / 2);

      canvas.drawLine(
        Offset(x, centerY - amplitudeHeight),
        Offset(x, centerY + amplitudeHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PcmWaveformPainter oldDelegate) {
    return oldDelegate.peaks != peaks;
  }
}