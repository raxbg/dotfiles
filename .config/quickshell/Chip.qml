import QtQuick
import Quickshell

Item {
    id: chip

    property alias text: label.text
    property alias textFormat: label.textFormat
    property alias foreground: label.color
    property alias font: label.font
    property int leftPadding: 7
    property int rightPadding: 7
    property real leftRadius: 15
    property real rightRadius: 15
    property color background: "transparent"
    property color hoverBackground: "#33dcdfe1"
    property color selectedBackground: "#33dcdfe1"
    readonly property bool hovered: mouse.containsMouse
    property string tip: ""
    property bool richTip: false
    property bool selected: false
    property bool interactive: false
    property int buttons: Qt.LeftButton
    signal clicked(int button)
    signal wheel(int delta)

    implicitWidth: Math.ceil(label.implicitWidth) + leftPadding + rightPadding
    implicitHeight: 30
    clip: true

    Rectangle {
        anchors.fill: parent
        topLeftRadius: chip.leftRadius
        bottomLeftRadius: chip.leftRadius
        topRightRadius: chip.rightRadius
        bottomRightRadius: chip.rightRadius
        color: chip.hovered ? chip.hoverBackground : chip.selected ? chip.selectedBackground : chip.background
        Behavior on color { ColorAnimation { duration: 700 } }
    }

    Text {
        id: label
        anchors.fill: parent
        anchors.leftMargin: chip.leftPadding
        anchors.rightMargin: chip.rightPadding
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        textFormat: Text.PlainText
        color: "#dcdfe1"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14
        font.bold: true
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: chip.interactive ? chip.buttons : Qt.NoButton
        cursorShape: chip.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: event => chip.clicked(event.button)
        onWheel: event => {
            if (event.angleDelta.y)
                chip.wheel(event.angleDelta.y)
            event.accepted = chip.interactive
        }
    }

    Timer {
        id: hoverDelay
        interval: 500
        running: chip.tip !== "" && chip.visible && mouse.containsMouse
        onTriggered: tooltip.hoverReady = true
    }

    PopupWindow {
        id: tooltip
        property bool hoverReady: false
        // qmllint disable missing-property
        anchor.item: chip
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        // qmllint enable missing-property
        visible: chip.visible && chip.tip !== "" && mouse.containsMouse && hoverReady
        onVisibleChanged: if (!visible) hoverReady = false
        implicitWidth: Math.min(440, detail.implicitWidth + 20)
        implicitHeight: detail.implicitHeight + 16
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "#242e42"
            border.color: "#80dcdfe1"
            border.width: 2
            radius: 15

            Text {
                id: detail
                anchors.fill: parent
                anchors.margins: 8
                text: chip.tip
                textFormat: chip.richTip ? Text.StyledText : Text.PlainText
                wrapMode: Text.Wrap
                color: "#dcdfe1"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                font.bold: true
            }
        }
    }
}
