import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    id: osd

    required property ShellScreen targetScreen
    function showLevel(icon: string, title: string, level: int, muted: bool): void {
        const pill = title === "Brightness" ? brightness : audio;
        pill.showLevel(icon, title, level, muted);
    }

    // The Wayland backend provides the concrete PanelWindow at runtime.
    // qmllint disable uncreatable-type
    PanelWindow {
        // qmllint enable uncreatable-type
        anchors.right: true
        // qmllint disable missing-property
        margins.right: 10
        // qmllint enable missing-property
        implicitWidth: 40
        implicitHeight: pills.implicitHeight
        screen: osd.targetScreen
        visible: osd.targetScreen !== null && (audio.shown || brightness.shown)
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-osd"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region {}
        color: "transparent"

        Column {
            id: pills
            spacing: 10
            OsdPill { id: audio }
            OsdPill { id: brightness }
        }
    }
}
