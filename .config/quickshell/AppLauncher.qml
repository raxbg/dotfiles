pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

Scope {
    id: launcher

    required property ShellScreen targetScreen
    property ShellScreen openScreen: null
    property bool opened: false
    property int mode: 0
    readonly property list<string> modes: ["Apps & commands", "Calculator", "Wallpapers"]
    readonly property string query: input.text.trim()
    property list<string> executables: []
    property string answer: ""
    property string calculating: ""
    readonly property string home: Quickshell.env("HOME")

    // shortcut: recency is session-only; persist it if this replaces Rofi.
    PersistentProperties {
        id: history
        property list<string> recent: []
    }

    readonly property var apps: DesktopEntries.applications.values.map(app => ({
        key: "app:" + app.id,
        title: app.name,
        name: app.name.toLowerCase(),
        detail: app.genericName || app.comment || "Application",
        search: [app.name, app.genericName, app.id, ...app.keywords, ...app.categories].join(" ").toLowerCase(),
        icon: app.icon,
        app: app
    }))
    readonly property var commands: executables.map(name => ({
        key: "run:" + name, title: name, name: name.toLowerCase(), detail: "Command", search: name.toLowerCase()
    }))
    readonly property var wallpapers: {
        const files = [];
        for (let i = 0; i < wallpaperFiles.count; i++) {
            const name = wallpaperFiles.get(i, "fileName");
            files.push({key: name, title: name, name: name.toLowerCase(), search: name.toLowerCase(), image: wallpaperFiles.get(i, "fileUrl")});
        }
        return files;
    }
    readonly property var launchRows: sortRows(apps.concat(commands), history.recent)
    readonly property var wallpaperRows: sortRows(wallpapers, [])

    function sortRows(rows, recent) {
        return rows.map(row => {
            const used = recent.indexOf(row.key);
            return {row, rank: used >= 0 ? used : row.app || row.image ? 25 : 26};
        })
            .sort((a, b) => a.rank - b.rank || a.row.title.localeCompare(b.row.title))
            .map(entry => entry.row);
    }

    readonly property var results: {
        const source = mode === 2 ? wallpaperRows : mode === 0 ? launchRows : [];
        const needle = query.toLowerCase();
        if (!needle)
            return source;

        const terms = needle.split(/\s+/);
        const matches = [[], [], [], []];
        for (const row of source) {
            if (!terms.every(term => row.search.includes(term)))
                continue;
            const priority = row.name === needle ? 0 : row.name.startsWith(needle) ? 1 : row.name.includes(needle) ? 2 : 3;
            matches[priority].push(row);
        }
        return matches[0].concat(matches[1], matches[2], matches[3]);
    }
    readonly property int resultCount: results.length

    function close(): void { opened = false; }

    function setMode(index: int): void {
        mode = index;
        input.clear();
        list.currentIndex = results.length ? 0 : -1;
        input.forceActiveFocus();
    }

    function move(step: int): void {
        if (!list.count)
            return;
        list.currentIndex = (list.currentIndex + step + list.count) % list.count;
        list.positionViewAtIndex(list.currentIndex, ListView.Contain);
    }

    function activate(row): void {
        if (!row)
            return;
        if (mode === 2) {
            const script = home + "/.config/hypr/scripts/wallpaper-selector.sh";
            Quickshell.execDetached([script, "--rofi", row.title]);
        } else {
            history.recent = [row.key, ...history.recent.filter(key => key !== row.key)].slice(0, 25);
            if (row.app)
                row.app.execute();
            else
                Quickshell.execDetached([row.title]);
        }
        close();
    }

    onQueryChanged: {
        answer = "";
        if (mode === 1 && query)
            debounce.restart();
        list.currentIndex = results.length ? 0 : -1;
        list.positionViewAtBeginning();
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            if (launcher.opened) {
                launcher.close();
            } else if (launcher.targetScreen) {
                launcher.openScreen = launcher.targetScreen;
                launcher.opened = true;
                launcher.setMode(0);
            }
        }
    }

    // shortcut: refresh PATH on config reload rather than on every open.
    Component.onCompleted: inventory.running = true

    Process {
        id: inventory
        command: ["bash", "-c", `
            IFS=: read -ra dirs <<< "$PATH"
            for dir in "\${dirs[@]}"; do
                for file in "\${dir:-.}"/*; do
                    [[ -f "$file" && -x "$file" ]] && printf '%s\\0' "\${file##*/}"
                done
            done
        `]
        stdout: StdioCollector {
            onStreamFinished: launcher.executables = [...new Set(text.split("\0").filter(Boolean))]
        }
    }

    FolderListModel {
        id: wallpaperFiles
        folder: "file://" + launcher.home + "/Pictures/Wallpapers"
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.gif", "*.webp"]
        caseSensitive: false
        showDirs: false
    }

    Timer {
        id: debounce
        interval: 120
        onTriggered: {
            if (launcher.opened && launcher.mode === 1 && launcher.query && !calculator.running) {
                launcher.calculating = launcher.query;
                calculator.exec(["qalc", "-defaults", "-t", "-m", "700", "--", launcher.query]);
            }
        }
    }

    Process {
        id: calculator
        stdout: StdioCollector { id: output }
        stderr: StdioCollector { id: errors }
        onExited: code => {
            if (launcher.mode !== 1 || !launcher.query || !launcher.opened)
                return;
            if (launcher.query !== launcher.calculating)
                debounce.restart();
            else
                launcher.answer = code === 0 && !errors.text.trim() ? output.text.trim() : "";
        }
    }

    // qmllint disable uncreatable-type
    PanelWindow {
        // qmllint enable uncreatable-type
        id: overlay
        screen: launcher.openScreen
        visible: launcher.opened && launcher.openScreen !== null
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell-launcher"
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "#3d000000"
            MouseArea { anchors.fill: parent; onClicked: launcher.close() }
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(580, parent.width - 32)
            height: Math.min(490, parent.height - 32)
            radius: 15
            color: "#242e42"
            border.color: "#24dcdfe1"
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 14

                Row {
                    spacing: 10
                    Repeater {
                        model: launcher.modes
                        Chip {
                            required property string modelData
                            required property int index
                            text: modelData
                            selected: launcher.mode === index
                            selectedBackground: "transparent"
                            hoverBackground: "#0ddcdfe1"
                            foreground: selected ? "#93c5fd" : "#b5bfce"
                            font.pixelSize: 13
                            font.bold: selected
                            interactive: true
                            onClicked: launcher.setMode(index)

                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                width: 16
                                height: 2
                                radius: 1
                                color: "#93c5fd"
                                visible: parent.selected
                            }
                        }
                    }
                }

                TextField {
                    id: input
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    leftPadding: 23
                    rightPadding: 16
                    topPadding: 0
                    bottomPadding: 0
                    verticalAlignment: TextInput.AlignVCenter
                    placeholderText: ["Search apps and commands…", "Enter an expression…", "Search wallpapers…"][launcher.mode]
                    color: "#dcdfe1"
                    placeholderTextColor: "#9ba7b9"
                    selectionColor: "#455977"
                    selectedTextColor: "#ffffff"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                    Accessible.name: placeholderText
                    background: Rectangle {
                        color: "#1b2434"
                        radius: 10
                        border.color: input.activeFocus ? "#3693c5fd" : "#1adcdfe1"
                    }

                    Keys.onPressed: event => {
                        const alt = event.modifiers & Qt.AltModifier;
                        const shift = event.modifiers & Qt.ShiftModifier;
                        const noCommandModifier = !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier));
                        if (event.key === Qt.Key_Escape) {
                            launcher.close();
                        } else if (alt && (event.key === Qt.Key_H || event.key === Qt.Key_L)) {
                            launcher.setMode((launcher.mode + (event.key === Qt.Key_H ? 2 : 1)) % 3);
                        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (noCommandModifier && event.text === "K")) {
                            launcher.move(-1);
                        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab || (noCommandModifier && event.text === "J")) {
                            launcher.move(1);
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (launcher.mode === 1 && launcher.answer) {
                                Quickshell.clipboardText = launcher.answer;
                                launcher.close();
                            } else if (launcher.mode === 0 && shift && launcher.query) {
                                Quickshell.execDetached(["bash", "-c", launcher.query]);
                                launcher.close();
                            } else {
                                launcher.activate(launcher.results[list.currentIndex]);
                            }
                        } else {
                            return;
                        }
                        event.accepted = true;
                    }
                }

                Label {
                    visible: launcher.mode === 1
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: launcher.answer || (launcher.query ? "No result" : "Try 2 + 2 or 15 km in mi")
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    color: "#dcdfe1"
                    font.family: input.font.family
                    font.pixelSize: 22
                }

                ListView {
                    id: list
                    visible: launcher.mode !== 1
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    // Stable row slots let visible delegates update without resetting or reordering the model.
                    model: ScriptModel {
                        values: Array.from({length: launcher.resultCount}, (_, index) => index)
                    }
                    onCountChanged: if (currentIndex < 0 && count) currentIndex = 0

                    delegate: Rectangle {
                        id: entry
                        required property int index
                        readonly property var row: launcher.results[index]
                        readonly property bool current: index === list.currentIndex
                        width: list.width
                        height: 42
                        radius: 8
                        color: current ? "#1393c5fd" : "transparent"

                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 3
                            anchors.verticalCenter: parent.verticalCenter
                            width: 2
                            height: 18
                            radius: 1
                            color: "#93c5fd"
                            visible: entry.current
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 12
                            spacing: 12

                            IconImage {
                                visible: !!entry.row && !entry.row.image
                                implicitSize: 24
                                source: visible ? Quickshell.iconPath(entry.row.icon || "utilities-terminal", true) : ""
                            }
                            Image {
                                visible: !!entry.row?.image
                                source: entry.row?.image ?? ""
                                Layout.preferredWidth: 52
                                Layout.preferredHeight: 36
                                sourceSize: Qt.size(104, 72)
                                asynchronous: true
                                fillMode: Image.PreserveAspectFit
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Label {
                                    Layout.fillWidth: true
                                    text: entry.row?.title ?? ""
                                    textFormat: Text.PlainText
                                    elide: Text.ElideRight
                                    color: "#dcdfe1"
                                    font.family: input.font.family
                                    font.pixelSize: 13
                                    font.bold: entry.current
                                }
                                Label {
                                    Layout.fillWidth: true
                                    text: entry.row?.detail === entry.row?.title ? "" : entry.row?.detail ?? ""
                                    visible: text !== ""
                                    textFormat: Text.PlainText
                                    elide: Text.ElideRight
                                    color: "#9ba7b9"
                                    font.family: input.font.family
                                    font.pixelSize: 11
                                }
                            }
                        }

                        HoverHandler {
                            onPointChanged: if (hovered) list.currentIndex = entry.index
                        }
                        TapHandler { onTapped: launcher.activate(entry.row) }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: launcher.mode === 1 ? "Enter: copy   Alt+H/L: mode   Esc: close" :
                        launcher.mode === 2 ? "↑↓ / J/K: navigate   Enter: apply   Alt+H/L: mode   Esc: close" :
                        "↑↓ / J/K: navigate   Enter: open   Shift+Enter: run command   Alt+H/L: mode"
                    elide: Text.ElideRight
                    color: "#9ba7b9"
                    font.family: input.font.family
                    font.pixelSize: 10
                }
            }
        }
    }
}
