#pragma once

#include <QtCore/QCoreApplication>

// Maintained by tools/translations/import_vehicle_messages.py for lupdate.
// Runtime lookup uses the VehicleMessages context, not these array indices.
namespace VehicleMessageCatalog {
inline const char* const sources[] = {
    QT_TRANSLATE_NOOP("VehicleMessages", "Battery voltage low"),
    QT_TRANSLATE_NOOP("VehicleMessages", "Battery %1 voltage low"),
    QT_TRANSLATE_NOOP("VehicleMessages", "Test popup #%1: Battery voltage low"),
    QT_TRANSLATE_NOOP("VehicleMessages", "Test dialog #%1"),
    QT_TRANSLATE_NOOP("VehicleMessages", "Test confirmation"),
};
}
