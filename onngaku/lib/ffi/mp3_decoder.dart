import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

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

class Mp3Decoder {
  late final DynamicLibrary _lib;
  late final DartDecodeMp3 _decodeMp3;
  late final DartFreePcm _freePcm;

  Mp3Decoder() {
    _lib = DynamicLibrary.executable();
    _decodeMp3 = _lib.lookupFunction<NativeDecodeMp3, DartDecodeMp3>('decode_mp3_file');
    _freePcm = _lib.lookupFunction<NativeFreePcm, DartFreePcm>('free_pcm_data');
  }

  Float32List? decode(String path) {
    final pathPtr = path.toNativeUtf8();
    final sampleCountPtr = calloc<Uint64>();
    final channelsPtr = calloc<Uint32>();
    final sampleRatePtr = calloc<Uint32>();

    try {
      final floatPtr = _decodeMp3(pathPtr, sampleCountPtr, channelsPtr, sampleRatePtr);
      if (floatPtr == nullptr) return null;

      final count = sampleCountPtr.value;
      final rawSamples = floatPtr.asTypedList(count);
      final pcmList = Float32List.fromList(rawSamples);

      _freePcm(floatPtr);
      return pcmList;
    } finally {
      calloc.free(pathPtr);
      calloc.free(sampleCountPtr);
      calloc.free(channelsPtr);
      calloc.free(sampleRatePtr);
    }
  }
}