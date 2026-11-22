import QtQuick

Rectangle {
    id: pill

    property string icon: ""
    property string title: ""
    property int level: 0
    property bool muted: false
    property bool shown: false

    function showLevel(icon: string, title: string, level: int, muted: bool): void {
        pill.icon = icon;
        pill.title = title;
        pill.level = level;
        pill.muted = muted;
        pill.shown = true;
        // Restarting the timer must not unmap the popup.
        dismiss.restart();
    }

    visible: shown
    width: 40
    height: 200
    radius: 20
    color: "#242e42"
    border.color: "#80dcdfe1"
    Accessible.role: Accessible.ProgressBar
    Accessible.name: title + ": " + (muted ? "Muted" : level + "%")

    Timer {
        id: dismiss
        interval: 1500
        onTriggered: pill.shown = false
    }

    Text {
        id: valueLabel
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 11
        text: pill.muted ? "Mute" : pill.level + "%"
        color: "#dcdfe1"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 11
        font.bold: true
    }

    Rectangle {
        id: track
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: valueLabel.bottom
        anchors.bottom: glyph.top
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        width: 8
        radius: 4
        color: "#33dcdfe1"

        Rectangle {
            anchors.bottom: parent.bottom
            width: track.width
            height: pill.muted ? 0 : track.height * Math.min(100, Math.max(0, pill.level)) / 100
            radius: track.radius
            color: glyph.color
            Behavior on height { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
        }
    }

    Text {
        id: glyph
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        text: pill.icon
        color: pill.muted ? "#FF4040" : pill.title === "Brightness" ? "#FFD700" : "#dcdfe1"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 16
    }
}
