#include <jni.h>
#include <string>
#include <android/log.h>

extern "C" {
#include <libavformat/avformat.h>
#include <libavutil/timestamp.h>
}

#define LOG_TAG "FFmpegNative"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

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
