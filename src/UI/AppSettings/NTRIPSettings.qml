/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.ScreenTools

SettingsPage {
    property var _ntripSettings: QGroundControl.settingsManager.ntripSettings
    property var _ntripManager:  QGroundControl.ntripManager
    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    function statusText() {
        if (!_ntripManager) {
            return qsTr("Unavailable")
        }
        return _ntripManager.statusMessage === "" ? qsTr("Disconnected") : _ntripManager.statusMessage
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("NTRIP")

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Connect")
            fact:               _ntripSettings.ntripServerConnectEnabled
        }

        LabelledFactTextField {
            Layout.fillWidth:           true
            textFieldPreferredWidth:    ScreenTools.defaultFontPixelWidth * 24
            label:                      _ntripSettings.ntripServerHostAddress.shortDescription
            fact:                       _ntripSettings.ntripServerHostAddress
        }

        LabelledFactTextField {
            Layout.fillWidth:           true
            textFieldPreferredWidth:    ScreenTools.defaultFontPixelWidth * 24
            label:                      _ntripSettings.ntripServerPort.shortDescription
            fact:                       _ntripSettings.ntripServerPort
        }

        LabelledFactTextField {
            Layout.fillWidth:           true
            textFieldPreferredWidth:    ScreenTools.defaultFontPixelWidth * 24
            label:                      _ntripSettings.ntripMountpoint.shortDescription
            fact:                       _ntripSettings.ntripMountpoint
        }

        LabelledFactTextField {
            Layout.fillWidth:           true
            textFieldPreferredWidth:    ScreenTools.defaultFontPixelWidth * 24
            label:                      _ntripSettings.ntripUsername.shortDescription
            fact:                       _ntripSettings.ntripUsername
        }

        LabelledFactTextField {
            Layout.fillWidth:           true
            textFieldPreferredWidth:    ScreenTools.defaultFontPixelWidth * 24
            label:                      _ntripSettings.ntripPassword.shortDescription
            fact:                       _ntripSettings.ntripPassword
            textField.echoMode:         TextInput.Password
        }

        LabelledFactTextField {
            Layout.fillWidth:           true
            textFieldPreferredWidth:    ScreenTools.defaultFontPixelWidth * 24
            label:                      _ntripSettings.ntripWhitelist.shortDescription
            fact:                       _ntripSettings.ntripWhitelist
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               _ntripSettings.ntripUseTls.shortDescription
            fact:               _ntripSettings.ntripUseTls
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("4G Module")

        LabelledButton {
            Layout.fillWidth:   true
            label:              qsTr("RTK Account")
            buttonText:         _activeVehicle ? qsTr("Send") : qsTr("Not Connected")
            enabled:            _activeVehicle

            onClicked: {
                if (_activeVehicle.sendNtripConfigTo4GModule(_ntripSettings.ntripServerHostAddress.rawValue,
                                                             _ntripSettings.ntripServerPort.rawValue,
                                                             _ntripSettings.ntripMountpoint.rawValue,
                                                             _ntripSettings.ntripUsername.rawValue,
                                                             _ntripSettings.ntripPassword.rawValue)) {
                    mainWindow.showMessageDialog(qsTr("NTRIP"), qsTr("NTRIP account settings sent to the 4G module."))
                } else {
                    mainWindow.showMessageDialog(qsTr("NTRIP"), qsTr("Unable to send NTRIP account settings to the 4G module. Check the vehicle connection and field lengths."))
                }
            }
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Status")

        LabelledLabel {
            Layout.fillWidth:   true
            label:              qsTr("Connection")
            labelText:          statusText()
        }

        LabelledLabel {
            Layout.fillWidth:   true
            label:              qsTr("GGA source")
            labelText:          _ntripManager && _ntripManager.ggaSource !== "" ? _ntripManager.ggaSource : qsTr("N/A")
        }

        LabelledLabel {
            Layout.fillWidth:   true
            label:              qsTr("Bytes received")
            labelText:          _ntripManager ? _ntripManager.bytesReceived.toString() : "0"
        }

        LabelledLabel {
            Layout.fillWidth:   true
            label:              qsTr("Messages")
            labelText:          _ntripManager ? _ntripManager.messagesReceived.toString() : "0"
        }

        LabelledLabel {
            Layout.fillWidth:   true
            label:              qsTr("Rate")
            labelText:          _ntripManager ? qsTr("%1 B/s").arg(_ntripManager.dataRateBytesPerSec.toFixed(0)) : qsTr("0 B/s")
        }

        LabelledButton {
            Layout.fillWidth:   true
            label:              qsTr("Mountpoints")
            buttonText:         qsTr("Fetch")
            enabled:            _ntripManager

            onClicked:          _ntripManager.fetchMountpoints()
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("UDP Forward")

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               _ntripSettings.ntripUdpForwardEnabled.shortDescription
            fact:               _ntripSettings.ntripUdpForwardEnabled
        }

        LabelledFactTextField {
            Layout.fillWidth:           true
            textFieldPreferredWidth:    ScreenTools.defaultFontPixelWidth * 24
            label:                      _ntripSettings.ntripUdpTargetAddress.shortDescription
            fact:                       _ntripSettings.ntripUdpTargetAddress
            enabled:                    _ntripSettings.ntripUdpForwardEnabled.rawValue
        }

        LabelledFactTextField {
            Layout.fillWidth:           true
            textFieldPreferredWidth:    ScreenTools.defaultFontPixelWidth * 24
            label:                      _ntripSettings.ntripUdpTargetPort.shortDescription
            fact:                       _ntripSettings.ntripUdpTargetPort
            enabled:                    _ntripSettings.ntripUdpForwardEnabled.rawValue
        }
    }
}
