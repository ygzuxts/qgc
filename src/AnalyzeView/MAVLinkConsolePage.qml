/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtCore

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.Controllers

AnalyzePage {
    id: root
    pageComponent: pageComponent
    pageDescription: qsTr("Provides a connection to the vehicle's system shell.")
    allowPopout: true

    property bool isLoaded: false

    // Key input on mobile is handled differently, so use a separate command input text field.
    // E.g. for android see https://bugreports.qt.io/browse/QTBUG-40803
    readonly property bool _separateCommandInput: ScreenTools.isMobile

    MAVLinkConsoleController { id: conController }

    Component {
        id: pageComponent

        ColumnLayout {
            height: availableHeight
            width: availableWidth
            property int _consoleOutputLen: 0
            property bool savedCommandPanelVisible: false

            Settings {
                id: savedCommandSettings
                property string commandsJson: "[]"
            }

            ListModel {
                id: savedCommandModel
            }

            function scrollToBottom() {
                if (flickable.contentHeight > flickable.height) {
                    flickable.contentY = flickable.contentHeight - flickable.height
                }
            }

            function getCommand() { return textConsole.getText(_consoleOutputLen, textConsole.length) }

            function getCommandAndClear() {
                const command = getCommand()
                textConsole.remove(_consoleOutputLen, textConsole.length)
                return command
            }

            function pasteFromClipboard() {
                // we need to handle a few cases here:
                // in the general form we have: <command_pre><cursor><command_post>
                // and the clipboard may contain newlines
                const cursor = textConsole.cursorPosition - _consoleOutputLen
                var command = getCommandAndClear()
                var command_pre = ""
                var command_post = command
                if (cursor > 0) {
                    command_pre = command.substr(0, cursor)
                    command_post = command.substr(cursor)
                }
                var command_leftover = conController.handleClipboard(command_pre) + command_post
                textConsole.insert(textConsole.length, command_leftover)
                textConsole.cursorPosition = textConsole.length - command_post.length
            }

            function loadSavedCommands() {
                savedCommandModel.clear()
                var commands = []
                try {
                    commands = JSON.parse(savedCommandSettings.commandsJson)
                } catch (e) {
                    commands = []
                }

                for (var i = 0; i < commands.length; i++) {
                    savedCommandModel.append({
                        "commandName": commands[i].commandName || commands[i].name || "",
                        "commandText": commands[i].commandText || commands[i].command || ""
                    })
                }
            }

            function saveSavedCommands() {
                var commands = []
                for (var i = 0; i < savedCommandModel.count; i++) {
                    var item = savedCommandModel.get(i)
                    commands.push({
                        "commandName": item.commandName,
                        "commandText": item.commandText
                    })
                }
                savedCommandSettings.commandsJson = JSON.stringify(commands)
            }

            function setConsoleCommand(commandText) {
                if (!commandText || commandText.trim() === "") {
                    return
                }

                if (_separateCommandInput) {
                    commandInput.text = commandText
                    commandInput.forceActiveFocus()
                } else {
                    getCommandAndClear()
                    textConsole.insert(textConsole.length, commandText)
                    textConsole.cursorPosition = textConsole.length
                    textConsole.forceActiveFocus()
                }
                scrollToBottom()
            }

            function sendSavedCommand(commandText) {
                if (!commandText || commandText.trim() === "") {
                    return
                }
                conController.sendCommand(commandText)
                scrollToBottom()
            }

            Component.onCompleted: loadSavedCommands()

            Connections {
                target: conController

                onDataChanged: {
                    if (isLoaded) {
                        // rate-limit updates to reduce CPU load
                        updateTimer.start();
                    }
                }
            }

            Timer {
                id: updateTimer
                interval: 30
                running: false
                repeat: false
                onTriggered: {
                    // only update if scroll bar is at the bottom
                    if (flickable.atYEnd) {
                        // backup & restore cursor & command
                        const command = getCommand()
                        const cursor = textConsole.cursorPosition - _consoleOutputLen
                        textConsole.text = conController.text
                        _consoleOutputLen = textConsole.length
                        textConsole.insert(textConsole.length, command)
                        textConsole.cursorPosition = textConsole.length
                        scrollToBottom()
                        if (cursor >= 0) {
                            // We could restore the selection here too...
                            textConsole.cursorPosition = _consoleOutputLen + cursor
                        }
                    } else {
                        updateTimer.start();
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: ScreenTools.defaultFontPixelWidth
                layoutDirection: Qt.RightToLeft

                Rectangle {
                    Layout.preferredWidth: Math.max(ScreenTools.defaultFontPixelWidth * 34, 260)
                    Layout.fillHeight: true
                    visible: savedCommandPanelVisible
                    color: qgcPal.windowShade
                    border.color: qgcPal.text
                    border.width: 1
                    radius: ScreenTools.defaultFontPixelHeight / 3

                    ColumnLayout {
                        id: savedCommandLayout
                        anchors.fill: parent
                        anchors.margins: ScreenTools.defaultFontPixelHeight / 2
                        spacing: ScreenTools.defaultFontPixelHeight / 2
                        layoutDirection: Qt.LeftToRight

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: ScreenTools.defaultFontPixelHeight / 2

                            QGCLabel {
                                Layout.fillWidth: true
                                text: qsTr("快捷命令")
                                font.bold: true
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: ScreenTools.defaultFontPixelWidth

                                QGCButton {
                                    Layout.fillWidth: true
                                    text: qsTr("收起")
                                    onClicked: savedCommandPanelVisible = false
                                }

                                QGCButton {
                                    Layout.fillWidth: true
                                    text: qsTr("添加命令")
                                    onClicked: savedCommandDialogComponent.createObject(mainWindow, {
                                        editIndex: -1,
                                        initialName: "",
                                        initialCommand: ""
                                    }).open()
                                }
                            }
                        }

                        QGCLabel {
                            Layout.fillWidth: true
                            visible: savedCommandModel.count === 0
                            text: qsTr("暂无保存的命令。可以添加 listener sensor_mag 这类命令，一键填入控制台。")
                            wrapMode: Text.WordWrap
                            color: qgcPal.text
                            font.pointSize: ScreenTools.smallFontPointSize
                        }

                        ListView {
                            id: savedCommandListView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: ScreenTools.defaultFontPixelHeight / 2
                            model: savedCommandModel

                            delegate: Rectangle {
                                width: savedCommandListView.width
                                height: ScreenTools.defaultFontPixelHeight * 7.2
                                color: qgcPal.window
                                border.color: qgcPal.button
                                border.width: 1
                                radius: ScreenTools.defaultFontPixelHeight / 3

                                property real _margin: ScreenTools.defaultFontPixelHeight / 2
                                property real _gap: ScreenTools.defaultFontPixelHeight / 2
                                property real _buttonHeight: ScreenTools.defaultFontPixelHeight * 2.2

                                Rectangle {
                                    id: savedCommandNameButton
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: parent._margin
                                    height: parent._buttonHeight
                                    color: savedCommandNameMouse.pressed ? qgcPal.buttonHighlight : (savedCommandNameMouse.containsMouse ? qgcPal.button : qgcPal.windowShade)
                                    border.color: qgcPal.button
                                    border.width: 1
                                    radius: ScreenTools.defaultFontPixelHeight / 4

                                    QGCLabel {
                                        anchors.fill: parent
                                        anchors.leftMargin: ScreenTools.defaultFontPixelWidth
                                        anchors.rightMargin: ScreenTools.defaultFontPixelWidth
                                        text: commandName !== "" ? commandName : commandText
                                        color: qgcPal.text
                                        elide: Text.ElideRight
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    MouseArea {
                                        id: savedCommandNameMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: setConsoleCommand(commandText)
                                    }
                                }

                                Row {
                                    id: savedCommandActions
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: savedCommandNameButton.bottom
                                    anchors.topMargin: parent._gap
                                    anchors.leftMargin: parent._margin
                                    anchors.rightMargin: parent._margin
                                    height: parent._buttonHeight
                                    spacing: ScreenTools.defaultFontPixelWidth

                                    Rectangle {
                                        width: (savedCommandActions.width - savedCommandActions.spacing * 2) / 3
                                        height: parent.height
                                        color: sendMouse.pressed ? qgcPal.buttonHighlight : (sendMouse.containsMouse ? qgcPal.button : qgcPal.windowShade)
                                        border.color: qgcPal.button
                                        border.width: 1
                                        radius: ScreenTools.defaultFontPixelHeight / 4

                                        QGCLabel {
                                            anchors.fill: parent
                                            text: qsTr("发送")
                                            color: qgcPal.text
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        MouseArea {
                                            id: sendMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: sendSavedCommand(commandText)
                                        }
                                    }

                                    Rectangle {
                                        width: (savedCommandActions.width - savedCommandActions.spacing * 2) / 3
                                        height: parent.height
                                        color: editMouse.pressed ? qgcPal.buttonHighlight : (editMouse.containsMouse ? qgcPal.button : qgcPal.windowShade)
                                        border.color: qgcPal.button
                                        border.width: 1
                                        radius: ScreenTools.defaultFontPixelHeight / 4

                                        QGCLabel {
                                            anchors.fill: parent
                                            text: qsTr("编辑")
                                            color: qgcPal.text
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        MouseArea {
                                            id: editMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: savedCommandDialogComponent.createObject(mainWindow, {
                                                editIndex: index,
                                                initialName: commandName,
                                                initialCommand: commandText
                                            }).open()
                                        }
                                    }

                                    Rectangle {
                                        width: (savedCommandActions.width - savedCommandActions.spacing * 2) / 3
                                        height: parent.height
                                        color: deleteMouse.pressed ? qgcPal.buttonHighlight : (deleteMouse.containsMouse ? qgcPal.button : qgcPal.windowShade)
                                        border.color: qgcPal.button
                                        border.width: 1
                                        radius: ScreenTools.defaultFontPixelHeight / 4

                                        QGCLabel {
                                            anchors.fill: parent
                                            text: qsTr("删除")
                                            color: qgcPal.text
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        MouseArea {
                                            id: deleteMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                savedCommandModel.remove(index)
                                                saveSavedCommands()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                QGCButton {
                    Layout.alignment: Qt.AlignTop
                    visible: !savedCommandPanelVisible
                    text: qsTr("快捷命令")
                    onClicked: savedCommandPanelVisible = true
                }

                QGCFlickable {
                    id: flickable
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: textConsole.width
                    contentHeight: textConsole.height

                    TextArea.flickable: TextArea {
                        id: textConsole
                        width: availableWidth
                        wrapMode: Text.WordWrap
                        readOnly: _separateCommandInput
                        textFormat: TextEdit.RichText
                        inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhMultiLine
                        text: "> "
                        focus: true
                        color: qgcPal.text
                        selectedTextColor: qgcPal.windowShade
                        selectionColor: qgcPal.text
                        font.pointSize: ScreenTools.defaultFontPointSize
                        font.family: ScreenTools.fixedFontFamily

                        Component.onCompleted: {
                            root.isLoaded = true
                            _consoleOutputLen = textConsole.length
                            textConsole.cursorPosition = _consoleOutputLen
                            if (!_separateCommandInput) {
                                textConsole.forceActiveFocus()
                            }
                        }

                        background: Rectangle { color: qgcPal.windowShade }

                        Keys.onPressed: (event) => {
                        // ignore tabs
                        if (event.key == Qt.Key_Tab) {
                            event.accepted = true
                        }

                        // ignore for now
                        if (event.matches(StandardKey.Cut)) {
                            event.accepted = true
                        }

                        if (!event.matches(StandardKey.Copy) &&
                            event.key != Qt.Key_Escape &&
                            event.key != Qt.Key_Insert &&
                            event.key != Qt.Key_Pause &&
                            event.key != Qt.Key_Print &&
                            event.key != Qt.Key_SysReq &&
                            event.key != Qt.Key_Clear &&
                            event.key != Qt.Key_Home &&
                            event.key != Qt.Key_End &&
                            event.key != Qt.Key_Left &&
                            event.key != Qt.Key_Up &&
                            event.key != Qt.Key_Right &&
                            event.key != Qt.Key_Down &&
                            event.key != Qt.Key_PageUp &&
                            event.key != Qt.Key_PageDown &&
                            event.key != Qt.Key_Shift &&
                            event.key != Qt.Key_Control &&
                            event.key != Qt.Key_Meta &&
                            event.key != Qt.Key_Alt &&
                            event.key != Qt.Key_AltGr &&
                            event.key != Qt.Key_CapsLock &&
                            event.key != Qt.Key_NumLock &&
                            event.key != Qt.Key_ScrollLock &&
                            event.key != Qt.Key_Super_L &&
                            event.key != Qt.Key_Super_R &&
                            event.key != Qt.Key_Menu &&
                            event.key != Qt.Key_Hyper_L &&
                            event.key != Qt.Key_Hyper_R &&
                            event.key != Qt.Key_Direction_L &&
                            event.key != Qt.Key_Direction_R) {
                            // Note: dead keys do not generate keyPressed event on linux, see
                            // https://bugreports.qt.io/browse/QTBUG-79216

                            scrollToBottom()

                            // ensure cursor position is at an editable region
                            if (textConsole.selectionStart < _consoleOutputLen) {
                                textConsole.select(_consoleOutputLen, textConsole.selectionEnd)
                            }

                            if (textConsole.cursorPosition < _consoleOutputLen) {
                                textConsole.cursorPosition = textConsole.length
                            }
                        }

                        switch (event.key) {
                        case Qt.Key_Left:
                            // don't move beyond current command
                            if (textConsole.cursorPosition == _consoleOutputLen) {
                                event.accepted = true
                            }
                            break;
                        case Qt.Key_Backspace:
                            if (textConsole.cursorPosition <= _consoleOutputLen) {
                                event.accepted = true
                            }
                            break;
                        case Qt.Key_Enter:
                        case Qt.Key_Return:
                            conController.sendCommand(getCommandAndClear())
                            event.accepted = true
                            break;
                        default:
                            break;
                        }

                        if (event.matches(StandardKey.Paste)) {
                            pasteFromClipboard()
                            event.accepted = true
                        }

                        // command history
                        if (event.key == Qt.Key_Up) {
                            const command = conController.historyUp(getCommandAndClear())
                            textConsole.insert(textConsole.length, command)
                            textConsole.cursorPosition = textConsole.length
                            event.accepted = true
                        } else if (event.key == Qt.Key_Down) {
                            const command = conController.historyDown(getCommandAndClear())
                            textConsole.insert(textConsole.length, command)
                            textConsole.cursorPosition = textConsole.length
                            event.accepted = true
                        }
                    }
                }
            }
            }

            Component {
                id: savedCommandDialogComponent

                QGCPopupDialog {
                    title: editIndex >= 0 ? qsTr("编辑命令") : qsTr("添加命令")
                    buttons: Dialog.Save | Dialog.Cancel
                    acceptButtonEnabled: nameField.text !== "" && commandField.text !== ""

                    property int editIndex: -1
                    property string initialName: ""
                    property string initialCommand: ""

                    onAccepted: {
                        var commandItem = {
                            "commandName": nameField.text,
                            "commandText": commandField.text
                        }

                        if (editIndex >= 0) {
                            savedCommandModel.set(editIndex, commandItem)
                        } else {
                            savedCommandModel.append(commandItem)
                        }
                        saveSavedCommands()
                    }

                    ColumnLayout {
                        width: Math.max(ScreenTools.defaultFontPixelWidth * 42, 420)
                        spacing: ScreenTools.defaultFontPixelHeight / 2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: ScreenTools.defaultFontPixelWidth

                            QGCLabel { text: qsTr("名称") }
                            QGCTextField {
                                id: nameField
                                Layout.fillWidth: true
                                text: initialName
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: ScreenTools.defaultFontPixelWidth

                            QGCLabel { text: qsTr("命令") }
                            QGCTextField {
                                id: commandField
                                Layout.fillWidth: true
                                text: initialCommand
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: _separateCommandInput

                QGCTextField {
                    id: commandInput
                    Layout.fillWidth: true
                    placeholderText:  qsTr("在此输入命令...")
                    inputMethodHints: Qt.ImhNoAutoUppercase
                    onAccepted: sendCommand()

                    function sendCommand() {
                        conController.sendCommand(text)
                        text = ""
                        scrollToBottom()
                    }

                }

                QGCButton {
                    text: qsTr("发送")
                    onClicked: commandInput.sendCommand()
                }
            }
        }
    } // Component
} // AnalyzePage
