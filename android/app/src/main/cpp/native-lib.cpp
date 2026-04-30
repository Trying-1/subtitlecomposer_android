#include <jni.h>
#include <string>
#include <vector>
#include <algorithm>
#include <android/log.h>

extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libswscale/swscale.h>
#include <libswresample/swresample.h>
#include <libavutil/imgutils.h>
#include <libavutil/timestamp.h>
#include <libavutil/channel_layout.h>
}

#include <android/bitmap.h>

#include <android/bitmap.h>
#include <GLES2/gl2.h>

#define LOG_TAG "FFmpegNative"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

class FFmpegFrameExtractor {
public:
    AVFormatContext* fmt_ctx = nullptr;
    AVCodecContext* codec_ctx = nullptr;
    int video_stream_idx = -1;
    AVFrame* frame = nullptr;
    uint8_t* buffer = nullptr;
    struct SwsContext* sws_ctx = nullptr;
    std::string path;
    int64_t last_pts = -1;

    FFmpegFrameExtractor(const char* p) : path(p) {}

    bool init() {
        if (avformat_open_input(&fmt_ctx, path.c_str(), nullptr, nullptr) < 0) return false;
        if (avformat_find_stream_info(fmt_ctx, nullptr) < 0) return false;

        for (int i = 0; i < fmt_ctx->nb_streams; i++) {
            if (fmt_ctx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
                video_stream_idx = i;
                break;
            }
        }
        if (video_stream_idx == -1) return false;

        AVCodecParameters* codecpar = fmt_ctx->streams[video_stream_idx]->codecpar;
        const AVCodec* codec = avcodec_find_decoder(codecpar->codec_id);
        if (!codec) return false;

        codec_ctx = avcodec_alloc_context3(codec);
        avcodec_parameters_to_context(codec_ctx, codecpar);
        if (avcodec_open2(codec_ctx, codec, nullptr) < 0) return false;

        frame = av_frame_alloc();
        return true;
    }

    bool updateTexture(int64_t time_ms, int texture_id, int width, int height) {
        if (video_stream_idx == -1) return false;

        AVStream* stream = fmt_ctx->streams[video_stream_idx];
        int64_t target_pts = av_rescale_q(time_ms, {1, 1000}, stream->time_base);

        bool need_seek = (last_pts == -1) || 
                         (target_pts < last_pts) || 
                         (target_pts - last_pts > stream->time_base.den / stream->time_base.num);

        if (need_seek) {
            if (avformat_seek_file(fmt_ctx, video_stream_idx, INT64_MIN, target_pts, target_pts, 0) < 0) {
                LOGE("Seek failed for %lld ms", (long long)time_ms);
            }
            avcodec_flush_buffers(codec_ctx);
            last_pts = -1;
        }

        AVPacket pkt;
        bool found = false;
        int max_retries = need_seek ? 100 : 20;

        while (max_retries-- > 0 && av_read_frame(fmt_ctx, &pkt) >= 0) {
            if (pkt.stream_index == video_stream_idx) {
                if (avcodec_send_packet(codec_ctx, &pkt) == 0) {
                    while (avcodec_receive_frame(codec_ctx, frame) == 0) {
                        last_pts = frame->pts;
                        if (frame->pts >= target_pts) {
                            found = true;
                            break;
                        }
                    }
                }
            }
            av_packet_unref(&pkt);
            if (found) break;
        }

        if (found) {
            // Re-allocate buffer if needed
            int buffer_size = av_image_get_buffer_size(AV_PIX_FMT_RGBA, width, height, 1);
            if (!buffer) buffer = (uint8_t*)av_malloc(buffer_size);

            sws_ctx = sws_getCachedContext(sws_ctx,
                frame->width, frame->height, codec_ctx->pix_fmt,
                width, height, AV_PIX_FMT_RGBA,
                SWS_FAST_BILINEAR, nullptr, nullptr, nullptr);

            uint8_t* dest[4] = {buffer, nullptr, nullptr, nullptr};
            int dest_linesize[4] = {width * 4, 0, 0, 0};
            sws_scale(sws_ctx, frame->data, frame->linesize, 0, frame->height, dest, dest_linesize);

            // Upload directly to texture
            glBindTexture(GL_TEXTURE_2D, texture_id);
            glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
        }

        return found;
    }

