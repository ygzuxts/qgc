#include "VehicleMessageTranslator.h"
#include <QtCore/QCoreApplication>
#include <QtCore/QFile>
#include <QtCore/QJsonDocument>
#include <QtCore/QJsonObject>
#include <QtCore/QStandardPaths>
#include <QtCore/QTemporaryDir>
#include <QtCore/QTranslator>
#include <cstdio>
#include <cstdlib>

static void check(bool condition, const char* reason)
{
    if (!condition) {
        fprintf(stderr, "FAIL: %s\n", reason);
        exit(1);
    }
}

int main(int argc, char* argv[])
{
    QCoreApplication app(argc, argv);
    QStandardPaths::setTestModeEnabled(true);
    QTemporaryDir directory;
    check(directory.isValid(), "temporary directory");
    app.setApplicationName(QStringLiteral("vehicle-message-check-") + directory.path().section('/', -1));
    const QString raw = QStringLiteral("Test popup #12: Battery voltage low");
    check(VehicleMessageTranslator::translate(raw) == raw, "English fallback");
    check(VehicleMessageTranslator::translate(QStringLiteral("Unknown %1 <value>")) == QStringLiteral("Unknown %1 <value>"), "literal unknown text");
    QTranslator translator;
    check(argc == 2 && translator.load(QString::fromLocal8Bit(argv[1])), "load test catalog");
    app.installTranslator(&translator);
    check(VehicleMessageTranslator::translate(raw) == QString::fromUtf8("测试弹窗 #12：电池电压低"), "numbered popup translation");
    check(VehicleMessageTranslator::translate(QStringLiteral("Battery 2 voltage low")) == QString::fromUtf8("电池 2 电压低"), "battery ID preserved");
    check(VehicleMessageTranslator::translate(QStringLiteral("[QGC_TEST_DIALOG] Test dialog #3")) == QString::fromUtf8("[QGC_TEST_DIALOG] 测试确认弹窗 #3"), "dialog marker preserved");
    VehicleMessageTranslator::collectUntranslated(raw, 1, 1, 2);
    check(!QFile::exists(VehicleMessageTranslator::pendingFilePath()), "known Chinese translations not collected");
    app.removeTranslator(&translator);
    check(VehicleMessageTranslator::translate(raw) == raw, "switch back to English");
    VehicleMessageTranslator::collectUntranslated(raw, 1, 1, 2);
    VehicleMessageTranslator::collectUntranslated(QStringLiteral("Test popup #99: Battery voltage low"), 1, 1, 2);
    VehicleMessageTranslator::collectUntranslated(QStringLiteral("New firmware message"), 1, 1, 4);
    QFile pending(VehicleMessageTranslator::pendingFilePath());
    check(pending.open(QIODevice::ReadOnly), "pending file created");
    const auto first = QJsonDocument::fromJson(pending.readLine()).object();
    check(first.value(QStringLiteral("source")).toString() == QStringLiteral("Test popup #%1: Battery voltage low"), "template collected");
    check(first.value(QStringLiteral("example")).toString() == raw, "raw example retained");
    check(!pending.readLine().isEmpty() && pending.atEnd(), "deduplicated templates");
    pending.close();
    check(pending.remove(), "test file cleanup");
    puts("PASS: language switching, templates, dialog routing marker, raw fallback, collection and deduplication");
}
