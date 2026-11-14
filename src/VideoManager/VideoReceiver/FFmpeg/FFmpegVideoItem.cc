#include "FFmpegVideoItem.h"
#include "FFmpegReceiver.h"

#include <QPainter>

FFmpegVideoItem::FFmpegVideoItem(QQuickItem *parent)
    : QQuickPaintedItem(parent)
{
}

void FFmpegVideoItem::startTest()
{
    if (_receiver) {
        return;
    }
    _receiver = new FFmpegReceiver(this);
    _receiver->setUri("C:/deps/test.mp4");
    connect(_receiver, &FFmpegReceiver::frameReady,
            this, &FFmpegVideoItem::setFrame, Qt::QueuedConnection);
    _receiver->start(10);
}

void FFmpegVideoItem::setFrame(const QImage &image)
{
    _image = image;
    update();  // 通知 Qt 重新绘制
}

void FFmpegVideoItem::paint(QPainter *painter)
{
    painter->fillRect(boundingRect(), Qt::black);

    if (_image.isNull()) {
        return;
    }

            // 保持视频比例，居中显示。
    QSizeF size = _image.size();
    size.scale(boundingRect().size(), Qt::KeepAspectRatio);

    QRectF target(QPointF(0, 0), size);
    target.moveCenter(boundingRect().center());

    painter->drawImage(target, _image);
}
