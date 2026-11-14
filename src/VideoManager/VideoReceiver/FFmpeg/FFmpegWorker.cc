#include "FFmpegWorker.h"

#include <QDebug>
#include <QElapsedTimer>
#include <QImage>
extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavutil/error.h>
#include <libswscale/swscale.h>
}

FFmpegWorker::FFmpegWorker(const QString &source, uint32_t timeout, QObject *parent)
    : QThread(parent)
    , _source(source)
    , _timeout(timeout)
{
}

FFmpegWorker::~FFmpegWorker()
{
    requestInterruption();
    wait();
}

void FFmpegWorker::run()
{
    qInfo() << "FFmpeg worker started";

    AVFormatContext *input = avformat_alloc_context();
    AVCodecContext *decoder = nullptr;
    AVPacket *packet = nullptr;
    AVFrame *frame = nullptr;

    // Keep the interrupt context alive until the input is closed.
    struct InterruptContext {
        FFmpegWorker *worker;
        QElapsedTimer timer;
        qint64 timeoutMs;
    } interrupt{this, {}, static_cast<qint64>(_timeout) * 1000};
    interrupt.timer.start();

    const auto logError = [](const char *operation, int result) {
        char message[AV_ERROR_MAX_STRING_SIZE] = {};
        av_strerror(result, message, sizeof(message));
        qWarning() << "FFmpeg" << operation << ":" << message;
    };

    // Open the input and decode frames until the stream ends or is stopped.
    const auto decodeFirstFrame = [&]() {
        if (!input) {
            qWarning() << "FFmpeg: failed to allocate input context";
            return;
        }
        input->interrupt_callback.callback = [](void *opaque) -> int {
            auto *context = static_cast<InterruptContext *>(opaque);
            return context->worker->isInterruptionRequested()
            || context->timer.elapsed() > context->timeoutMs;
        };
        input->interrupt_callback.opaque = &interrupt;

        const QByteArray sourceBytes = _source.toUtf8();
        int result = avformat_open_input(&input, sourceBytes.constData(), nullptr, nullptr);
        if (result < 0) {
            logError("open input", result);
            return;
        }
        interrupt.timer.restart();
        result = avformat_find_stream_info(input, nullptr);
        if (result < 0) {
            logError("read stream info", result);
            return;
        }
        const AVCodec *codec = nullptr;
        const int videoIndex = av_find_best_stream(input, AVMEDIA_TYPE_VIDEO,
                               -1, -1, &codec, 0);
        if (videoIndex < 0) {
            logError("find video stream", videoIndex);
            return;
        }
        decoder = avcodec_alloc_context3(codec);
        packet = av_packet_alloc();
        frame = av_frame_alloc();
        if (!decoder || !packet || !frame) {
            qWarning() << "FFmpeg: failed to allocate decoder buffers";
            return;
        }
        result = avcodec_parameters_to_context(decoder, input->streams[videoIndex]->codecpar);
        if (result < 0) {
            logError("copy codec parameters", result);
            return;
        }
        result = avcodec_open2(decoder, codec, nullptr);
        if (result < 0) {
            logError("open decoder", result);
            return;
        }
        QElapsedTimer playbackTimer;
        qint64 firstPts = AV_NOPTS_VALUE;
        bool firstImage = true;

        const AVRational timeBase = input->streams[videoIndex]->time_base;
        while (!isInterruptionRequested()) {
            interrupt.timer.restart();
            const int readResult = av_read_frame(input, packet);
            if (readResult < 0 && readResult != AVERROR_EOF) {
                logError("read packet", readResult);
                return;
            }
            if (readResult >= 0 && packet->stream_index != videoIndex) {
                av_packet_unref(packet);
                continue;
            }
            // At EOF, flush delayed frames from the decoder.
            result = avcodec_send_packet(decoder, readResult == AVERROR_EOF ? nullptr : packet);
            av_packet_unref(packet);
            if (result < 0) {
                logError("send packet", result);
                return;
            }

            while ((result = avcodec_receive_frame(decoder, frame)) == 0) {
                if (firstImage) {
                    qInfo() << "FFmpeg first frame:"
                            << frame->width << "x" << frame->height
                            << "decoder:" << codec->name;
                }

                // 创建一张 Qt 图片，用于存放转换后的画面。
                QImage image(frame->width, frame->height, QImage::Format_RGB888);
                if (image.isNull()) {
                    qWarning() << "FFmpeg: failed to allocate image";
                    return;
                }

                // 把 FFmpeg 解码出的像素格式转换成 RGB。
                SwsContext *converter = sws_getContext(
                                            frame->width, frame->height,
                                            static_cast<AVPixelFormat>(frame->format),
                                            frame->width, frame->height,
                                            AV_PIX_FMT_RGB24,
                                            SWS_BILINEAR,
                                            nullptr, nullptr, nullptr
                                        );

                if (!converter) {
                    qWarning() << "FFmpeg: failed to create image converter";
                    return;
                }

                uint8_t *outputData[4] = {
                    image.bits(), nullptr, nullptr, nullptr
                };

                int outputStride[4] = {
                    static_cast<int>(image.bytesPerLine()), 0, 0, 0
                };

                const int rows = sws_scale(
                                     converter,
                                     frame->data, frame->linesize,
                                     0, frame->height,
                                     outputData, outputStride
                                 );

                sws_freeContext(converter);

                if (rows != frame->height) {
                    qWarning() << "FFmpeg: image conversion failed";
                    return;
                }

                if (firstImage) {
                    firstImage = false;
                }

                // 按视频时间戳控制速度，避免几秒钟就解码完整个文件。
                const qint64 pts = frame->best_effort_timestamp;

                if (pts != AV_NOPTS_VALUE) {
                    if (firstPts == AV_NOPTS_VALUE) {
                        firstPts = pts;
                        playbackTimer.start();
                    }

                    const qint64 targetMs = av_rescale_q(
                                                pts - firstPts,
                                                timeBase,
                                                AVRational{1, 1000}
                                            );

                    while (!isInterruptionRequested()
                            && playbackTimer.elapsed() < targetMs) {
                        QThread::msleep(5);
                    }
                }

                if (isInterruptionRequested()) {
                    return;
                }

                // 把当前画面发送到预览窗口。
                emit frameReady(image);
                av_frame_unref(frame);

                // 这里不再 return，继续取下一帧。
            }
            if (result != AVERROR(EAGAIN) && result != AVERROR_EOF) {
                logError("decode frame", result);
                return;
            }
            if (readResult == AVERROR_EOF) {
                break;
            }
        }
        if (firstImage && !isInterruptionRequested()) {
            qWarning() << "FFmpeg: reached EOF without a frame";
        }
    };

    decodeFirstFrame();
    av_frame_free(&frame);
    av_packet_free(&packet);
    avcodec_free_context(&decoder);
    avformat_close_input(&input);

    qInfo() << "FFmpeg worker stopped";
}
