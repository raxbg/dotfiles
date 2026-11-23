//@ pragma UseQApplication
// Native tray menus use the Qt platform palette, not the bar's QML colors.
//@ pragma Env QT_QPA_PLATFORMTHEME=gtk3
//@ pragma Env GTK_THEME=Adwaita:dark
//@ pragma Env TZ=Europe/Sofia
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Wayland

ShellRoot {
    id: root

    readonly property ShellScreen mainScreen: {
        const screens = Quickshell.screens;
        if (!screens.length)
            return null;
        const monitors = Hyprland.monitors.values;
        const origin = monitors.find(monitor => monitor.x === 0 && monitor.y === 0);
        return screens.find(screen => screen.name === origin?.name) ?? screens[0];
    }
    readonly property var persistentIds: [1, 2, 3, 4, 5, 6, 11, 12, 13, 14, 15, 16]
    readonly property var workspaceIcons: ({2: "", 3: "", 4: "", 5: "", 6: "󰖳", 12: "", 14: "", 16: "󰖳"})
    readonly property var workspaces: Hyprland.workspaces.values
    readonly property var workspaceIds: [...new Set(persistentIds.concat(workspaces.filter(ws => ws.id > 0).map(ws => ws.id)))].sort((a, b) => a - b)

    readonly property var speaker: Pipewire.defaultAudioSink?.audio ?? null
    readonly property var mic: Pipewire.defaultAudioSource?.audio ?? null
    readonly property var battery: UPower.displayDevice
    readonly property int batteryPercent: Math.round((battery?.percentage ?? 0) * 100)
    readonly property bool charging: battery?.state === UPowerDeviceState.Charging

    readonly property string backlight: "/sys/class/backlight/intel_backlight/"
    property int brightness: -1
    readonly property int maxBrightness: Number(maxBrightnessFile.text())
    readonly property int brightnessPercent: maxBrightness > 0 && brightness >= 0 ? Math.round(brightness * 100 / maxBrightness) : -1
    property var cpuCounters: null
    property int cpuUsage: -1
    property real ramUsed: 0
    property real ramTotal: 0
    property string temperature: ""
    property string agentText: "○ agents: unavailable"
    property string agentTip: "Stop Waybar before starting Quickshell to enable agent status."

    function percent(node) {
        return Math.round(node.volume * 100) + "%";
    }

    function coloredIcon(glyph: string, color: string): string {
        return '<font color="' + color + '">' + glyph + '</font>';
    }

    function speakerIcon(): string {
        if (!speaker || speaker.muted)
            return coloredIcon("󰖁", "#FF4040");
        const form = Pipewire.defaultAudioSink?.properties["device.form-factor"];
        if (form === "headphone" || form === "headset" || form === "hands-free")
            return coloredIcon("", "#BF00FF");
        if (form === "phone" || form === "portable")
            return coloredIcon("", "#00FFFF");
        if (form === "car")
            return coloredIcon("", "#FFA500");
        const level = Math.min(2, Math.floor(speaker.volume * 3));
        return coloredIcon(["", "", ""][level], ["#808080", "#FFFF66", "#16a34a"][level]);
    }

    function focusWorkspace(selector) {
        Hyprland.dispatch('hl.dsp.focus({workspace = "' + selector + '"})');
    }

    SystemClock { id: clock; precision: SystemClock.Seconds }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource].filter(node => node !== null)
    }

    Connections {
        target: root.speaker
        function onVolumesChanged() { showVolume(); }
        function onMutedChanged() { showVolume(); }
        function showVolume() {
            const node = root.speaker;
            if (node)
                osd.showLevel(node.muted ? "󰖁" : "", "Volume", Math.round(node.volume * 100), node.muted);
        }
    }

    Connections {
        target: root.mic
        function onMutedChanged() {
            const node = root.mic;
            if (node)
                osd.showLevel(node.muted ? "" : "", "Microphone", Math.round(node.volume * 100), node.muted);
        }
    }

    FileView {
        id: cpuFile
        path: "/proc/stat"
        blockLoading: false
        onLoaded: {
            const fields = text().split("\n", 1)[0].trim().split(/\s+/).slice(1, 9).map(Number);
            if (fields.length < 8 || fields.some(field => !Number.isFinite(field)))
                return;
            const total = fields.reduce((sum, field) => sum + field, 0);
            const idle = fields[3] + fields[4];
            if (root.cpuCounters && total > root.cpuCounters.total) {
                const usage = 1 - (idle - root.cpuCounters.idle) / (total - root.cpuCounters.total);
                root.cpuUsage = Math.round(Math.max(0, Math.min(1, usage)) * 100);
            }
            root.cpuCounters = { total, idle };
        }
    }

    FileView {
        id: ramFile
        path: "/proc/meminfo"
        blockLoading: false
        onLoaded: {
            const contents = text();
            const total = Number(contents.match(/^MemTotal:\s+(\d+)/m)?.[1]);
            const available = Number(contents.match(/^MemAvailable:\s+(\d+)/m)?.[1]);
            if (total > 0 && available >= 0) {
                root.ramUsed = (total - available) / 1048576;
                root.ramTotal = total / 1048576;
            }
        }
    }

    FileView {
        id: brightnessFile
        path: root.backlight + "brightness"
        blockLoading: false
        printErrors: false
        onLoaded: {
            const value = parseInt(text(), 10);
            if (!Number.isFinite(value) || value === root.brightness)
                return;
            const previous = root.brightness;
            root.brightness = value;
            if (previous >= 0 && root.brightnessPercent >= 0)
                osd.showLevel("󰃠", "Brightness", root.brightnessPercent, false);
        }
    }
    FileView {
        id: maxBrightnessFile
        path: root.backlight + "max_brightness"
        blockLoading: false
        printErrors: false
    }
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            cpuFile.reload();
            ramFile.reload();
        }
    }
    Timer {
        interval: 150
        running: true
        repeat: true
        onTriggered: brightnessFile.reload()
    }
    Process {
        id: setBrightness
        onExited: brightnessFile.reload()
    }

    Process {
        id: sensors
        command: ["sensors"]
        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.match(/^Tctl:\s*([+-]?[\d.]+)/m) ?? text.match(/^Package id 0:\s*([+-]?[\d.]+)/m);
                root.temperature = match ? Number(match[1]).toFixed(2) : "";
            }
        }
    }
    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: sensors.running = true
    }

    Process {
        running: true
        // The Waybar helper owns a shared socket and unlinks it on startup.
        command: ["bash", "-c", `
            set -eu
            socket="$XDG_RUNTIME_DIR/waybar-agent-status/socket"
            if pgrep -u "$(id -u)" -x waybar >/dev/null || ss -xlH | grep -F -- "$socket " >/dev/null; then
                exit 0
            fi
            bin="$XDG_RUNTIME_DIR/quickshell-agent-status"
            go build -o "$bin" "$HOME/.config/waybar/agent-status.go"
            exec "$bin"
        `]
        stdout: SplitParser {
            onRead: line => {
                try {
                    const update = JSON.parse(line);
                    if (typeof update.text === "string" && typeof update.tooltip === "string") {
                        root.agentText = update.text.replace(/<span color="(#[a-fA-F0-9]{6})">/g, '<font color="$1">').replace(/<\/span>/g, "</font>");
                        root.agentTip = update.tooltip.replace(/\n/g, "<br>");
                    }
                } catch (error) {
                    console.warn("Invalid agent status JSON:", error);
                }
            }
        }
        onExited: code => {
            root.agentText = "○ agents: unavailable";
            if (code !== 0)
                root.agentTip = "Agent status helper failed to start or exited.";
        }
    }

    Osd {
        id: osd
        targetScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name) ?? root.mainScreen
    }

    NotificationPopups { targetScreen: root.mainScreen }

    AppLauncher {
        targetScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name) ?? root.mainScreen
    }

    component Section: Rectangle {
        height: 40
        radius: 20
        color: "#242e42"
    }

    component StatusChip: Chip {
        hoverBackground: "#1cdcdfe1"
        textFormat: Text.StyledText
        leftRadius: 0
        rightRadius: 0
    }

    PanelWindow {
        id: panel
        screen: root.mainScreen
        visible: root.mainScreen !== null
        anchors { top: true; left: true; right: true }
        implicitHeight: 50
        exclusiveZone: 50
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell-bar"
        color: "transparent"

        Section {
            id: workspaceSection
            x: 5
            y: 10
            width: workspaceRow.implicitWidth + 14

            Rectangle {
                anchors.centerIn: parent
                width: workspaceRow.implicitWidth + 4
                height: 30
                radius: 15
                color: "#0ddcdfe1"
            }

            Row {
                id: workspaceRow
                anchors.centerIn: parent
                spacing: 4
                Repeater {
                    model: root.workspaceIds
                    Chip {
                        required property int modelData
                        readonly property var workspace: root.workspaces.find(ws => ws.id === modelData)
                        readonly property bool empty: !(workspace?.lastIpcObject.windows > 0)
                        implicitWidth: 30
                        leftPadding: 0
                        rightPadding: 0
                        font.family: "JetBrainsMono Nerd Font Mono"
                        font.pixelSize: 20
                        text: root.workspaceIcons[modelData] ?? ""
                        tip: "Workspace " + (workspace?.name ?? modelData)
                        background: "#1fdcdfe1"
                        hoverBackground: "#4ddcdfe1"
                        selectedBackground: "#dcdfe1"
                        foreground: hovered || selected ? "#242e42" : "#a6dcdfe1"
                        opacity: hovered || !empty ? 1 : selected ? 0.75 : 0.2
                        selected: workspace?.active ?? false
                        interactive: true
                        onClicked: root.focusWorkspace(modelData)
                        onWheel: delta => root.focusWorkspace(delta > 0 ? "e-1" : "e+1")
                    }
                }
            }
        }

        Section {
            id: center
            readonly property real room: Math.max(0, statusSection.x - workspaceSection.x - workspaceSection.width - 12)
            width: Math.min(room, clockChip.implicitWidth + agentChip.implicitWidth + 10)
            visible: width >= clockChip.implicitWidth + 10
            x: Math.max(workspaceSection.x + workspaceSection.width + 6, Math.min((panel.width - width) / 2, statusSection.x - width - 6))
            y: 10

            Row {
                x: 5
                anchors.verticalCenter: parent.verticalCenter
                Chip {
                    id: clockChip
                    leftPadding: 15
                    rightPadding: 15
                    text: " " + Qt.formatDateTime(clock.date, "dd - HH:mm:ss") + " "
                    tip: calendarPopup.visible ? "" : "Open calendar"
                    selected: calendarPopup.visible
                    interactive: true
                    buttons: Qt.LeftButton | Qt.RightButton
                    onClicked: button => {
                        if (button === Qt.RightButton)
                            DesktopEntries.byId("org.gnome.Calendar")?.execute();
                        else
                            calendarPopup.visible = !calendarPopup.visible;
                    }

                    CalendarPopup {
                        id: calendarPopup
                        trigger: clockChip
                        today: clock.date
                    }
                }
                Chip {
                    id: agentChip
                    width: Math.max(0, center.width - clockChip.width - 10)
                    visible: width >= 20
                    leftPadding: 12
                    rightPadding: 12
                    background: "#1adcdfe1"
                    text: root.agentText
                    textFormat: Text.StyledText
                    tip: root.agentTip
                    richTip: true
                }
            }
        }

        Section {
            id: statusSection
            anchors.right: parent.right
            anchors.rightMargin: 5
            y: 10
            width: statusRow.implicitWidth + 16

            // A single fill avoids seams between chips at fractional display scales.
            Rectangle {
                x: statusRow.x + audioChip.x
                y: statusRow.y
                width: statusRow.width - audioChip.x
                height: audioChip.height
                radius: 15
                color: "#1adcdfe1"
            }

            Row {
                id: statusRow
                anchors.centerIn: parent

                Row {
                    spacing: 5
                    Repeater {
                        model: SystemTray.items
                        delegate: Item {
                            id: trayItem
                            required property SystemTrayItem modelData
                            visible: modelData.status !== Status.Passive && modelData.id !== "blueman"
                            width: 24
                            height: 30

                            Chip {
                                anchors.fill: parent
                                hoverBackground: "#1adcdfe1"
                                tip: [trayItem.modelData.tooltipTitle || trayItem.modelData.title, trayItem.modelData.tooltipDescription].filter(Boolean).join("\n")
                                interactive: true
                                buttons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                onClicked: button => {
                                    if (button === Qt.RightButton || (button === Qt.LeftButton && (trayItem.modelData.onlyMenu || trayItem.modelData.id === "nm-applet"))) {
                                        if (trayItem.modelData.hasMenu) {
                                            const pos = trayItem.mapToItem(panel.contentItem, 0, trayItem.height);
                                            trayItem.modelData.display(panel, pos.x, pos.y);
                                        }
                                    } else if (button === Qt.MiddleButton) {
                                        trayItem.modelData.secondaryActivate();
                                    } else {
                                        trayItem.modelData.activate();
                                    }
                                }
                                onWheel: delta => trayItem.modelData.scroll(delta, false)
                            }
                            Image {
                                anchors.centerIn: parent
                                width: 17
                                height: 17
                                source: trayItem.modelData.icon
                            }
                        }
                    }
                }

                BluetoothControl { leftPadding: 9; rightPadding: 9 }

                Item { width: 9; height: 30 }

                StatusChip {
                    id: audioChip
                    leftRadius: 15
                    foreground: root.speaker?.muted ? "#a55555" : "#dcdfe1"
                    text: root.speakerIcon() + " " + (root.speaker ? root.percent(root.speaker) : "—") +
                          (root.mic ? " " + root.coloredIcon(root.mic.muted ? "" : "", root.mic.muted ? "#FF4040" : "#16a34a") + " " + root.percent(root.mic) : "")
                    tip: "Output: " + (root.speaker ? root.percent(root.speaker) + (root.speaker.muted ? " (muted)" : "") : "Unavailable") +
                         "\nMic: " + (root.mic ? root.percent(root.mic) + (root.mic.muted ? " (muted)" : "") : "Unavailable") +
                         "\nLeft: mute output · Right: mute mic · Middle: mixer"
                    interactive: true
                    buttons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: button => {
                        if (button === Qt.LeftButton && root.speaker)
                            root.speaker.muted = !root.speaker.muted;
                        else if (button === Qt.RightButton && root.mic)
                            root.mic.muted = !root.mic.muted;
                        else if (button === Qt.MiddleButton)
                            Quickshell.execDetached(["pavucontrol", "-t", "3"]);
                    }
                    onWheel: delta => {
                        if (root.speaker)
                            root.speaker.volume = Math.max(0, Math.min(1.5, root.speaker.volume + (delta > 0 ? 0.01 : -0.01)));
                    }
                }
                StatusChip {
                    readonly property int iconLevel: Math.max(0, Math.min(3, Math.floor(root.brightnessPercent / 25)))
                    visible: root.brightnessPercent >= 0
                    text: root.coloredIcon(["󰃞", "󰃝", "󰃟", "󰃠"][iconLevel], ["#696969", "#A9A9A9", "#FFFF66", "#FFD700"][iconLevel]) + " " + root.brightnessPercent + "%"
                    tip: "Backlight: " + root.brightnessPercent + "%"
                    interactive: true
                    buttons: Qt.NoButton
                    onWheel: delta => {
                        if (!setBrightness.running)
                            setBrightness.exec(["brightnessctl", "-q", "-d", "intel_backlight", "set", delta > 0 ? "+1%" : "1%-"]);
                    }
                }
                StatusChip {
                    visible: root.battery?.isPresent ?? false
                    text: (root.charging ? "󱐋" : root.coloredIcon(["󰂎", "󰁼", "󰁿", "󰂁", "󰁹"][Math.min(4, Math.floor(root.batteryPercent / 20))], "#16a34a")) + " " + root.batteryPercent + "%"
                    tip: {
                        const battery = root.battery;
                        if (!battery?.isPresent)
                            return "";
                        const heading = "Battery: " + root.batteryPercent + "%";
                        const discharging = battery.state === UPowerDeviceState.Discharging;
                        const seconds = discharging ? battery.timeToEmpty : root.charging ? battery.timeToFull : 0;
                        if (seconds > 0) {
                            const minutes = Math.ceil(seconds / 60);
                            const hours = Math.floor(minutes / 60);
                            const estimate = (hours ? hours + "h " : "") + minutes % 60 + "m";
                            return heading + "\nAbout " + estimate + (discharging ? " remaining" : " until full");
                        }
                        const state = UPowerDeviceState.toString(battery.state);
                        return heading + "\n" + state + (discharging || root.charging ? " · Estimating time…" : "");
                    }
                }
                StatusChip {
                    visible: root.temperature !== ""
                    text: root.coloredIcon("", "#FFA500") + " " + root.temperature + "°C"
                    tip: "CPU temperature: " + root.temperature + "°C"
                }
                StatusChip {
                    visible: root.ramTotal > 0
                    text: root.coloredIcon("", "#8A2BE2") + " " + root.ramUsed.toFixed(1) + "G/" + root.ramTotal.toFixed(1) + "G"
                    tip: "Memory: " + root.ramUsed.toFixed(2) + " GiB used of " + root.ramTotal.toFixed(2) + " GiB"
                }
                StatusChip {
                    id: cpuChip
                    leftPadding: 10
                    rightPadding: 15
                    rightRadius: 15
                    // Reserve room for 100% without shifting the icon or neighboring items.
                    implicitWidth: Math.ceil(cpuWidthSample.implicitWidth) + leftPadding + rightPadding
                    horizontalAlignment: Text.AlignLeft
                    text: root.coloredIcon("", "#FF9F0A") + " " + (root.cpuUsage >= 0 ? root.cpuUsage + "%" : "—")
                    tip: "CPU usage: " + (root.cpuUsage >= 0 ? root.cpuUsage + "%" : "Sampling…")

                    Text {
                        id: cpuWidthSample
                        visible: false
                        font: cpuChip.font
                        textFormat: Text.StyledText
                        text: root.coloredIcon("", "#FF9F0A") + " 100%"
                    }
                }
            }
        }
    }
}
