#include <jni.h>
#include <string>
#include <vector>
#include <android/log.h>
#include "whisper.h"

extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libswresample/swresample.h>
#include <libavutil/opt.h>
#include <libavutil/channel_layout.h>
}

#define LOG_TAG "WhisperNative"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

#define FFMPEG_TAG "FFmpegNative"
#define FFLOGD(...) __android_log_print(ANDROID_LOG_DEBUG, FFMPEG_TAG, __VA_ARGS__)
#define FFLOGE(...) __android_log_print(ANDROID_LOG_ERROR, FFMPEG_TAG, __VA_ARGS__)

// --- Audio Decoding Helper ---

static bool decode_audio_to_pcm(const char *path, std::vector<float> &pcm) {
    AVFormatContext *fmt_ctx = nullptr;
    FFLOGD("Opening input file: %s", path);
    if (avformat_open_input(&fmt_ctx, path, nullptr, nullptr) < 0) {
        FFLOGE("Failed to open input file: %s", path);
        return false;
    }
    if (avformat_find_stream_info(fmt_ctx, nullptr) < 0) {
        FFLOGE("Failed to find stream info");
        avformat_close_input(&fmt_ctx);
        return false;
    }

    int stream_index = av_find_best_stream(fmt_ctx, AVMEDIA_TYPE_AUDIO, -1, -1, nullptr, 0);
    if (stream_index < 0) {
        FFLOGE("Failed to find audio stream");
        avformat_close_input(&fmt_ctx);
        return false;
    }

    FFLOGD("Found audio stream at index %d", stream_index);
    AVStream *stream = fmt_ctx->streams[stream_index];
    const AVCodec *codec = avcodec_find_decoder(stream->codecpar->codec_id);
    if (!codec) {
        FFLOGE("Failed to find decoder for codec ID %d", stream->codecpar->codec_id);
        avformat_close_input(&fmt_ctx);
        return false;
    }

    AVCodecContext *codec_ctx = avcodec_alloc_context3(codec);
    avcodec_parameters_to_context(codec_ctx, stream->codecpar);
    if (avcodec_open2(codec_ctx, codec, nullptr) < 0) {
        FFLOGE("Failed to open codec");
        avcodec_free_context(&codec_ctx);
        avformat_close_input(&fmt_ctx);
        return false;
    }

    SwrContext *swr_ctx = swr_alloc();
    av_opt_set_chlayout(swr_ctx, "in_chlayout", &codec_ctx->ch_layout, 0);
    av_opt_set_int(swr_ctx, "in_sample_rate", codec_ctx->sample_rate, 0);
    av_opt_set_sample_fmt(swr_ctx, "in_sample_fmt", codec_ctx->sample_fmt, 0);

    AVChannelLayout out_ch_layout;
    av_channel_layout_default(&out_ch_layout, 1); // Mono
    av_opt_set_chlayout(swr_ctx, "out_chlayout", &out_ch_layout, 0);
    av_opt_set_int(swr_ctx, "out_sample_rate", 16000, 0);
    av_opt_set_sample_fmt(swr_ctx, "out_sample_fmt", AV_SAMPLE_FMT_FLT, 0);

    if (swr_init(swr_ctx) < 0) {
        swr_free(&swr_ctx);
        avcodec_free_context(&codec_ctx);
        avformat_close_input(&fmt_ctx);
        return false;
    }

    AVPacket *pkt = av_packet_alloc();
    AVFrame *frame = av_frame_alloc();
    
    FFLOGD("Starting decoding loop...");
    int total_samples = 0;
    while (av_read_frame(fmt_ctx, pkt) >= 0) {
        if (pkt->stream_index == stream_index) {
            if (avcodec_send_packet(codec_ctx, pkt) == 0) {
                while (avcodec_receive_frame(codec_ctx, frame) == 0) {
                    float *out_buffer = nullptr;
                    int out_samples = swr_get_out_samples(swr_ctx, frame->nb_samples);
                    av_samples_alloc((uint8_t **)&out_buffer, nullptr, 1, out_samples, AV_SAMPLE_FMT_FLT, 0);
                    int converted = swr_convert(swr_ctx, (uint8_t **)&out_buffer, out_samples, (const uint8_t **)frame->data, frame->nb_samples);
                    if (converted > 0) {
                        pcm.insert(pcm.end(), out_buffer, out_buffer + converted);
                        total_samples += converted;
                    }
                    av_freep(&out_buffer);
                }
            }
        }
        av_packet_unref(pkt);
    }
    FFLOGD("Decoding finished. Total samples: %d", total_samples);

    av_frame_free(&frame);
    av_packet_free(&pkt);
    swr_free(&swr_ctx);
    avcodec_free_context(&codec_ctx);
    avformat_close_input(&fmt_ctx);

    return true;
}

