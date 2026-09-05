package main

import (
	"bufio"
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

func playSound(soundPath string) {
	if _, err := os.Stat(soundPath); err != nil {
		return
	}
	player, err := exec.LookPath("pw-play")
	if err != nil {
		player, err = exec.LookPath("paplay")
	}
	if err == nil {
		go exec.Command(player, soundPath).Run()
	}
}

func notify(conn net.Conn, soundPath string, data []byte) {
	if len(data) > 8192 || len(data) == 0 {
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
	playSound(soundPath)
	reply(conn, true, "")
}

func forwardAgentStatus(conn net.Conn, reader *bufio.Reader, id, workspace string) {
	runtimeDir := os.Getenv("XDG_RUNTIME_DIR")
	if runtimeDir == "" {
		return
	}
	waybar, err := net.Dial("unix", filepath.Join(runtimeDir, "waybar-agent-status.sock"))
	if err != nil {
		return
	}
	defer waybar.Close()
	if json.NewEncoder(waybar).Encode(map[string]string{"id": id, "state": "ready", "workspace": workspace}) != nil {
		return
	}
	io.Copy(waybar, reader)
}

func handle(conn net.Conn, soundPath, workspace string) {
	defer conn.Close()
	reader := bufio.NewReaderSize(conn, 8192)
	line, err := reader.ReadSlice('\n')
	if err != nil {
		return
	}
	var envelope struct {
		Type string `json:"type"`
		ID   string `json:"id"`
	}
	if json.Unmarshal(line, &envelope) != nil {
		return
	}
	switch envelope.Type {
	case "notification":
		notify(conn, soundPath, line)
	case "agent-status":
		if envelope.ID != "" && len(envelope.ID) <= 200 {
			forwardAgentStatus(conn, reader, envelope.ID, workspace)
		}
	}
}

func main() {
	if len(os.Args) != 4 {
		fmt.Fprintln(os.Stderr, "usage: bridge.go SOCKET_PATH SOUND_PATH WORKSPACE")
		os.Exit(2)
	}

	socketPath := os.Args[1]
	soundPath := os.Args[2]
	workspace := os.Args[3]
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
		go handle(connection, soundPath, workspace)
	}
}
