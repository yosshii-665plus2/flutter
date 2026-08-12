#define MINIAUDIO_IMPLEMENTATION
#if defined(_MSC_VER)
#pragma warning(push, 0)
#endif
#include "miniaudio.h"
#if defined(_MSC_VER)
#pragma warning(pop)
#endif

#include <cstdint>
#include <cstdlib>
#include <windows.h>
#include <string>
#include <vector>

// UTF-8 (char*) のパスを Windows 用の UTF-16 (wchar_t*) に変換
std::wstring utf8_to_wstring(const char* str) {
    if (!str) return L"";
    int size_needed = MultiByteToWideChar(CP_UTF8, 0, str, -1, NULL, 0);
    if (size_needed <= 0) return L"";
    std::wstring wstr(size_needed, 0);
    MultiByteToWideChar(CP_UTF8, 0, str, -1, &wstr[0], size_needed);
    return wstr;
}

extern "C" {
    // MP3/WAV/FLAC等 を全自動でデコードする関数
    __declspec(dllexport) float* decode_mp3_file(
        const char* filePath, 
        uint64_t* outSampleCount, 
        uint32_t* outChannels, 
        uint32_t* outSampleRate
    ) {
        // 1. パスを UTF-16 に変換してファイルを開く
        std::wstring wPath = utf8_to_wstring(filePath);

        FILE* f = nullptr;
        if (_wfopen_s(&f, wPath.c_str(), L"rb") != 0 || !f) {
            *outSampleCount = 0;
            return nullptr;
        }

        // 2. メモリに全読み込み
        fseek(f, 0, SEEK_END);
        size_t fileSize = ftell(f);
        fseek(f, 0, SEEK_SET);

        std::vector<uint8_t> buffer(fileSize);
        size_t bytesRead = fread(buffer.data(), 1, fileSize, f);
        fclose(f);

        if (bytesRead != fileSize) {
            *outSampleCount = 0;
            return nullptr;
        }

        // 3. miniaudio デコーダーの初期化（出力フォーマットを float32 に統一）
        ma_decoder decoder;
        ma_decoder_config config = ma_decoder_config_init(ma_format_f32, 0, 0);

        if (ma_decoder_init_memory(buffer.data(), buffer.size(), &config, &decoder) != MA_SUCCESS) {
            *outSampleCount = 0;
            return nullptr;
        }

        // 4. 総フレーム数を取得
        ma_uint64 totalFrameCount;
        if (ma_decoder_get_length_in_pcm_frames(&decoder, &totalFrameCount) != MA_SUCCESS) {
            ma_decoder_uninit(&decoder);
            *outSampleCount = 0;
            return nullptr;
        }

        size_t totalSampleCount = (size_t)(totalFrameCount * decoder.outputChannels);
        float* pSampleData = (float*)malloc(totalSampleCount * sizeof(float));

        if (!pSampleData) {
            ma_decoder_uninit(&decoder);
            *outSampleCount = 0;
            return nullptr;
        }

        // 5. PCMデータ（floatリスト）への読み出し
        ma_uint64 framesRead;
        if (ma_decoder_read_pcm_frames(&decoder, pSampleData, totalFrameCount, &framesRead) != MA_SUCCESS) {
            free(pSampleData);
            ma_decoder_uninit(&decoder);
            *outSampleCount = 0;
            return nullptr;
        }

        // 6. 結果をセット
        *outSampleCount = framesRead * decoder.outputChannels;
        *outChannels = decoder.outputChannels;
        *outSampleRate = decoder.outputSampleRate;

        ma_decoder_uninit(&decoder);

        return pSampleData;
    }

    __declspec(dllexport) void free_pcm_data(float* pSampleData) {
        if (pSampleData) {
            free(pSampleData);
        }
    }
}