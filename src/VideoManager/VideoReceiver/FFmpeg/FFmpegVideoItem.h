#pragma once

#include <QImage>
#include <QQuickPaintedItem>

class FFmpegReceiver;

class FFmpegVideoItem : public QQuickPaintedItem
{
    Q_OBJECT

   public:
    explicit FFmpegVideoItem(QQuickItem *parent = nullptr);

    void paint(QPainter *painter) override;
    Q_INVOKABLE void startTest();

   public slots:
    void setFrame(const QImage &image);

   private:
    QImage _image;
    FFmpegReceiver *_receiver = nullptr;
};
