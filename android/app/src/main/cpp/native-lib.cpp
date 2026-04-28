#include <jni.h>
#include <string>
#include <android/log.h>

extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libswscale/swscale.h>
#include <libavutil/imgutils.h>
#include <libavutil/timestamp.h>
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
extern "C"
JNIEXPORT jint JNICALL
Java_com_example_typgraphyeditor_MainActivity_muxVideoAudio(
        JNIEnv *env,
        jobject thiz,
        jstring video_path,
        jstring audio_path,
        jstring output_path) {

    const char *in_v = env->GetStringUTFChars(video_path, nullptr);
    const char *in_a = env->GetStringUTFChars(audio_path, nullptr);
    const char *out = env->GetStringUTFChars(output_path, nullptr);

    AVFormatContext *ifmt_ctx_v = nullptr, *ifmt_ctx_a = nullptr, *ofmt_ctx = nullptr;
    AVPacket pkt;
    int ret;
    int video_stream_idx = -1, audio_stream_idx = -1;
    int out_video_stream_idx = -1, out_audio_stream_idx = -1;

    LOGD("Muxing starting: V=%s, A=%s, O=%s", in_v, in_a, out);

    // Open video input
    if ((ret = avformat_open_input(&ifmt_ctx_v, in_v, nullptr, nullptr)) < 0) {
        LOGE("Could not open video input file '%s'", in_v);
        goto end;
    }
    if ((ret = avformat_find_stream_info(ifmt_ctx_v, nullptr)) < 0) {
        LOGE("Failed to retrieve video stream information");
        goto end;
    }

    // Open audio input
    if ((ret = avformat_open_input(&ifmt_ctx_a, in_a, nullptr, nullptr)) < 0) {
        LOGE("Could not open audio input file '%s'", in_a);
        goto end;
    }
    if ((ret = avformat_find_stream_info(ifmt_ctx_a, nullptr)) < 0) {
        LOGE("Failed to retrieve audio stream information");
        goto end;
    }

    // Create output context
    avformat_alloc_output_context2(&ofmt_ctx, nullptr, nullptr, out);
    if (!ofmt_ctx) {
        LOGE("Could not create output context");
        ret = AVERROR_UNKNOWN;
        goto end;
    }

    // Add video stream to output
    for (int i = 0; i < ifmt_ctx_v->nb_streams; i++) {
        if (ifmt_ctx_v->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            video_stream_idx = i;
            AVStream *in_stream = ifmt_ctx_v->streams[i];
            AVStream *out_stream = avformat_new_stream(ofmt_ctx, nullptr);
            if (!out_stream) {
                LOGE("Failed allocating output video stream");
                ret = AVERROR_UNKNOWN;
                goto end;
            }
            out_video_stream_idx = out_stream->index;
            if ((ret = avcodec_parameters_copy(out_stream->codecpar, in_stream->codecpar)) < 0) {
                LOGE("Failed to copy video codec parameters");
                goto end;
            }
            out_stream->codecpar->codec_tag = 0;
            break;
        }
    }

    // Add audio stream to output
    for (int i = 0; i < ifmt_ctx_a->nb_streams; i++) {
        if (ifmt_ctx_a->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
            audio_stream_idx = i;
            AVStream *in_stream = ifmt_ctx_a->streams[i];
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

    // Mux video
    while (true) {
        ret = av_read_frame(ifmt_ctx_v, &pkt);
        if (ret < 0) break;

        if (pkt.stream_index == video_stream_idx) {
            AVStream *in_stream = ifmt_ctx_v->streams[pkt.stream_index];
            AVStream *out_stream = ofmt_ctx->streams[out_video_stream_idx];

            pkt.stream_index = out_video_stream_idx;
            av_packet_rescale_ts(&pkt, in_stream->time_base, out_stream->time_base);
            pkt.pos = -1;

            if ((ret = av_interleaved_write_frame(ofmt_ctx, &pkt)) < 0) {
                LOGE("Error muxing video packet");
                break;
            }
        }
        av_packet_unref(&pkt);
    }

    // Mux audio
    while (true) {
        ret = av_read_frame(ifmt_ctx_a, &pkt);
        if (ret < 0) break;

        if (pkt.stream_index == audio_stream_idx) {
            AVStream *in_stream = ifmt_ctx_a->streams[pkt.stream_index];
            AVStream *out_stream = ofmt_ctx->streams[out_audio_stream_idx];

            pkt.stream_index = out_audio_stream_idx;
            av_packet_rescale_ts(&pkt, in_stream->time_base, out_stream->time_base);
            pkt.pos = -1;

            if ((ret = av_interleaved_write_frame(ofmt_ctx, &pkt)) < 0) {
                LOGE("Error muxing audio packet");
                break;
            }
        }
        av_packet_unref(&pkt);
    }

    av_write_trailer(ofmt_ctx);
    LOGD("Muxing finished successfully");
    ret = 0;

end:
    if (ifmt_ctx_v) avformat_close_input(&ifmt_ctx_v);
    if (ifmt_ctx_a) avformat_close_input(&ifmt_ctx_a);
    if (ofmt_ctx && !(ofmt_ctx->oformat->flags & AVFMT_NOFILE)) avio_closep(&ofmt_ctx->pb);
    if (ofmt_ctx) avformat_free_context(ofmt_ctx);

    env->ReleaseStringUTFChars(video_path, in_v);
    env->ReleaseStringUTFChars(audio_path, in_a);
    env->ReleaseStringUTFChars(output_path, out);

    return ret;
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
