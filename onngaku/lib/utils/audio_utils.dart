import 'dart:typed_data';

List<double> extractPeaks(Float32List pcmData, int targetCount) {
  final List<double> peaks = [];
  final int blockSize = (pcmData.length / targetCount).floor();

  for (int i = 0; i < targetCount; i++) {
    int start = i * blockSize;
    int end = (i + 1) * blockSize;
    if (end > pcmData.length) end = pcmData.length;

    double maxVal = 0.0;
    for (int j = start; j < end; j++) {
      double absVal = pcmData[j].abs();
      if (absVal > maxVal) {
        maxVal = absVal;
      }
    }
    peaks.add(maxVal);
  }

  return peaks;
}