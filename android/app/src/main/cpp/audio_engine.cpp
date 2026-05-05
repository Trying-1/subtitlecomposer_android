#include "audio_engine.h"
#include <android/log.h>
#include <algorithm>
#include <cmath>

extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libswresample/swresample.h>
#include <libavutil/opt.h>
}

#define LOG_TAG "AudioEngine"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// Helper to decode audio (reused from native-lib.cpp logic)
std::vector<float> decodeToPcm(const char* path, int targetSampleRate) {
    AVFormatContext* fmt_ctx = nullptr;
    if (avformat_open_input(&fmt_ctx, path, nullptr, nullptr) < 0) return {};
    if (avformat_find_stream_info(fmt_ctx, nullptr) < 0) {
        avformat_close_input(&fmt_ctx);
        return {};
    }

    int stream_idx = -1;
    for (int i = 0; i < fmt_ctx->nb_streams; i++) {
        if (fmt_ctx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
            stream_idx = i;
            break;
        }
    }
    if (stream_idx == -1) {
        avformat_close_input(&fmt_ctx);
        return {};
    }

    AVCodecParameters* codecpar = fmt_ctx->streams[stream_idx]->codecpar;
    const AVCodec* codec = avcodec_find_decoder(codecpar->codec_id);
    AVCodecContext* codec_ctx = avcodec_alloc_context3(codec);
    avcodec_parameters_to_context(codec_ctx, codecpar);
    avcodec_open2(codec_ctx, codec, nullptr);

    AVChannelLayout out_ch_layout;
    av_channel_layout_default(&out_ch_layout, 2); // Stereo

    SwrContext* swr_ctx = nullptr;
    swr_alloc_set_opts2(&swr_ctx, &out_ch_layout, AV_SAMPLE_FMT_FLT, targetSampleRate,
                        &codec_ctx->ch_layout, codec_ctx->sample_fmt, codec_ctx->sample_rate, 0, nullptr);
    swr_init(swr_ctx);

    AVFrame* frame = av_frame_alloc();
    AVPacket pkt;
    std::vector<float> pcm;

    while (av_read_frame(fmt_ctx, &pkt) >= 0) {
        if (pkt.stream_index == stream_idx) {
            if (avcodec_send_packet(codec_ctx, &pkt) == 0) {
                while (avcodec_receive_frame(codec_ctx, frame) == 0) {
                    int out_samples = av_rescale_rnd(swr_get_delay(swr_ctx, codec_ctx->sample_rate) + frame->nb_samples, targetSampleRate, codec_ctx->sample_rate, AV_ROUND_UP);
                    float* buf = (float*)av_malloc(out_samples * 2 * sizeof(float));
                    uint8_t* out_data[1] = {(uint8_t*)buf};
                    int converted = swr_convert(swr_ctx, out_data, out_samples, (const uint8_t**)frame->data, frame->nb_samples);
                    if (converted > 0) {
                        pcm.insert(pcm.end(), buf, buf + converted * 2);
                    }
                    av_free(buf);
                }
            }
        }
        av_packet_unref(&pkt);
    }

    av_frame_free(&frame);
    swr_free(&swr_ctx);
    avcodec_free_context(&codec_ctx);
    avformat_close_input(&fmt_ctx);
    return pcm;
}

#include <thread>
#include <queue>
#include <condition_variable>

static void bqPlayerCallback(SLAndroidSimpleBufferQueueItf bq, void *context) {
    AudioEngine* engine = (AudioEngine*)context;
    const int numFrames = 1024; // Match mBufferSizeFrames
    float floatBuf[numFrames * 2]; 
    int16_t outBuf[numFrames * 2];
    
    engine->processAudio(floatBuf, numFrames);
    
    // Convert float to 16-bit PCM
    for (int i = 0; i < numFrames * 2; i++) {
        float sample = floatBuf[i];
        if (sample > 1.0f) sample = 1.0f;
        if (sample < -1.0f) sample = -1.0f;
        outBuf[i] = (int16_t)(sample * 32767.0f);
    }
    
    (*bq)->Enqueue(bq, outBuf, numFrames * 2 * sizeof(int16_t));
}