    ~FFmpegFrameExtractor() {
        if (sws_ctx) sws_freeContext(sws_ctx);
        if (frame) av_frame_free(&frame);
        if (codec_ctx) avcodec_free_context(&codec_ctx);
        if (fmt_ctx) avformat_close_input(&fmt_ctx);
        if (buffer) av_free(buffer);
    }
};

extern "C"
JNIEXPORT jlong JNICALL
Java_com_example_typgraphyeditor_VideoFrameDecoder_nativeInit(JNIEnv *env, jobject thiz, jstring path) {
    const char *p = env->GetStringUTFChars(path, nullptr);
    auto* extractor = new FFmpegFrameExtractor(p);
    if (!extractor->init()) {
        delete extractor;
        env->ReleaseStringUTFChars(path, p);
        return 0;
    }
    env->ReleaseStringUTFChars(path, p);
    return reinterpret_cast<jlong>(extractor);
}

extern "C"
JNIEXPORT jboolean JNICALL
Java_com_example_typgraphyeditor_VideoFrameDecoder_nativeUpdateTexture(JNIEnv *env, jobject thiz, jlong handle, jlong time_ms, jint texture_id, jint width, jint height) {
    auto* extractor = reinterpret_cast<FFmpegFrameExtractor*>(handle);
    if (!extractor) return JNI_FALSE;
    return extractor->updateTexture(time_ms, texture_id, width, height) ? JNI_TRUE : JNI_FALSE;
}

extern "C"
JNIEXPORT jint JNICALL
Java_com_example_typgraphyeditor_VideoFrameDecoder_nativeGetWidth(JNIEnv *env, jobject thiz, jlong handle) {
    auto* extractor = reinterpret_cast<FFmpegFrameExtractor*>(handle);
    return extractor && extractor->codec_ctx ? extractor->codec_ctx->width : 0;
}

extern "C"
JNIEXPORT jint JNICALL
Java_com_example_typgraphyeditor_VideoFrameDecoder_nativeGetHeight(JNIEnv *env, jobject thiz, jlong handle) {
    auto* extractor = reinterpret_cast<FFmpegFrameExtractor*>(handle);
    return extractor && extractor->codec_ctx ? extractor->codec_ctx->height : 0;
}

extern "C"
JNIEXPORT void JNICALL
Java_com_example_typgraphyeditor_VideoFrameDecoder_nativeRelease(JNIEnv *env, jobject thiz, jlong handle) {
    auto* extractor = reinterpret_cast<FFmpegFrameExtractor*>(handle);
    delete extractor;
}

// Keep the previous muxVideoAudio and extractAudio methods...
struct NativeAudioClip {
    std::string path;
    long startTime;
    long endTime;
    float volume;
};

