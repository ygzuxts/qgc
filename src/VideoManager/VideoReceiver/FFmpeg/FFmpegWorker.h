#pragma once
#include <QImage>
#include <QThread>

class FFmpegWorker final : public QThread
{
    Q_OBJECT

public:
    explicit FFmpegWorker(const QString &source, uint32_t timeout, QObject *parent = nullptr);
    ~FFmpegWorker() override;

protected:
    void run() override;
signals:
    void frameReady(const QImage &image);
private:
    QString _source;
    uint32_t _timeout;
};