AudioEngine::AudioEngine() {
}

AudioEngine::~AudioEngine() {
    release();
}

bool AudioEngine::init() {
    setupOpenSL();
    return true;
}

void AudioEngine::release() {
    shutdownOpenSL();
}

void AudioEngine::setupOpenSL() {
    SLresult result;

    result = slCreateEngine(&mEngineObj, 0, nullptr, 0, nullptr, nullptr);
    (*mEngineObj)->Realize(mEngineObj, SL_BOOLEAN_FALSE);
    (*mEngineObj)->GetInterface(mEngineObj, SL_IID_ENGINE, &mEngine);

    result = (*mEngine)->CreateOutputMix(mEngine, &mOutputMixObj, 0, nullptr, nullptr);
    (*mOutputMixObj)->Realize(mOutputMixObj, SL_BOOLEAN_FALSE);

    SLDataLocator_AndroidSimpleBufferQueue loc_bufq = {SL_DATALOCATOR_ANDROIDSIMPLEBUFFERQUEUE, 2};
    SLDataFormat_PCM format_pcm = {
        SL_DATAFORMAT_PCM,
        2,
        SL_SAMPLINGRATE_44_1,
        SL_PCMSAMPLEFORMAT_FIXED_16,
        SL_PCMSAMPLEFORMAT_FIXED_16,
        SL_SPEAKER_FRONT_LEFT | SL_SPEAKER_FRONT_RIGHT,
        SL_BYTEORDER_LITTLEENDIAN
    };
    
    SLDataLocator_OutputMix loc_outmix = {SL_DATALOCATOR_OUTPUTMIX, mOutputMixObj};
    SLDataSource audioSrc = {&loc_bufq, &format_pcm};
    SLDataSink audioSnk = {&loc_outmix, nullptr};

    const SLInterfaceID ids[1] = {SL_IID_ANDROIDSIMPLEBUFFERQUEUE};
    const SLboolean req[1] = {SL_BOOLEAN_TRUE};
    
    result = (*mEngine)->CreateAudioPlayer(mEngine, &mPlayerObj, &audioSrc, &audioSnk, 1, ids, req);
    (*mPlayerObj)->Realize(mPlayerObj, SL_BOOLEAN_FALSE);

    (*mPlayerObj)->GetInterface(mPlayerObj, SL_IID_PLAY, &mPlayerPlay);
    (*mPlayerObj)->GetInterface(mPlayerObj, SL_IID_ANDROIDSIMPLEBUFFERQUEUE, &mBufferQueue);

    (*mBufferQueue)->RegisterCallback(mBufferQueue, bqPlayerCallback, this);
    
    int16_t silence[mBufferSizeFrames * 2] = {0};
    (*mBufferQueue)->Enqueue(mBufferQueue, silence, sizeof(silence));
    (*mBufferQueue)->Enqueue(mBufferQueue, silence, sizeof(silence));

    (*mPlayerPlay)->SetPlayState(mPlayerPlay, SL_PLAYSTATE_PLAYING);
}

void AudioEngine::shutdownOpenSL() {
    if (mPlayerObj) {
        (*mPlayerPlay)->SetPlayState(mPlayerPlay, SL_PLAYSTATE_STOPPED);
        (*mPlayerObj)->Destroy(mPlayerObj);
        mPlayerObj = nullptr;
    }
    if (mOutputMixObj) {
        (*mOutputMixObj)->Destroy(mOutputMixObj);
        mOutputMixObj = nullptr;
    }
    if (mEngineObj) {
        (*mEngineObj)->Destroy(mEngineObj);
        mEngineObj = nullptr;
    }
}

