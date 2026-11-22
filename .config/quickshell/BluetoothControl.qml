pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io

Chip {
    id: control

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property var devices: adapter?.devices.values ?? []
    readonly property bool connected: devices.some(device => device.connected)
    property bool scanning: false
    property string status: ""
    property var prompt: null

    text: connected ? "󰂱" : adapter?.enabled ? "󰂯" : "󰂲"
    foreground: adapter?.enabled ? "#00BFFF" : "#a6dcdfe1"
    selected: dropdown.visible
    interactive: true
    tip: dropdown.visible ? "" : "Bluetooth controls"
    Accessible.role: Accessible.Button
    Accessible.name: "Bluetooth controls"
    Accessible.onPressAction: control.toggle()
    onClicked: toggle()

    function toggle() {
        dropdown.visible = !dropdown.visible;
    }

    function stopScan() {
        if (scanning && adapter)
            adapter.discovering = false;
        scanning = false;
    }

    function reply(value) {
        pairing.write(JSON.stringify(value) + "\n");
        prompt = null;
        secret.clear();
    }

    Process {
        id: pairing
        stdinEnabled: true
        stdout: SplitParser {
            onRead: line => {
                const event = JSON.parse(line);
                if (event.kind === "status") {
                    control.status = event.text;
                    control.prompt = null;
                    secret.clear();
                } else {
                    control.prompt = event;
                    if (event.kind === "pin" || event.kind === "passkey")
                        secret.forceActiveFocus();
                }
            }
        }
        onExited: code => {
            control.prompt = null;
            secret.clear();
            if (code !== 0 && control.status.startsWith("Pairing with"))
                control.status = "Could not start the pairing helper (requires python-dbus and python-gobject).";
        }
    }

    PopupWindow {
        id: dropdown
        // qmllint disable missing-property
        anchor.item: control
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        // qmllint enable missing-property
        grabFocus: true
        visible: false
        implicitWidth: 380
        implicitHeight: body.implicitHeight + 24
        color: "transparent"

        onVisibleChanged: {
            if (visible) {
                body.forceActiveFocus();
            } else {
                control.stopScan();
                if (pairing.running)
                    control.reply(null);
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 15
            color: "#242e42"
            border.color: "#80dcdfe1"

            ColumnLayout {
                id: body
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8
                Keys.onEscapePressed: dropdown.visible = false

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        Layout.fillWidth: true
                        text: "Bluetooth"
                        color: "#dcdfe1"
                        font.pixelSize: 17
                        font.bold: true
                    }
                    Button {
                        text: control.adapter?.enabled ? "Turn off" : "Turn on"
                        enabled: !!control.adapter && !pairing.running
                        onClicked: {
                            control.stopScan();
                            control.status = "";
                            control.adapter.enabled = !control.adapter.enabled;
                        }
                    }
                    Button {
                        text: "Close"
                        onClicked: dropdown.visible = false
                    }
                }

                Label {
                    visible: !control.adapter?.enabled
                    text: control.adapter ? (control.adapter.state === BluetoothAdapterState.Blocked ? "Bluetooth is blocked" : "Bluetooth is off") : "No Bluetooth adapter found"
                    color: "#cbd5e1"
                }

                RowLayout {
                    visible: control.adapter?.enabled ?? false
                    Label {
                        Layout.fillWidth: true
                        text: control.scanning ? "Looking for nearby devices…" : "Paired devices"
                        color: "#cbd5e1"
                    }
                    Button {
                        enabled: !pairing.running
                        text: control.scanning ? "Stop scan" : "Scan for devices"
                        onClicked: {
                            control.status = "";
                            if (control.scanning) {
                                control.stopScan();
                            } else {
                                control.scanning = true;
                                control.adapter.discovering = true;
                            }
                        }
                    }
                }

                ScrollView {
                    Layout.fillWidth: true
                    implicitHeight: control.adapter?.enabled ? Math.min(deviceList.contentHeight, 270) : 0
                    visible: implicitHeight > 0
                    contentWidth: availableWidth
                    clip: true

                    ListView {
                        id: deviceList
                        spacing: 4
                        model: control.devices.filter(device => !device.blocked && (device.paired || device.connected || control.scanning))
                            .sort((a, b) => Number(b.connected) - Number(a.connected) || Number(b.paired) - Number(a.paired) || a.name.localeCompare(b.name))
                        delegate: RowLayout {
                            id: row
                            required property BluetoothDevice modelData
                            readonly property BluetoothDevice device: modelData
                            readonly property bool busy: device.pairing || device.state === BluetoothDeviceState.Connecting || device.state === BluetoothDeviceState.Disconnecting
                            width: ListView.view.width

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Label {
                                    Layout.fillWidth: true
                                    text: row.device.name || row.device.address
                                    textFormat: Text.PlainText
                                    color: "#dcdfe1"
                                    elide: Text.ElideRight
                                }
                                Label {
                                    text: (row.device.pairing ? "Pairing…" : row.busy ? BluetoothDeviceState.toString(row.device.state) : row.device.connected ? "Connected" : row.device.paired ? "Paired" : "Nearby") +
                                          (row.device.batteryAvailable ? " · " + Math.round(row.device.battery * 100) + "% battery" : "")
                                    color: "#aab9d0"
                                    font.pixelSize: 11
                                }
                            }
                            Button {
                                enabled: !row.busy && !pairing.running
                                text: row.device.connected ? "Disconnect" : row.device.paired ? "Connect" : "Pair"
                                onClicked: {
                                    control.status = "";
                                    if (row.device.connected) {
                                        row.device.disconnect();
                                    } else if (row.device.paired) {
                                        row.device.connect();
                                    } else {
                                        control.status = "Pairing with " + row.device.name + "…";
                                        pairing.exec(["/usr/bin/python", Quickshell.shellPath("bluetooth-pair.py"), row.device.dbusPath]);
                                    }
                                }
                            }
                            Button {
                                visible: row.device.paired
                                enabled: !row.busy && !pairing.running
                                text: "Forget…"
                                onClicked: {
                                    forget.device = row.device;
                                    forget.open();
                                }
                            }
                        }
                    }
                }

                Label {
                    visible: !!control.adapter?.enabled && !deviceList.count
                    text: control.scanning ? "No nearby devices found yet" : "No paired devices"
                    color: "#aab9d0"
                }
                Label {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: control.prompt?.text ?? control.status
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    color: "#dcdfe1"
                }
                RowLayout {
                    visible: pairing.running
                    TextField {
                        id: secret
                        Layout.fillWidth: true
                        visible: control.prompt?.kind === "pin" || control.prompt?.kind === "passkey"
                        placeholderText: control.prompt?.kind === "pin" ? "PIN" : "Passkey"
                        maximumLength: control.prompt?.kind === "pin" ? 16 : 6
                        onAccepted: if (submit.enabled) control.reply(text)
                    }
                    Button {
                        id: submit
                        visible: secret.visible || control.prompt?.kind === "confirm"
                        enabled: !secret.visible || (control.prompt?.kind === "passkey" ? /^\d{1,6}$/.test(secret.text) : secret.text.length > 0)
                        text: "Confirm"
                        onClicked: control.reply(secret.visible ? secret.text : true)
                    }
                    Button {
                        text: "Cancel pairing"
                        onClicked: control.reply(null)
                    }
                }
            }

            Dialog {
                id: forget
                property BluetoothDevice device: null
                anchors.centerIn: parent
                title: "Forget Bluetooth device?"
                standardButtons: Dialog.Ok | Dialog.Cancel
                modal: true
                onAccepted: device?.forget()
                onClosed: device = null
                Label {
                    text: forget.device?.name ?? ""
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                }
            }
        }
    }
}