static std::string escape_json(const std::string &s) {
    std::string out;
    for (auto c : s) {
        if (c == '"') out += "\\\"";
        else if (c == '\\') out += "\\\\";
        else if (c == '\b') out += "\\b";
        else if (c == '\f') out += "\\f";
        else if (c == '\n') out += "\\n";
        else if (c == '\r') out += "\\r";
        else if (c == '\t') out += "\\t";
        else if (static_cast<unsigned char>(c) < 32) {
            char buf[10];
            snprintf(buf, sizeof(buf), "\\u%04x", c);
            out += buf;
        } else {
            out += c;
        }
    }
    return out;
}

// --- Whisper JNI Implementation ---

extern "C"
JNIEXPORT jlong JNICALL
Java_com_typography_MainActivity_initWhisper(JNIEnv *env, jobject thiz, jstring model_path) {
    const char *path = env->GetStringUTFChars(model_path, nullptr);
    struct whisper_context_params cparams = whisper_context_default_params();
    cparams.use_gpu = false; 
    struct whisper_context * ctx = whisper_init_from_file_with_params(path, cparams);
    env->ReleaseStringUTFChars(model_path, path);
    return reinterpret_cast<jlong>(ctx);
}

extern "C"
JNIEXPORT jstring JNICALL
Java_com_typography_MainActivity_transcribeWhisper(
        JNIEnv *env, jobject thiz, jlong context_ptr, jstring audio_path, jstring initial_prompt, jstring language) {
    
    struct whisper_context * ctx = reinterpret_cast<struct whisper_context *>(context_ptr);
    if (!ctx) return env->NewStringUTF("{ \"error\": \"invalid context\" }");

    const char *path = env->GetStringUTFChars(audio_path, nullptr);
    const char *prompt = env->GetStringUTFChars(initial_prompt, nullptr);
    const char *lang = env->GetStringUTFChars(language, nullptr);
    
    std::vector<float> pcm;
    if (!decode_audio_to_pcm(path, pcm)) {
        env->ReleaseStringUTFChars(audio_path, path);
        env->ReleaseStringUTFChars(initial_prompt, prompt);
        env->ReleaseStringUTFChars(language, lang);
        return env->NewStringUTF("{ \"error\": \"failed to decode audio\" }");
    }

    whisper_full_params params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
    params.n_threads = 4;
    params.language = (strcmp(lang, "auto") == 0) ? nullptr : lang;
    params.initial_prompt = prompt;
    params.token_timestamps = true;
    params.split_on_word = true; 
    params.max_len = 1; 

    FFLOGD("Starting transcription with lang: %s, threads: %d", (lang ? lang : "auto"), params.n_threads);
    if (whisper_full(ctx, params, pcm.data(), pcm.size()) != 0) {
        FFLOGE("Whisper processing failed!");
        env->ReleaseStringUTFChars(audio_path, path);
        env->ReleaseStringUTFChars(initial_prompt, prompt);
        env->ReleaseStringUTFChars(language, lang);
        return env->NewStringUTF("{ \"error\": \"whisper processing failed\" }");
    }

    std::string json = "[";
    const int n_segments = whisper_full_n_segments(ctx);
    FFLOGD("Transcription finished. Generated %d segments.", n_segments);
    for (int i = 0; i < n_segments; ++i) {
        const char * text = whisper_full_get_segment_text(ctx, i);
        const int64_t t0 = whisper_full_get_segment_t0(ctx, i);
        const int64_t t1 = whisper_full_get_segment_t1(ctx, i);

        // Skip empty or special segments (like [vocalized_noise])
        if (text == nullptr || strlen(text) == 0) continue;
        if (text[0] == '[' && text[strlen(text)-1] == ']') continue;

        if (json.length() > 1) json += ",";
        json += "{";
        json += "\"start\":" + std::to_string(t0 * 10) + ",";
        json += "\"end\":" + std::to_string(t1 * 10) + ",";
        json += "\"text\":\"" + escape_json(text) + "\"";
        json += "}";
    }
    json += "]";

    env->ReleaseStringUTFChars(audio_path, path);
    env->ReleaseStringUTFChars(initial_prompt, prompt);
    env->ReleaseStringUTFChars(language, lang);
    
    return env->NewStringUTF(json.c_str());
}

extern "C"
JNIEXPORT void JNICALL
Java_com_typography_MainActivity_freeWhisper(JNIEnv *env, jobject thiz, jlong context_ptr) {
    struct whisper_context * ctx = reinterpret_cast<struct whisper_context *>(context_ptr);
    if (ctx) whisper_free(ctx);
}
