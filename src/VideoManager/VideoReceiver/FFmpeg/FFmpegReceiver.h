#ifndef FFMPEGRECEIVER_H
#define FFMPEGRECEIVER_H

#include "VideoReceiver.h"
#include <QImage>
#include <QPointer>

class FFmpegWorker;
class FFmpegVideoItem;

class FFmpegReceiver : public VideoReceiver
{
    Q_OBJECT
public:
    explicit FFmpegReceiver(QObject* parent = nullptr);
    ~FFmpegReceiver() override;

signals:
    void frameReady(const QImage &image);

public slots:
    void start(uint32_t timeout) override;
    void stop() override;

    void startDecoding(void *sink) override;
    void stopDecoding() override;

    void startRecording(const QString &videoFile,
                        FILE_FORMAT format) override;
    void stopRecording() override;

    void takeScreenshot(const QString &imageFile) override;

private:
    FFmpegWorker *_worker = nullptr;
    bool _stopRequested = false;
    QPointer<FFmpegVideoItem> _videoItem;
};

#endif  // FFMPEGRECEIVER_H
