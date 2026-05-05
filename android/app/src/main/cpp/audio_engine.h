#ifndef AUDIO_ENGINE_H
#define AUDIO_ENGINE_H

#include <SLES/OpenSLES.h>
#include <SLES/OpenSLES_Android.h>
#include <string>
#include <vector>
#include <mutex>
#include <atomic>

struct PreviewAudioClip {
    std::string id;
    std::string path;
    long startTime; // ms
    long endTime;   // ms
    float volume;
    std::vector<float> pcmData;
    bool isLoaded = false;
};

class AudioEngine {
public:
    AudioEngine();
    ~AudioEngine();

    bool init();
    void release();

    void setClips(const std::vector<PreviewAudioClip>& clips);
    void setMainAudio(const std::string& path);
    
    void start();
    void stop();
    void seek(long timeMs);
    
    long getCurrentPositionMs();
    bool isPlaying() const { return mIsPlaying; }

    // Internal callback
    void processAudio(float* buffer, int numFrames);

private:
    void setupOpenSL();
    void shutdownOpenSL();
    void loadClipPcm(PreviewAudioClip& clip);

    SLObjectItf mEngineObj = nullptr;
    SLEngineItf mEngine = nullptr;
    SLObjectItf mOutputMixObj = nullptr;
    SLObjectItf mPlayerObj = nullptr;
    SLPlayItf mPlayerPlay = nullptr;
    SLAndroidSimpleBufferQueueItf mBufferQueue = nullptr;

    std::vector<PreviewAudioClip> mClips;
    PreviewAudioClip mMainAudio;
    std::string mMainAudioPath;

    std::atomic<long> mCurrentPositionSamples{0};
    std::atomic<bool> mIsPlaying{false};
    std::mutex mClipMutex;

    static constexpr int mSampleRate = 44100;
    static constexpr int mNumChannels = 2;
    static constexpr int mBufferSizeFrames = 1024;

    float* mOutputBuffer = nullptr;
};

#endif // AUDIO_ENGINE_H
