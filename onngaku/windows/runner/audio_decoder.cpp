#define DR_MP3_IMPLEMENTATION
#include "dr_mp3.h"
#include <cstdint>
#include <cstdlib>
#include <windows.h>
#include <string>
#include <vector>

// UTF-8 (char*) のパスを Windows 用の UTF-16 (wchar_t*) に変換する関数
std::wstring utf8_to_wstring(const char* str) {
    if (!str) return L"";
    int size_needed = MultiByteToWideChar(CP_UTF8, 0, str, -1, NULL, 0);
    if (size_needed <= 0) return L"";
    std::wstring wstr(size_needed, 0);
    MultiByteToWideChar(CP_UTF8, 0, str, -1, &wstr[0], size_needed);
    return wstr;
}

extern "C" {
    __declspec(dllexport) float* decode_mp3_file(
        const char* filePath, 
        uint64_t* outSampleCount, 
        uint32_t* outChannels, 
        uint32_t* outSampleRate
    ) {
        // 1. パスを UTF-16 に変換
        std::wstring wPath = utf8_to_wstring(filePath);

        // 2. Windows のワイド文字対応関数でファイルを開く
        FILE* f = nullptr;
        if (_wfopen_s(&f, wPath.c_str(), L"rb") != 0 || !f) {
            *outSampleCount = 0;
            return nullptr;
        }

        // 3. ファイルサイズを取得してメモリに全読み込み
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

        // 4. dr_mp3 のメモリ読み込み API を使用して PCM（float）にデコード
        drmp3_config config;
        drmp3_uint64 totalFrameCount;

        float* pSampleData = drmp3_open_memory_and_read_pcm_frames_f32(
            buffer.data(), buffer.size(), &config, &totalFrameCount, NULL
        );

        if (pSampleData == NULL) {
            *outSampleCount = 0;
            return NULL;
        }

        *outSampleCount = totalFrameCount * config.channels;
        *outChannels = config.channels;
        *outSampleRate = config.sampleRate;

        return pSampleData;
    }

    __declspec(dllexport) void free_pcm_data(float* pSampleData) {
        if (pSampleData) {
            drmp3_free(pSampleData, NULL);
        }
    }
}