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
    const int numFrames = 1024;
    
    // Use the engine's persistent float buffer for mixing
    engine->processAudio(engine->mFloatBuf, numFrames);
    
    // Pick the buffer that OpenSL is NOT currently reading
    int16_t* outBuf = (engine->mCurrentBuffer == 0) ? engine->mBufferA : engine->mBufferB;
    engine->mCurrentBuffer = 1 - engine->mCurrentBuffer;
    
    // Convert float to 16-bit PCM with proper clamping
    for (int i = 0; i < numFrames * 2; i++) {
        float sample = engine->mFloatBuf[i];
        if (sample > 1.0f) sample = 1.0f;
        if (sample < -1.0f) sample = -1.0f;
        outBuf[i] = (int16_t)(sample * 32767.0f);
    }
    
    // Enqueue the persistent buffer — it stays valid until the next callback
    (*bq)->Enqueue(bq, outBuf, numFrames * 2 * sizeof(int16_t));
}

AudioEngine::AudioEngine() {
    mMainAudio.volume = 1.0f;
    std::fill(mBufferA, mBufferA + mBufferSizeFrames * 2, 0);
    std::fill(mBufferB, mBufferB + mBufferSizeFrames * 2, 0);
    std::fill(mFloatBuf, mFloatBuf + mBufferSizeFrames * 2, 0.0f);
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
    
    // Use our persistent member buffers to prime the queue. 
    // They were zeroed in the constructor.
    (*mBufferQueue)->Enqueue(mBufferQueue, mBufferA, sizeof(mBufferA));
    (*mBufferQueue)->Enqueue(mBufferQueue, mBufferB, sizeof(mBufferB));

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

void AudioEngine::setMainAudioVolume(float volume) {
    std::lock_guard<std::mutex> lock(mClipMutex);
    mMainAudio.volume = volume;
    LOGD("Main audio volume set to: %.2f", volume);
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
        auto pcm = std::make_shared<std::vector<float>>(decodeToPcm(path.c_str(), mSampleRate));
        
        std::lock_guard<std::mutex> lock(mClipMutex);
        mMainAudioPath = path;
        mMainAudio.path = path;
        mMainAudio.pcmData = std::move(pcm);
        mMainAudio.isLoaded = !mMainAudio.pcmData->empty();
        LOGD("Main audio loaded asynchronously: %zu samples", mMainAudio.pcmData->size());
    }).detach();
}

void AudioEngine::setClips(const std::vector<PreviewAudioClip>& clips) {
    std::unique_lock<std::mutex> lock(mClipMutex);
    
    // 1. Immediately update clips that we already have (matched by ID or Path)
    // This makes volume changes feel instant
    std::vector<PreviewAudioClip> updatedClips = clips;
    bool needsDecoding = false;
    
    for (auto& newClip : updatedClips) {
        // First try to match by ID for exact property update (volume, timing)
        bool found = false;
        for (const auto& existing : mClips) {
            if (existing.id == newClip.id && existing.isLoaded) {
                newClip.pcmData = existing.pcmData; // Cheap shared_ptr copy
                newClip.isLoaded = true;
                found = true;
                break;
            }
        }
        
        // If not found by ID, try matching by Path (it might be the same file on a new track)
        if (!found) {
            for (const auto& existing : mClips) {
                if (existing.path == newClip.path && existing.isLoaded) {
                    newClip.pcmData = existing.pcmData;
                    newClip.isLoaded = true;
                    found = true;
                    break;
                }
            }
        }
        
        if (!found && !newClip.path.empty()) {
            needsDecoding = true;
        }
    }
    
    // Apply the updates immediately
    mClips = updatedClips;
    
    if (needsDecoding) {
        // Spawn a thread ONLY if we need to decode new files
        std::thread([this]() {
            std::unique_lock<std::mutex> threadLock(mClipMutex);
            std::vector<PreviewAudioClip> backgroundClips = mClips; // Copy current state
            threadLock.unlock();
            
            bool changed = false;
            for (auto& clip : backgroundClips) {
                if (!clip.isLoaded && !clip.path.empty()) {
                    LOGD("Decoding clip asynchronously: %s", clip.path.c_str());
                    clip.pcmData = std::make_shared<std::vector<float>>(decodeToPcm(clip.path.c_str(), mSampleRate));
                    clip.isLoaded = !clip.pcmData->empty();
                    changed = true;
                }
            }
            
            if (changed) {
                threadLock.lock();
                // Merge loaded data back into mClips
                for (auto& clip : backgroundClips) {
                    if (clip.isLoaded) {
                        for (auto& target : mClips) {
                            if (target.id == clip.id) {
                                target.pcmData = clip.pcmData;
                                target.isLoaded = true;
                            }
                        }
                    }
                }
                LOGD("Clips background decoding finished.");
            }
        }).detach();
    }
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
    
    // Main audio is now mixed via the mClips loop below if it's in the tracks,
    // so we don't mix it here to avoid double-mixing and distortion.

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
                    if (clip.pcmData && pcmIdx + 1 < clip.pcmData->size()) {
                        float vol = clip.volume;
                        buffer[i * 2] += (*clip.pcmData)[pcmIdx] * vol;
                        buffer[i * 2 + 1] += (*clip.pcmData)[pcmIdx + 1] * vol;
                    }
                }
            }
        }
    }

    mCurrentPositionSamples += numFrames;
}