void AudioEngine::setMainAudio(const std::string& path) {
    std::thread([this, path]() {
        if (path.empty()) {
            std::lock_guard<std::mutex> lock(mClipMutex);
            mMainAudio.isLoaded = false;
            mMainAudioPath = "";
            return;
        }
        
        LOGD("Decoding main audio asynchronously: %s", path.c_str());
        auto pcm = decodeToPcm(path.c_str(), mSampleRate);
        
        std::lock_guard<std::mutex> lock(mClipMutex);
        mMainAudioPath = path;
        mMainAudio.path = path;
        mMainAudio.pcmData = std::move(pcm);
        mMainAudio.isLoaded = !mMainAudio.pcmData.empty();
        LOGD("Main audio loaded asynchronously: %zu samples", mMainAudio.pcmData.size());
    }).detach();
}

void AudioEngine::setClips(const std::vector<PreviewAudioClip>& clips) {
    // We need to decode missing ones in background
    std::thread([this, clips]() {
        std::vector<PreviewAudioClip> updatedClips = clips;
        for (auto& clip : updatedClips) {
            // Check if we already have this clip loaded (basic cache)
            bool found = false;
            {
                std::lock_guard<std::mutex> lock(mClipMutex);
                for (const auto& existing : mClips) {
                    if (existing.path == clip.path && existing.isLoaded) {
                        clip.pcmData = existing.pcmData;
                        clip.isLoaded = true;
                        found = true;
                        break;
                    }
                }
            }

            if (!found && !clip.path.empty()) {
                LOGD("Decoding clip asynchronously: %s", clip.path.c_str());
                clip.pcmData = decodeToPcm(clip.path.c_str(), mSampleRate);
                clip.isLoaded = !clip.pcmData.empty();
            }
        }

        std::lock_guard<std::mutex> lock(mClipMutex);
        mClips = std::move(updatedClips);
        LOGD("Clips updated asynchronously: %zu clips", mClips.size());
    }).detach();
}

void AudioEngine::start() {
    mIsPlaying = true;
}

void AudioEngine::stop() {
    mIsPlaying = false;
}

void AudioEngine::seek(long timeMs) {
    mCurrentPositionSamples = (timeMs * mSampleRate) / 1000;
}

long AudioEngine::getCurrentPositionMs() {
    return (mCurrentPositionSamples * 1000) / mSampleRate;
}

void AudioEngine::processAudio(float* buffer, int numFrames) {
    std::fill(buffer, buffer + numFrames * 2, 0.0f);

    if (!mIsPlaying) return;

    // Use try_lock to avoid blocking the audio thread
    // If we can't get the lock, we just skip this buffer (causes a tiny gap, 
    // but better than a massive hitch or crash)
    std::unique_lock<std::mutex> lock(mClipMutex, std::try_to_lock);
    if (!lock.owns_lock()) {
        // Just advance the clock and return silence to keep sync
        mCurrentPositionSamples += numFrames;
        return;
    }
    
    long currentSamples = mCurrentPositionSamples.load();

    if (mMainAudio.isLoaded) {
        size_t startIdx = currentSamples * 2;
        size_t endIdx = startIdx + numFrames * 2;
        
        for (int i = 0; i < numFrames * 2; i++) {
            size_t idx = startIdx + i;
            if (idx < mMainAudio.pcmData.size()) {
                buffer[i] += mMainAudio.pcmData[idx];
            }
        }
    }

    for (const auto& clip : mClips) {
        if (!clip.isLoaded) continue;

        long clipStartSample = (clip.startTime * mSampleRate) / 1000;
        long clipEndSample = (clip.endTime * mSampleRate) / 1000;

        if (currentSamples + numFrames > clipStartSample && currentSamples < clipEndSample) {
            for (int i = 0; i < numFrames; i++) {
                long absoluteSample = currentSamples + i;
                if (absoluteSample >= clipStartSample && absoluteSample < clipEndSample) {
                    long relativeSample = absoluteSample - clipStartSample;
                    size_t pcmIdx = relativeSample * 2;
                    if (pcmIdx + 1 < clip.pcmData.size()) {
                        buffer[i * 2] += clip.pcmData[pcmIdx] * clip.volume;
                        buffer[i * 2 + 1] += clip.pcmData[pcmIdx + 1] * clip.volume;
                    }
                }
            }
        }
    }

    mCurrentPositionSamples += numFrames;
}