// Helper to decode an audio file into a PCM buffer (Float, 44100Hz, Stereo)
std::vector<float> decodeAudioFile(const char* path, int targetSampleRate = 44100) {
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

extern "C"
JNIEXPORT jint JNICALL
Java_com_example_typgraphyeditor_MainActivity_muxVideoAudio(
        JNIEnv *env,
        jobject thiz,
        jstring video_path,
        jstring audio_path,
        jstring output_path,
        jobjectArray paths_obj,
        jlongArray starts_obj,
        jlongArray ends_obj,
        jfloatArray vols_obj) {

    const char *in_v = env->GetStringUTFChars(video_path, nullptr);
    const char *in_a = env->GetStringUTFChars(audio_path, nullptr);
    const char *out = env->GetStringUTFChars(output_path, nullptr);

    // Parse audio tracks from flat arrays
    int clips_count = env->GetArrayLength(paths_obj);
    jlong *starts = env->GetLongArrayElements(starts_obj, nullptr);
    jlong *ends = env->GetLongArrayElements(ends_obj, nullptr);
    jfloat *vols = env->GetFloatArrayElements(vols_obj, nullptr);

    std::vector<NativeAudioClip> clips;
    for (int i = 0; i < clips_count; i++) {
        jstring path_str = (jstring)env->GetObjectArrayElement(paths_obj, i);
        const char *path_c = env->GetStringUTFChars(path_str, nullptr);
        clips.push_back({path_c, (long)starts[i], (long)ends[i], vols[i]});
        env->ReleaseStringUTFChars(path_str, path_c);
    }

    env->ReleaseLongArrayElements(starts_obj, starts, JNI_ABORT);
    env->ReleaseLongArrayElements(ends_obj, ends, JNI_ABORT);
    env->ReleaseFloatArrayElements(vols_obj, vols, JNI_ABORT);

    LOGD("Multi-track mixing starting: V=%s, Clips=%zu", in_v, clips.size());

    // 1. Get video duration
    AVFormatContext* v_fmt_ctx = nullptr;
    avformat_open_input(&v_fmt_ctx, in_v, nullptr, nullptr);
    avformat_find_stream_info(v_fmt_ctx, nullptr);
    int64_t duration_ms = v_fmt_ctx->duration / 1000;
    int video_stream_idx = -1;
    for (int i = 0; i < v_fmt_ctx->nb_streams; i++) {
        if (v_fmt_ctx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            video_stream_idx = i;
            break;
        }
    }

    // 2. Mix audio into a single PCM buffer
    int sample_rate = 44100;
    size_t total_samples = (size_t)((duration_ms / 1000.0) * sample_rate);
    std::vector<float> mixed_pcm(total_samples * 2, 0.0f);

    // Mix Main Audio if exists
    if (strlen(in_a) > 0) {
        std::vector<float> main_pcm = decodeAudioFile(in_a, sample_rate);
        size_t to_copy = std::min(mixed_pcm.size(), main_pcm.size());
        for (size_t i = 0; i < to_copy; i++) mixed_pcm[i] += main_pcm[i];
    }

    // Mix supplementary clips
    for (const auto& clip : clips) {
        std::vector<float> clip_pcm = decodeAudioFile(clip.path.c_str(), sample_rate);
        size_t start_idx = (size_t)((clip.startTime / 1000.0) * sample_rate) * 2;
        for (size_t i = 0; i < clip_pcm.size() && (start_idx + i) < mixed_pcm.size(); i++) {
            mixed_pcm[start_idx + i] += clip_pcm[i] * clip.volume;
        }
    }

    // 3. Setup output file
    AVFormatContext* ofmt_ctx = nullptr;
    avformat_alloc_output_context2(&ofmt_ctx, nullptr, nullptr, out);
    
    // Copy video stream
    AVStream* out_v_stream = avformat_new_stream(ofmt_ctx, nullptr);
    avcodec_parameters_copy(out_v_stream->codecpar, v_fmt_ctx->streams[video_stream_idx]->codecpar);
    out_v_stream->codecpar->codec_tag = 0;

    // Create audio stream and encoder
    const AVCodec* a_codec = avcodec_find_encoder(AV_CODEC_ID_AAC);
    AVStream* out_a_stream = avformat_new_stream(ofmt_ctx, nullptr);
    AVCodecContext* a_enc_ctx = avcodec_alloc_context3(a_codec);
    a_enc_ctx->sample_fmt = a_codec->sample_fmts[0];
    a_enc_ctx->bit_rate = 128000;
    a_enc_ctx->sample_rate = sample_rate;
    av_channel_layout_default(&a_enc_ctx->ch_layout, 2);
    avcodec_open2(a_enc_ctx, a_codec, nullptr);
    avcodec_parameters_from_context(out_a_stream->codecpar, a_enc_ctx);

    if (!(ofmt_ctx->oformat->flags & AVFMT_NOFILE)) {
        avio_open(&ofmt_ctx->pb, out, AVIO_FLAG_WRITE);
    }
    if (avformat_write_header(ofmt_ctx, nullptr) < 0) {
        LOGE("Could not write header to output file");
    }

    // Write Video packets
    AVPacket pkt;
    while (av_read_frame(v_fmt_ctx, &pkt) >= 0) {
        if (pkt.stream_index == video_stream_idx) {
            pkt.stream_index = out_v_stream->index;
            av_packet_rescale_ts(&pkt, v_fmt_ctx->streams[video_stream_idx]->time_base, out_v_stream->time_base);
            av_interleaved_write_frame(ofmt_ctx, &pkt);
        }
        av_packet_unref(&pkt);
    }

    // Write Mixed Audio
    SwrContext* resample_ctx = nullptr;
    swr_alloc_set_opts2(&resample_ctx, &a_enc_ctx->ch_layout, a_enc_ctx->sample_fmt, sample_rate,
                        &a_enc_ctx->ch_layout, AV_SAMPLE_FMT_FLT, sample_rate, 0, nullptr);
    swr_init(resample_ctx);

    AVFrame* a_frame = av_frame_alloc();
    a_frame->nb_samples = a_enc_ctx->frame_size;
    a_frame->format = a_enc_ctx->sample_fmt;
    av_channel_layout_copy(&a_frame->ch_layout, &a_enc_ctx->ch_layout);
    av_frame_get_buffer(a_frame, 0);

    size_t pcm_offset = 0;
    int64_t next_pts = 0;
    while (pcm_offset < mixed_pcm.size()) {
        int nb_samples = std::min((int)a_enc_ctx->frame_size, (int)((mixed_pcm.size() - pcm_offset) / 2));
        if (nb_samples <= 0) break;

        const float* src_data[1] = {&mixed_pcm[pcm_offset]};
        swr_convert(resample_ctx, a_frame->data, a_enc_ctx->frame_size, (const uint8_t**)src_data, nb_samples);
        
        a_frame->pts = next_pts;
        next_pts += nb_samples;
        
        if (avcodec_send_frame(a_enc_ctx, a_frame) == 0) {
            while (avcodec_receive_packet(a_enc_ctx, &pkt) == 0) {
                pkt.stream_index = out_a_stream->index;
                av_packet_rescale_ts(&pkt, {1, sample_rate}, out_a_stream->time_base);
                av_interleaved_write_frame(ofmt_ctx, &pkt);
                av_packet_unref(&pkt);
            }
        }
        pcm_offset += nb_samples * 2;
    }

    // Flush encoder
    avcodec_send_frame(a_enc_ctx, nullptr);
    while (avcodec_receive_packet(a_enc_ctx, &pkt) == 0) {
        pkt.stream_index = out_a_stream->index;
        av_packet_rescale_ts(&pkt, {1, sample_rate}, out_a_stream->time_base);
        av_interleaved_write_frame(ofmt_ctx, &pkt);
        av_packet_unref(&pkt);
    }

    av_write_trailer(ofmt_ctx);

    // Cleanup
    av_frame_free(&a_frame);
    swr_free(&resample_ctx);
    avcodec_free_context(&a_enc_ctx);
    avformat_close_input(&v_fmt_ctx);
    if (!(ofmt_ctx->oformat->flags & AVFMT_NOFILE)) avio_closep(&ofmt_ctx->pb);
    avformat_free_context(ofmt_ctx);

    env->ReleaseStringUTFChars(video_path, in_v);
    env->ReleaseStringUTFChars(audio_path, in_a);
    env->ReleaseStringUTFChars(output_path, out);

    return 0;
}

extern "C"
JNIEXPORT jint JNICALL
Java_com_example_typgraphyeditor_MainActivity_extractAudio(
        JNIEnv *env,
        jobject thiz,
        jstring video_path,
        jstring output_path) {

    const char *in_v = env->GetStringUTFChars(video_path, nullptr);
    const char *out = env->GetStringUTFChars(output_path, nullptr);

    AVFormatContext *ifmt_ctx = nullptr, *ofmt_ctx = nullptr;
    AVPacket pkt;
    int ret;
    int audio_stream_idx = -1;
    int out_audio_stream_idx = -1;

    LOGD("Extraction starting: V=%s, O=%s", in_v, out);

    // Open input file
    if ((ret = avformat_open_input(&ifmt_ctx, in_v, nullptr, nullptr)) < 0) {
        LOGE("Could not open input file '%s'", in_v);
        goto end;
    }
    if ((ret = avformat_find_stream_info(ifmt_ctx, nullptr)) < 0) {
        LOGE("Failed to retrieve stream information");
        goto end;
    }

    // Create output context
    avformat_alloc_output_context2(&ofmt_ctx, nullptr, nullptr, out);
    if (!ofmt_ctx) {
        LOGE("Could not create output context");
        ret = AVERROR_UNKNOWN;
        goto end;
    }

    // Find and add audio stream to output
    for (int i = 0; i < ifmt_ctx->nb_streams; i++) {
        if (ifmt_ctx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
            audio_stream_idx = i;
            AVStream *in_stream = ifmt_ctx->streams[i];
            AVStream *out_stream = avformat_new_stream(ofmt_ctx, nullptr);
            if (!out_stream) {
                LOGE("Failed allocating output audio stream");
                ret = AVERROR_UNKNOWN;
                goto end;
            }
            out_audio_stream_idx = out_stream->index;
            if ((ret = avcodec_parameters_copy(out_stream->codecpar, in_stream->codecpar)) < 0) {
                LOGE("Failed to copy audio codec parameters");
                goto end;
            }
            out_stream->codecpar->codec_tag = 0;
            break;
        }
    }

    if (audio_stream_idx == -1) {
        LOGE("No audio stream found in input file");
        ret = -1;
        goto end;
    }

    if (!(ofmt_ctx->oformat->flags & AVFMT_NOFILE)) {
        if ((ret = avio_open(&ofmt_ctx->pb, out, AVIO_FLAG_WRITE)) < 0) {
            LOGE("Could not open output file '%s'", out);
            goto end;
        }
    }

    if ((ret = avformat_write_header(ofmt_ctx, nullptr)) < 0) {
        LOGE("Error occurred when opening output file");
        goto end;
    }

    // Read and write audio packets
    while (true) {
        ret = av_read_frame(ifmt_ctx, &pkt);
        if (ret < 0) break;

        if (pkt.stream_index == audio_stream_idx) {
            AVStream *in_stream = ifmt_ctx->streams[pkt.stream_index];
            AVStream *out_stream = ofmt_ctx->streams[out_audio_stream_idx];

            pkt.stream_index = out_audio_stream_idx;
            av_packet_rescale_ts(&pkt, in_stream->time_base, out_stream->time_base);
            pkt.pos = -1;

            if ((ret = av_interleaved_write_frame(ofmt_ctx, &pkt)) < 0) {
                LOGE("Error writing packet during extraction");
                break;
            }
        }
        av_packet_unref(&pkt);
    }

    av_write_trailer(ofmt_ctx);
    LOGD("Extraction finished successfully");
    ret = 0;

end:
    if (ifmt_ctx) avformat_close_input(&ifmt_ctx);
    if (ofmt_ctx && !(ofmt_ctx->oformat->flags & AVFMT_NOFILE)) avio_closep(&ofmt_ctx->pb);
    if (ofmt_ctx) avformat_free_context(ofmt_ctx);

    env->ReleaseStringUTFChars(video_path, in_v);
    env->ReleaseStringUTFChars(output_path, out);

    return ret;
}
#include <vector>

extern "C"
JNIEXPORT jfloatArray JNICALL
Java_com_example_typgraphyeditor_MainActivity_decodeAudioToPcm(JNIEnv *env, jobject thiz, jstring audio_path) {
    const char *path = env->GetStringUTFChars(audio_path, nullptr);
    AVFormatContext *fmt_ctx = nullptr;
    if (avformat_open_input(&fmt_ctx, path, nullptr, nullptr) < 0) {
        env->ReleaseStringUTFChars(audio_path, path);
        return nullptr;
    }

    if (avformat_find_stream_info(fmt_ctx, nullptr) < 0) {
        avformat_close_input(&fmt_ctx);
        env->ReleaseStringUTFChars(audio_path, path);
        return nullptr;
    }

    int audio_stream_idx = -1;
    for (int i = 0; i < fmt_ctx->nb_streams; i++) {
        if (fmt_ctx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
            audio_stream_idx = i;
            break;
        }
    }

    if (audio_stream_idx == -1) {
        avformat_close_input(&fmt_ctx);
        env->ReleaseStringUTFChars(audio_path, path);
        return nullptr;
    }

    AVCodecParameters *codecpar = fmt_ctx->streams[audio_stream_idx]->codecpar;
    const AVCodec *codec = avcodec_find_decoder(codecpar->codec_id);
    if (!codec) {
        avformat_close_input(&fmt_ctx);
        env->ReleaseStringUTFChars(audio_path, path);
        return nullptr;
    }

    AVCodecContext *codec_ctx = avcodec_alloc_context3(codec);
    avcodec_parameters_to_context(codec_ctx, codecpar);
    if (avcodec_open2(codec_ctx, codec, nullptr) < 0) {
        avcodec_free_context(&codec_ctx);
        avformat_close_input(&fmt_ctx);
        env->ReleaseStringUTFChars(audio_path, path);
        return nullptr;
    }

    AVChannelLayout out_ch_layout;
    av_channel_layout_default(&out_ch_layout, 1); // Mono

    SwrContext *swr_ctx = nullptr;
    int ret = swr_alloc_set_opts2(&swr_ctx,
                                 &out_ch_layout, AV_SAMPLE_FMT_FLT, 16000,
                                 &codec_ctx->ch_layout, codec_ctx->sample_fmt, codec_ctx->sample_rate,
                                 0, nullptr);

    if (ret < 0 || !swr_ctx || swr_init(swr_ctx) < 0) {
        if (swr_ctx) swr_free(&swr_ctx);
        avcodec_free_context(&codec_ctx);
        avformat_close_input(&fmt_ctx);
        env->ReleaseStringUTFChars(audio_path, path);
        return nullptr;
    }

    AVPacket pkt;
    AVFrame *frame = av_frame_alloc();
    std::vector<float> pcm_data;

    while (av_read_frame(fmt_ctx, &pkt) >= 0) {
        if (pkt.stream_index == audio_stream_idx) {
            if (avcodec_send_packet(codec_ctx, &pkt) == 0) {
                while (avcodec_receive_frame(codec_ctx, frame) == 0) {
                    uint8_t *out_data[1];
                    int out_samples = av_rescale_rnd(swr_get_delay(swr_ctx, codec_ctx->sample_rate) + frame->nb_samples, 16000, codec_ctx->sample_rate, AV_ROUND_UP);
                    
                    float *buffer = (float *)av_malloc(out_samples * sizeof(float));
                    out_data[0] = (uint8_t *)buffer;

                    int converted = swr_convert(swr_ctx, out_data, out_samples, (const uint8_t **)frame->data, frame->nb_samples);
                    if (converted > 0) {
                        pcm_data.insert(pcm_data.end(), buffer, buffer + converted);
                    }
                    av_free(buffer);
                }
            }
        }
        av_packet_unref(&pkt);
    }

    av_frame_free(&frame);
    swr_free(&swr_ctx);
    avcodec_free_context(&codec_ctx);
    avformat_close_input(&fmt_ctx);
    env->ReleaseStringUTFChars(audio_path, path);

    jfloatArray result = env->NewFloatArray(pcm_data.size());
    env->SetFloatArrayRegion(result, 0, pcm_data.size(), pcm_data.data());
    return result;
}
