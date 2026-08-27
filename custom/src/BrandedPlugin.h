#pragma once

#include "QGCCorePlugin.h"

class BrandedPlugin : public QGCCorePlugin
{
    Q_OBJECT

public:
    explicit BrandedPlugin(QObject* parent = nullptr);

    static QGCCorePlugin* instance();

    QString brandImageIndoor() const final;
    QString brandImageOutdoor() const final;
    void paletteOverride(const QString& colorName, QGCPalette::PaletteColorInfo_t& colorInfo) final;
};
