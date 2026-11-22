pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: popups

    required property ShellScreen targetScreen
    property bool doNotDisturb: false
    readonly property var entries: server.trackedNotifications.values

    screen: targetScreen
    visible: targetScreen !== null && entries.length > 0
    anchors { top: true; right: true }
    margins { top: 60; right: 10 }
    implicitWidth: 360
    implicitHeight: cards.implicitHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notifications"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    NotificationServer {
        id: server
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        keepOnReload: true
        onNotification: notice => {
            if (popups.doNotDisturb || !(notice.summary || notice.body || notice.image))
                return;
            if (popups.entries.length >= 5)
                popups.entries[0].expire();
            notice.tracked = true;
        }
    }

    IpcHandler {
        target: "notifications"
        function dismiss_all(): void {
            for (const notice of popups.entries.slice())
                notice.dismiss();
        }
        function dnd_toggle(): bool {
            popups.doNotDisturb = !popups.doNotDisturb;
            if (popups.doNotDisturb)
                dismiss_all();
            return popups.doNotDisturb;
        }
    }

    Column {
        id: cards
        width: parent.width
        spacing: 8

        Repeater {
            model: ScriptModel {
                values: popups.entries.slice().reverse()
                objectProp: "id"
            }

            Rectangle {
                id: card
                required property Notification modelData
                readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
                readonly property var actions: Array.from(modelData.actions).slice(0, 4)
                readonly property color accent: critical ? "#FF6262" : modelData.urgency === NotificationUrgency.Low ? "#9ba7b9" : "#93c5fd"
                readonly property int timeout: modelData.expireTimeout > 0 ? modelData.expireTimeout :
                    critical || modelData.expireTimeout === 0 ? 0 : 5000
                property real remaining: 1

                width: cards.width
                height: contents.implicitHeight + 24
                radius: 15
                color: "#242e42"
                border.color: critical ? accent : "#80dcdfe1"
                Accessible.name: (modelData.appName || "Notification") + ": " + modelData.summary

                HoverHandler { id: hover }
                NumberAnimation {
                    id: expiry
                    target: card
                    property: "remaining"
                    from: 1
                    to: 0
                    duration: card.timeout
                    paused: hover.hovered
                    onFinished: card.modelData.expire()
                }

                function restartExpiry(): void {
                    expiry.stop();
                    remaining = 1;
                    if (timeout > 0)
                        expiry.start();
                }

                Component.onCompleted: restartExpiry()
                Connections {
                    target: card.modelData
                    function onSummaryChanged() { Qt.callLater(card.restartExpiry); }
                    function onBodyChanged() { Qt.callLater(card.restartExpiry); }
                    function onExpireTimeoutChanged() { Qt.callLater(card.restartExpiry); }
                }

                Rectangle {
                    x: 6
                    y: 12
                    width: 3
                    height: parent.height - 24
                    radius: 2
                    color: card.accent
                }

                ColumnLayout {
                    id: contents
                    anchors.fill: parent
                    anchors.margins: 12
                    anchors.leftMargin: 16
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true

                        Item {
                            Layout.preferredWidth: 17
                            Layout.preferredHeight: 17

                            IconImage {
                                id: appIcon
                                anchors.fill: parent
                                source: card.modelData.appIcon ? Quickshell.iconPath(card.modelData.appIcon, true) : ""
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: !appIcon.source.toString()
                                text: "󰂚"
                                color: card.accent
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: card.modelData.appName || "Notification"
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            color: "#b5bfce"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                        }
                        Chip {
                            implicitHeight: 22
                            leftPadding: 6
                            rightPadding: 6
                            text: "×"
                            interactive: true
                            Accessible.role: Accessible.Button
                            Accessible.name: "Dismiss notification"
                            Accessible.onPressAction: card.modelData.dismiss()
                            onClicked: card.modelData.dismiss()
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: card.modelData.summary
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        color: "#dcdfe1"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        font.bold: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        visible: !!card.modelData.image || !!card.modelData.body

                        Image {
                            visible: !!card.modelData.image
                            source: card.modelData.image
                            sourceSize: Qt.size(48, 48)
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 48
                            fillMode: Image.PreserveAspectFit
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: card.modelData.body
                            textFormat: Text.PlainText
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            color: "#dcdfe1"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        visible: card.actions.length > 0
                        spacing: 5
                        Repeater {
                            model: card.actions
                            Chip {
                                required property NotificationAction modelData
                                width: Math.min(150, implicitWidth)
                                implicitHeight: 24
                                background: "#1adcdfe1"
                                interactive: true
                                text: modelData.text || "Open"
                                Accessible.role: Accessible.Button
                                Accessible.name: text
                                Accessible.onPressAction: modelData.invoke()
                                onClicked: modelData.invoke()
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 2
                        visible: card.timeout > 0
                        color: "#33dcdfe1"
                        Rectangle {
                            width: parent.width * card.remaining
                            height: parent.height
                            color: card.accent
                        }
                    }
                }
            }
        }
    }
}
