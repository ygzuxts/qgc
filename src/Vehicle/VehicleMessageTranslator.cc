#include "VehicleMessageTranslator.h"

#include <QtCore/QCoreApplication>
#include <QtCore/QDateTime>
#include <QtCore/QDir>
#include <QtCore/QFile>
#include <QtCore/QFileInfo>
#include <QtCore/QJsonDocument>
#include <QtCore/QJsonObject>
#include <QtCore/QMutex>
#include <QtCore/QMutexLocker>
#include <QtCore/QRegularExpression>
#include <QtCore/QSet>
#include <QtCore/QStandardPaths>

namespace {
struct Message {
    QString prefix;
    QString source;
    QString argument;
};

Message identify(QString text)
{
    Message message;
    const QString prefix = QStringLiteral("[QGC_TEST_DIALOG] ");
    if (text.startsWith(prefix)) {
        message.prefix = prefix;
        text.remove(0, prefix.size());
    }
    // Explicit templates only: do not replace arbitrary numbers or identifiers.
    static const QRegularExpression popup(QStringLiteral("^Test popup #(\\d+): Battery voltage low$"));
    static const QRegularExpression dialog(QStringLiteral("^Test dialog #(\\d+)$"));
    static const QRegularExpression battery(QStringLiteral("^Battery (\\d+) voltage low$"));
    auto match = popup.match(text);
    if (match.hasMatch()) {
        message.source = QT_TRANSLATE_NOOP("VehicleMessages", "Test popup #%1: Battery voltage low");
    } else if ((match = dialog.match(text)).hasMatch()) {
        message.source = QT_TRANSLATE_NOOP("VehicleMessages", "Test dialog #%1");
    } else if ((match = battery.match(text)).hasMatch()) {
        message.source = QT_TRANSLATE_NOOP("VehicleMessages", "Battery %1 voltage low");
    } else {
        message.source = text;
    }
    if (match.hasMatch()) {
        message.argument = match.captured(1);
    }
    return message;
}

QString translatedSource(const Message& message)
{
    return QCoreApplication::translate("VehicleMessages", message.source.toUtf8().constData());
}
}

QString VehicleMessageTranslator::translate(const QString& text)
{
    const auto message = identify(text);
    auto display = translatedSource(message);
    if (!message.argument.isEmpty()) {
        display = display.arg(message.argument);
    }
    return message.prefix + display;
}

QString VehicleMessageTranslator::pendingFilePath()
{
    return QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation)
        + QStringLiteral("/translations/vehicle_messages_pending.jsonl");
}

void VehicleMessageTranslator::collectUntranslated(const QString& text, int systemId, int componentId, int severity)
{
    const auto message = identify(text);
    static const QRegularExpression english(QStringLiteral("[A-Za-z]"));
    if (message.source.isEmpty() || message.source.size() > 4096
        || !message.source.contains(english) || translatedSource(message) != message.source) {
        return;
    }
    static QMutex mutex;
    const QMutexLocker locker(&mutex);
    static QSet<QString> seen;
    static QString loadedPath;
    const QString path = pendingFilePath();
    if (loadedPath != path) {
        seen.clear();
        QFile existing(path);
        if (existing.open(QIODevice::ReadOnly)) {
            while (!existing.atEnd() && seen.size() < 5000) {
                const auto entry = QJsonDocument::fromJson(existing.readLine()).object();
                const auto source = entry.value(QStringLiteral("source")).toString();
                if (!source.isEmpty()) {
                    seen.insert(source);
                }
            }
        }
        loadedPath = path;
    }
    if (seen.contains(message.source) || seen.size() >= 5000) {
        return;
    }
    if (!QDir().mkpath(QFileInfo(path).absolutePath())) {
        return;
    }
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Append)) {
        return;
    }
    const QJsonObject entry {
        {QStringLiteral("context"), QStringLiteral("VehicleMessages")},
        {QStringLiteral("source"), message.source},
        {QStringLiteral("example"), text},
        {QStringLiteral("system_id"), systemId},
        {QStringLiteral("component_id"), componentId},
        {QStringLiteral("severity"), severity},
        {QStringLiteral("first_seen_utc"), QDateTime::currentDateTimeUtc().toString(Qt::ISODate)}
    };
    const auto line = QJsonDocument(entry).toJson(QJsonDocument::Compact) + '\n';
    if (file.write(line) == line.size()) {
        seen.insert(message.source);
    }
}
