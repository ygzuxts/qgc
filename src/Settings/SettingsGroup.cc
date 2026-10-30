/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "SettingsGroup.h"
#include "QGCCorePlugin.h"
#include "QGCApplication.h"

#include <QtQml/QQmlEngine>

SettingsGroup::SettingsGroup(const QString& name, const QString& settingsGroup, QObject* parent)
    : QObject       (parent)
    , _visible      (QGCCorePlugin::instance()->overrideSettingsGroupVisibility(name))
    , _name         (name)
    , _settingsGroup(settingsGroup)
{
    QQmlEngine::setObjectOwnership(this, QQmlEngine::CppOwnership);

    _nameToMetaDataMap = FactMetaData::createMapFromJsonFile(QString(kJsonFile).arg(name), this);
    connect(qgcApp(), &QGCApplication::languageChanged, this, [this]() {
        QObject translationOwner;
        const auto translated = FactMetaData::createMapFromJsonFile(QString(kJsonFile).arg(_name), &translationOwner);
        const auto facts = findChildren<SettingsFact*>(QString(), Qt::FindDirectChildrenOnly);
        for (auto it = _nameToMetaDataMap.cbegin(); it != _nameToMetaDataMap.cend(); ++it) {
            const auto source = translated.value(it.key(), nullptr);
            if (!source) {
                continue;
            }
            auto metadata = it.value();
            metadata->setShortDescription(source->shortDescription());
            metadata->setLongDescription(source->longDescription());
            // Keep enum values and plugin overrides; only replace matching labels.
            const auto values = metadata->enumValues();
            auto strings = metadata->enumStrings();
            for (qsizetype i = 0; i < values.size(); ++i) {
                const auto index = source->enumValues().indexOf(values[i]);
                if (index >= 0 && i < strings.size()) {
                    strings[i] = source->enumStrings().value(index);
                }
            }
            metadata->setEnumInfo(strings, values);
            for (auto fact : facts) {
                if (fact->metaData() == metadata) {
                    emit fact->descriptionsChanged();
                    emit fact->enumsChanged();
                }
            }
        }
    });
}

SettingsFact* SettingsGroup::_createSettingsFact(const QString& factName)
{
    FactMetaData* m = _nameToMetaDataMap[factName];
    if(!m) {
        qCritical() << "Fact name " << factName << "not found in" << QString(kJsonFile).arg(_name);
        exit(-1);
    }
    return new SettingsFact(_settingsGroup, m, this);
}

