#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"

#include <cstdint>
#include <cstdlib>
#include <cstdio>
#include <vector>

extern "C" {

// MP3/WAV/FLAC等 を全自動でデコードする関数（Linux版）
__attribute__((visibility("default")))
float* decode_mp3_file(
    const char* filePath,
    uint64_t* outSampleCount,
    uint32_t* outChannels,
    uint32_t* outSampleRate
) {
    // Linux はファイルパスが元から UTF-8 なので変換不要
    FILE* f = fopen(filePath, "rb");
    if (!f) {
        *outSampleCount = 0;
        return nullptr;
    }

    fseek(f, 0, SEEK_END);
    long fileSize = ftell(f);
    fseek(f, 0, SEEK_SET);

    if (fileSize <= 0) {
        fclose(f);
        *outSampleCount = 0;
        return nullptr;
    }

    std::vector<uint8_t> buffer(static_cast<size_t>(fileSize));
    size_t bytesRead = fread(buffer.data(), 1, buffer.size(), f);
    fclose(f);

    if (bytesRead != buffer.size()) {
        *outSampleCount = 0;
        return nullptr;
    }

    ma_decoder decoder;
    ma_decoder_config config = ma_decoder_config_init(ma_format_f32, 0, 0);

    if (ma_decoder_init_memory(buffer.data(), buffer.size(), &config, &decoder) != MA_SUCCESS) {
        *outSampleCount = 0;
        return nullptr;
    }

    ma_uint64 totalFrameCount;
    if (ma_decoder_get_length_in_pcm_frames(&decoder, &totalFrameCount) != MA_SUCCESS) {
        ma_decoder_uninit(&decoder);
        *outSampleCount = 0;
        return nullptr;
    }

    size_t totalSampleCount = static_cast<size_t>(totalFrameCount * decoder.outputChannels);
    float* pSampleData = static_cast<float*>(malloc(totalSampleCount * sizeof(float)));

    if (!pSampleData) {
        ma_decoder_uninit(&decoder);
        *outSampleCount = 0;
        return nullptr;
    }

    ma_uint64 framesRead;
    if (ma_decoder_read_pcm_frames(&decoder, pSampleData, totalFrameCount, &framesRead) != MA_SUCCESS) {
        free(pSampleData);
        ma_decoder_uninit(&decoder);
        *outSampleCount = 0;
        return nullptr;
    }

    *outSampleCount = framesRead * decoder.outputChannels;
    *outChannels = decoder.outputChannels;
    *outSampleRate = decoder.outputSampleRate;

    ma_decoder_uninit(&decoder);

    return pSampleData;
}

__attribute__((visibility("default")))
void free_pcm_data(float* pSampleData) {
    if (pSampleData) {
        free(pSampleData);
    }
}

}  // extern "C"
