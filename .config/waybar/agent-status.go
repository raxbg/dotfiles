package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"html"
	"log"
	"net"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
)

type Update struct {
	ID      string `json:"id"`
	State   string `json:"state"`
	Tooltip string `json:"tooltip"`
	Todo    struct {
		Current int `json:"current"`
		Total   int `json:"total"`
	} `json:"todo"`
}

type Agent struct {
	connection net.Conn
	state      string
	current    int
	total      int
	tooltip    string
	number     int
}

var (
	mu        sync.Mutex
	agents    = map[string]Agent{}
	nextAgent = 1
)

func emit() {
	if len(agents) == 0 {
		json.NewEncoder(os.Stdout).Encode(map[string]string{"text": `<span color="#94a3b8">○ agents: none</span>`, "tooltip": "Agent status"})
		return
	}

	items := make([]Agent, 0, len(agents))
	for _, agent := range agents {
		items = append(items, agent)
	}
	sort.Slice(items, func(i, j int) bool { return items[i].number < items[j].number })
	text := make([]string, 0, len(items))
	tooltips := make([]string, 0, len(items))
	for _, agent := range items {
		name := fmt.Sprintf("Agent %d", agent.number)
		progress := ""
		if agent.total > 0 {
			progress = fmt.Sprintf(" %d/%d", agent.current, agent.total)
		}
		if agent.state == "ready" {
			text = append(text, fmt.Sprintf(`<span color="#16a34a">✓ %s%s</span>`, html.EscapeString(name), progress))
		} else {
			text = append(text, fmt.Sprintf(`<span color="#d97706">● %s%s</span>`, html.EscapeString(name), progress))
		}
		if agent.tooltip != "" {
			tooltips = append(tooltips, fmt.Sprintf("<b>%s</b>\n%s", name, agent.tooltip))
		}
	}
	tooltip := "Agent status"
	if len(tooltips) > 0 {
		tooltip = strings.Join(tooltips, "\n\n")
	}
	json.NewEncoder(os.Stdout).Encode(map[string]string{"text": strings.Join(text, " "), "tooltip": tooltip})
}

func handle(connection net.Conn) {
	defer func() {
		mu.Lock()
		for name, agent := range agents {
			if agent.connection == connection {
				delete(agents, name)
			}
		}
		emit()
		mu.Unlock()
		connection.Close()
	}()

	scanner := bufio.NewScanner(connection)
	scanner.Buffer(make([]byte, 1024), 8192)
	for scanner.Scan() {
		var update Update
		if json.Unmarshal(scanner.Bytes(), &update) != nil {
			continue
		}
		update.ID = strings.TrimSpace(update.ID)
		if update.ID == "" || len(update.ID) > 200 || len(update.Tooltip) > 8000 || (update.State != "running" && update.State != "ready" && update.State != "gone") || update.Todo.Current < 0 || update.Todo.Total < update.Todo.Current {
			continue
		}
		mu.Lock()
		if update.State == "gone" {
			delete(agents, update.ID)
		} else {
			number := nextAgent
			if agent, ok := agents[update.ID]; ok {
				number = agent.number
			} else {
				nextAgent++
			}
			agents[update.ID] = Agent{connection, update.State, update.Todo.Current, update.Todo.Total, update.Tooltip, number}
		}
		emit()
		mu.Unlock()
	}
}

func main() {
	runtime := os.Getenv("XDG_RUNTIME_DIR")
	if runtime == "" {
		log.Fatal("XDG_RUNTIME_DIR is required")
	}
	path := filepath.Join(runtime, "waybar-agent-status.sock")
	os.Remove(path)
	listener, err := net.Listen("unix", path)
	if err != nil {
		log.Fatal(err)
	}
	defer os.Remove(path)
	if err := os.Chmod(path, 0600); err != nil {
		log.Fatal(err)
	}

	mu.Lock()
	emit()
	mu.Unlock()
	for {
		connection, err := listener.Accept()
		if err != nil {
			log.Print(err)
			continue
		}
		go handle(connection)
	}
}
