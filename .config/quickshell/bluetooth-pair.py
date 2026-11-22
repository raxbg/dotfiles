"""A BlueZ agent scoped to one pairing attempt, never the default agent."""

import json
import os
import re
import sys

import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib


class Rejected(dbus.exceptions.DBusException):
    _dbus_error_name = "org.bluez.Error.Rejected"


def emit(kind, text):
    print(json.dumps({"kind": kind, "text": text}), flush=True)


def passkey(value):
    if not isinstance(value, str) or not re.fullmatch(r"[0-9]{1,6}", value):
        raise ValueError("Invalid passkey")
    return dbus.UInt32(int(value))


def pin(value):
    if not isinstance(value, str) or not 1 <= len(value.encode("utf-8")) <= 16:
        raise ValueError("Invalid PIN")
    return value


def confirm(value):
    if value is not True:
        raise ValueError("Not confirmed")
    return None


class Agent(dbus.service.Object):
    interface = "org.bluez.Agent1"
    path = "/org/quickshell/BluetoothPairingAgent"
    pending = None

    def __init__(self, bus, target):
        super().__init__(bus, self.path)
        self.target = target
        self.bluez = bus.get_name_owner("org.bluez")

    def check(self, sender, device=None):
        if sender != self.bluez or (device is not None and device != self.target):
            raise Rejected("Not part of this pairing attempt")

    def ask(self, kind, text, parse, success, reject):
        if self.pending:
            raise Rejected("A confirmation is already pending")
        self.pending = (parse, success, reject)
        emit(kind, text)

    def reply(self, value):
        if not self.pending:
            return
        (parse, success, reject), self.pending = self.pending, None
        try:
            parsed = parse(value)
        except ValueError:
            reject(Rejected("Pairing was declined or the code was invalid"))
        else:
            success() if parsed is None else success(parsed)

    @dbus.service.method(interface, in_signature="o", out_signature="s", sender_keyword="sender", async_callbacks=("ok", "fail"))
    def RequestPinCode(self, device, ok, fail, sender):
        self.check(sender, device)
        self.ask("pin", "Enter the PIN for the device.", pin, ok, fail)

    @dbus.service.method(interface, in_signature="o", out_signature="u", sender_keyword="sender", async_callbacks=("ok", "fail"))
    def RequestPasskey(self, device, ok, fail, sender):
        self.check(sender, device)
        self.ask("passkey", "Enter the numeric passkey shown on the device.", passkey, ok, fail)

    @dbus.service.method(interface, in_signature="ou", sender_keyword="sender", async_callbacks=("ok", "fail"))
    def RequestConfirmation(self, device, code, ok, fail, sender):
        self.check(sender, device)
        self.ask("confirm", f"Does {code:06d} match the code on the device?", confirm, ok, fail)

    @dbus.service.method(interface, in_signature="o", sender_keyword="sender", async_callbacks=("ok", "fail"))
    def RequestAuthorization(self, device, ok, fail, sender):
        self.check(sender, device)
        self.ask("confirm", "Allow this device to pair?", confirm, ok, fail)

    @dbus.service.method(interface, in_signature="os", sender_keyword="sender")
    def DisplayPinCode(self, device, code, sender):
        self.check(sender, device)
        emit("display", f"Type {code} on the device, then press Enter there.")

    @dbus.service.method(interface, in_signature="ouq", sender_keyword="sender")
    def DisplayPasskey(self, device, code, entered, sender):
        self.check(sender, device)
        emit("display", f"Type {code:06d} on the device, then press Enter there ({entered}/6 digits).")

    @dbus.service.method(interface, in_signature="os", sender_keyword="sender")
    def AuthorizeService(self, device, uuid, sender):
        raise Rejected("Only pairing is handled by this agent")

    @dbus.service.method(interface, sender_keyword="sender")
    def Cancel(self, sender):
        self.check(sender)
        self.reply(None)

    @dbus.service.method(interface, sender_keyword="sender")
    def Release(self, sender):
        self.Cancel(sender)


def pair(target):
    if not re.fullmatch(r"/org/bluez/hci[0-9]+/dev_(?:[A-Fa-f0-9]{2}_){5}[A-Fa-f0-9]{2}", target):
        raise ValueError("Invalid Bluetooth device path")

    DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus(private=True)
    agent = Agent(bus, target)
    manager = dbus.Interface(bus.get_object(agent.bluez, "/org/bluez"), "org.bluez.AgentManager1")
    device = dbus.Interface(bus.get_object(agent.bluez, target), "org.bluez.Device1")
    manager.RegisterAgent(agent.path, "KeyboardDisplay")
    loop = GLib.MainLoop()
    buffer = b""

    def finish(text):
        emit("status", text)
        loop.quit()

    def cancel():
        agent.reply(None)
        device.CancelPairing(reply_handler=lambda: None, error_handler=lambda error: None)
        finish("Pairing cancelled.")

    def read_reply(fd, condition):
        nonlocal buffer
        chunk = os.read(fd, 256)
        if not chunk or len(buffer) + len(chunk) > 256:
            cancel()
            return False
        buffer += chunk
        while b"\n" in buffer:
            line, buffer = buffer.split(b"\n", 1)
            try:
                value = json.loads(line)
            except ValueError:
                value = None
            if value is None:
                cancel()
                return False
            agent.reply(value)
        return True

    GLib.io_add_watch(sys.stdin.fileno(), GLib.PRIORITY_DEFAULT, GLib.IO_IN | GLib.IO_HUP, read_reply)
    device.Pair(reply_handler=lambda: finish("Device paired."),
                error_handler=lambda error: finish(f"Pairing failed: {error.get_dbus_message()}"), timeout=120)
    try:
        loop.run()
    finally:
        bus.close()


if __name__ == "__main__":
    try:
        pair(sys.argv[1])
    except (IndexError, ValueError, dbus.DBusException) as error:
        emit("status", str(error))
        sys.exit(1)
