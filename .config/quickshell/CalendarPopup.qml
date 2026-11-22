pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

PopupWindow {
    id: calendar

    required property Item trigger
    required property date today
    property date shownMonth: today

    function moveMonth(offset: int): void {
        shownMonth = new Date(shownMonth.getFullYear(), shownMonth.getMonth() + offset, 1);
    }

    // qmllint disable missing-property
    anchor.item: trigger
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    // qmllint enable missing-property
    grabFocus: true
    visible: false
    implicitWidth: 350
    implicitHeight: body.implicitHeight + 40
    color: "transparent"

    onVisibleChanged: if (visible) {
        shownMonth = today;
        body.forceActiveFocus();
    }

    Rectangle {
        anchors.fill: parent
        radius: 15
        color: "#242e42"
        border.color: "#24dcdfe1"

        ColumnLayout {
            id: body
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            Keys.onEscapePressed: calendar.visible = false
            Keys.onLeftPressed: calendar.moveMonth(-1)
            Keys.onRightPressed: calendar.moveMonth(1)

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: Qt.formatDate(calendar.shownMonth, "MMMM yyyy")
                    color: "#dcdfe1"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    font.bold: true
                }

                Chip {
                    text: "‹"
                    font.pixelSize: 19
                    interactive: true
                    hoverBackground: "#1adcdfe1"
                    Accessible.role: Accessible.Button
                    Accessible.name: "Previous month"
                    Accessible.onPressAction: calendar.moveMonth(-1)
                    onClicked: calendar.moveMonth(-1)
                }
                Chip {
                    text: "›"
                    font.pixelSize: 19
                    interactive: true
                    hoverBackground: "#1adcdfe1"
                    Accessible.role: Accessible.Button
                    Accessible.name: "Next month"
                    Accessible.onPressAction: calendar.moveMonth(1)
                    onClicked: calendar.moveMonth(1)
                }
            }

            DayOfWeekRow {
                Layout.fillWidth: true
                spacing: days.spacing
                locale: days.locale
                delegate: Text {
                    required property var model
                    text: model.shortName
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: "#9ba7b9"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                }
            }

            MonthGrid {
                id: days
                Layout.fillWidth: true
                Layout.preferredHeight: 208
                padding: 0
                spacing: 4
                locale: Qt.locale("en_GB")
                month: calendar.shownMonth.getMonth()
                year: calendar.shownMonth.getFullYear()
                delegate: Item {
                    id: dayCell
                    required property var model
                    readonly property bool isToday: model.year === calendar.today.getFullYear() &&
                        model.month === calendar.today.getMonth() && model.day === calendar.today.getDate()

                    Rectangle {
                        anchors.centerIn: parent
                        width: 30
                        height: 30
                        radius: 10
                        color: "#2693c5fd"
                        visible: dayCell.isToday
                    }
                    Text {
                        anchors.centerIn: parent
                        text: dayCell.model.day
                        color: dayCell.isToday ? "#93c5fd" : dayCell.model.month === days.month ? "#dcdfe1" : "#8090a7"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        font.bold: dayCell.isToday
                    }
                }
            }

            Chip {
                Layout.alignment: Qt.AlignRight
                text: "Today"
                foreground: "#93c5fd"
                font.pixelSize: 12
                interactive: true
                hoverBackground: "#1adcdfe1"
                Accessible.role: Accessible.Button
                Accessible.name: "Go to current month"
                Accessible.onPressAction: calendar.shownMonth = calendar.today
                onClicked: calendar.shownMonth = calendar.today
            }
        }
    }
}
