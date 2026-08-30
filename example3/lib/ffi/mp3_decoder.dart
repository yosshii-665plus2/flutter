import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

// --- FFI 型定義 ---
typedef NativeDecodeMp3 = Pointer<Float> Function(
  Pointer<Utf8> filePath,
  Pointer<Uint64> outSampleCount,
  Pointer<Uint32> outChannels,
  Pointer<Uint32> outSampleRate,
);
typedef DartDecodeMp3 = Pointer<Float> Function(
  Pointer<Utf8> filePath,
  Pointer<Uint64> outSampleCount,
  Pointer<Uint32> outChannels,
  Pointer<Uint32> outSampleRate,
);

typedef NativeFreePcm = Void Function(Pointer<Float> pSampleData);
typedef DartFreePcm = void Function(Pointer<Float> pSampleData);

// --- デコード結果保持用クラス ---
class AudioData {
  final Float32List samples; // PCMデータ (-1.0 〜 1.0)
  final int channels;        // チャンネル数 (1: モノラル, 2: ステレオ)
  final int sampleRate;      // サンプリングレート (44100, 48000 など)

  AudioData({
    required this.samples,
    required this.channels,
    required this.sampleRate,
  });
}

// --- デコーダークラス ---
class Mp3Decoder {
  late final DynamicLibrary _lib;
  late final DartDecodeMp3 _decodeMp3;
  late final DartFreePcm _freePcm;

  Mp3Decoder() {
    _lib = DynamicLibrary.executable();
    _decodeMp3 = _lib.lookupFunction<NativeDecodeMp3, DartDecodeMp3>('decode_mp3_file');
    _freePcm = _lib.lookupFunction<NativeFreePcm, DartFreePcm>('free_pcm_data');
  }

  /// 指定したファイルパスの音声をデコードし、AudioData として返す
  AudioData? decode(String path) {
    final pathPtr = path.toNativeUtf8();
    final sampleCountPtr = calloc<Uint64>();
    final channelsPtr = calloc<Uint32>();
    final sampleRatePtr = calloc<Uint32>();

    try {
      final floatPtr = _decodeMp3(pathPtr, sampleCountPtr, channelsPtr, sampleRatePtr);
      if (floatPtr == nullptr) return null;

      final count = sampleCountPtr.value;
      final channels = channelsPtr.value;
      final sampleRate = sampleRatePtr.value;

      // C側のポインタからDart用リストへコピー
      final rawSamples = floatPtr.asTypedList(count);
      final pcmList = Float32List.fromList(rawSamples);

      // C側のメモリを開放
      _freePcm(floatPtr);

      return AudioData(
        samples: pcmList,
        channels: channels,
        sampleRate: sampleRate,
      );
    } finally {
      calloc.free(pathPtr);
      calloc.free(sampleCountPtr);
      calloc.free(channelsPtr);
      calloc.free(sampleRatePtr);
    }
  }
}