package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"syscall"
)

type message struct {
	Type    string `json:"type"`
	Title   string `json:"title"`
	Body    string `json:"body"`
	Urgency string `json:"urgency"`
}

func reply(conn net.Conn, ok bool, err string) {
	json.NewEncoder(conn).Encode(map[string]any{"ok": ok, "error": err})
}

func notify(conn net.Conn) {
	defer conn.Close()
	data, err := io.ReadAll(io.LimitReader(conn, 8193))
	if err != nil || len(data) > 8192 || len(data) == 0 || data[len(data)-1] != '\n' {
		reply(conn, false, "invalid message")
		return
	}

	var message message
	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.DisallowUnknownFields()
	if decoder.Decode(&message) != nil || decoder.Decode(&struct{}{}) != io.EOF || message.Type != "notification" || message.Title == "" || len(message.Title) > 200 || len(message.Body) > 4000 || (message.Urgency != "low" && message.Urgency != "normal" && message.Urgency != "critical") {
		reply(conn, false, "invalid notification")
		return
	}

	if err := exec.Command("notify-send", "-u", message.Urgency, "--", message.Title, message.Body).Run(); err != nil {
		reply(conn, false, err.Error())
		return
	}
	reply(conn, true, "")
}

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "usage: bridge.go SOCKET_PATH")
		os.Exit(2)
	}

	socketPath := os.Args[1]
	listener, err := net.Listen("unix", socketPath)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	defer os.Remove(socketPath)
	defer os.Remove(filepath.Dir(socketPath))
	if err := os.Chmod(socketPath, 0600); err != nil {
		fmt.Fprintln(os.Stderr, err)
		return
	}

	signals := make(chan os.Signal, 1)
	signal.Notify(signals, syscall.SIGTERM)
	go func() {
		<-signals
		listener.Close()
	}()

	for {
		connection, err := listener.Accept()
		if err != nil {
			return
		}
		go notify(connection)
	}
}
