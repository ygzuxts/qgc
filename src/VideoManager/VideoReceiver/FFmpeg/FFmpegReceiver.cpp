#include "FFmpegReceiver.h"
#include "FFmpegWorker.h"
#include "FFmpegVideoItem.h"
#include <QUrl>
#include <QFileInfo>
#include <QDebug>

extern "C" {
#include <libavutil/avutil.h>
}
FFmpegReceiver::FFmpegReceiver(QObject* parent) : VideoReceiver{parent}
{
    qInfo() << "FFmpeg version:" << av_version_info();
}

FFmpegReceiver::~FFmpegReceiver() = default;


// 开始接收视频
void FFmpegReceiver::start(uint32_t timeout)
{
    if (_worker) {
        emit onStartComplete(STATUS_INVALID_STATE);
        return;
    }

    const QUrl source(uri());
    if (source.scheme() != QStringLiteral("rtsp") && source.scheme() != QStringLiteral("rtsps")
        && !QFileInfo(uri()).isFile()) {
        emit onStartComplete(STATUS_INVALID_URL);
        return;
    }

    _stopRequested = false;
    _worker = new FFmpegWorker(uri(), timeout ? timeout : 10, this);
    connect(_worker, &FFmpegWorker::frameReady, this, [this](const QImage & image) {
        if (_stopRequested) {
            return;
        }
        if (!_decoding) {
            _decoding = true;
            emit videoSizeChanged(image.size());
            emit decodingChanged(true);
            emit streamingChanged(true);
        }
        if (_videoItem) {
            _videoItem->setFrame(image);
        }
        emit frameReady(image);
    });
    connect(_worker, &QThread::finished, this, [this]() {
        FFmpegWorker *finishedWorker = _worker;
        _worker = nullptr;
        if (_decoding) {
            _decoding = false;
            emit decodingChanged(false);
            emit streamingChanged(false);
        }
        setStarted(false);
        finishedWorker->deleteLater();
        emit onStopComplete(STATUS_OK);
    });
    setStarted(true);
    _worker->start();
    emit onStartComplete(STATUS_OK);
}

// 停止接收视频
void FFmpegReceiver::stop()
{
    if (!_worker) {
        emit onStopComplete(STATUS_INVALID_STATE);
        return;
    }
    _stopRequested = true;
    _worker->requestInterruption();
}

// 开始向显示组件输出画面
void FFmpegReceiver::startDecoding(void *sink)
{
    if (!sink) {
        emit onStartDecodingComplete(STATUS_FAIL);
        return;
    }
    _videoItem = static_cast<FFmpegVideoItem *>(sink);
    emit onStartDecodingComplete(STATUS_OK);
}

// 停止输出画面
void FFmpegReceiver::stopDecoding()
{
    _videoItem = nullptr;
    emit onStopDecodingComplete(STATUS_OK);
}

// 开始录像
void FFmpegReceiver::startRecording(const QString &videoFile,
                                    FILE_FORMAT format)
{
    Q_UNUSED(videoFile);
    Q_UNUSED(format);

    emit onStartRecordingComplete(STATUS_NOT_IMPLEMENTED);
}

// 停止录像
void FFmpegReceiver::stopRecording()
{
    emit onStopRecordingComplete(STATUS_NOT_IMPLEMENTED);
}

// 截图
void FFmpegReceiver::takeScreenshot(const QString &imageFile)
{
    Q_UNUSED(imageFile);

    emit onTakeScreenshotComplete(STATUS_NOT_IMPLEMENTED);
}
