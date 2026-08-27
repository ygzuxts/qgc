#include "BrandedPlugin.h"
#include "BrandedConfig.h"

#include <QtCore/qapplicationstatic.h>
#include <QtGui/QColor>

Q_APPLICATION_STATIC(BrandedPlugin, _brandedPluginInstance);

BrandedPlugin::BrandedPlugin(QObject* parent)
    : QGCCorePlugin(parent)
{
}

QGCCorePlugin* BrandedPlugin::instance()
{
    return _brandedPluginInstance();
}

QString BrandedPlugin::brandImageIndoor() const
{
    return QStringLiteral("/brand/logo.png");
}

QString BrandedPlugin::brandImageOutdoor() const
{
    return QStringLiteral("/brand/logo.png");
}

void BrandedPlugin::paletteOverride(const QString& colorName, QGCPalette::PaletteColorInfo_t& colorInfo)
{
    if (colorName == QStringLiteral("brandingPurple")) {
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupEnabled] = QColor(QGC_BRAND_GRADIENT_COLOR);
        colorInfo[QGCPalette::Dark][QGCPalette::ColorGroupDisabled] = QColor(QGC_BRAND_GRADIENT_COLOR);
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupEnabled] = QColor(QGC_BRAND_GRADIENT_COLOR);
        colorInfo[QGCPalette::Light][QGCPalette::ColorGroupDisabled] = QColor(QGC_BRAND_GRADIENT_COLOR);
    }
}
