#pragma once

#include <QtCore/QString>

/// Display-only STATUSTEXT translation. Protocol and log text stay unchanged.
namespace VehicleMessageTranslator {
QString translate(const QString& text);
QString pendingFilePath();
void collectUntranslated(const QString& text, int systemId, int componentId, int severity);
}
