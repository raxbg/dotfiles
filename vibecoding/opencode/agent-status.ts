import { randomUUID } from "node:crypto"
import { createConnection, type Socket } from "node:net"
import { basename, join } from "node:path"

type Session = {
  title: string
  state: "running" | "ready"
  todo?: { current: number; total: number }
}

const escape = (text: string) => text.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;")

export default async () => {
  const runtime = process.env.XDG_RUNTIME_DIR
  const socketPath = runtime ? join(runtime, "waybar-agent-status", "socket") : undefined
  const workspace = (process.env.OPENCODE_WORKSPACE ?? basename(process.cwd())).slice(0, 200)
  const id = randomUUID()
  const sessions = new Map<string, Session>()
  let socket: Socket | undefined
  let connected = false

  const publish = () => {
    const active = [...sessions.values()].filter((session) => session.state === "running")
    const todos = active.filter((session) => session.todo?.total)
    const todo = todos.length ? { current: todos.reduce((sum, session) => sum + session.todo!.current, 0), total: todos.reduce((sum, session) => sum + session.todo!.total, 0) } : undefined
    const tooltip = [...sessions.values()].map((session) => {
      const progress = session.todo?.total ? ` ${session.todo.current}/${session.todo.total}` : ""
      const color = session.state === "running" ? "#d97706" : "#16a34a"
      const icon = session.state === "running" ? "●" : "✓"
      return `<span color="${color}">${icon} ${escape(session.title)}${progress}</span>`
    }).join("\n")
    if (connected) socket?.write(`${JSON.stringify({ id, state: active.length ? "running" : "ready", todo, tooltip, workspace })}\n`)
  }

  const touch = (id: string, session: Session) => {
    sessions.delete(id)
    sessions.set(id, session)
    if (sessions.size > 10) sessions.delete(sessions.keys().next().value!)
    publish()
  }

  const connect = () => {
    if (!socketPath) return
    const connection = createConnection(socketPath)
    socket = connection
    connection.on("connect", () => {
      connected = true
      publish()
    })
    connection.on("error", () => {})
    connection.on("close", () => {
      if (socket !== connection) return
      socket = undefined
      connected = false
      setTimeout(connect, 1000).unref()
    })
  }

  connect()

  return {
    event: async ({ event }) => {
      if (event.type === "session.created" || event.type === "session.updated") {
        const session = event.properties.info
        touch(session.id, { ...sessions.get(session.id), title: session.title.slice(0, 200) || "Untitled session", state: sessions.get(session.id)?.state ?? "ready" })
      } else if (event.type === "session.status") {
        const session = sessions.get(event.properties.sessionID) ?? { title: "Untitled session", state: "ready" as const }
        touch(event.properties.sessionID, { ...session, state: event.properties.status.type === "idle" ? "ready" : "running" })
      } else if (event.type === "session.idle") {
        const session = sessions.get(event.properties.sessionID) ?? { title: "Untitled session", state: "ready" as const }
        touch(event.properties.sessionID, { ...session, state: "ready" })
      } else if (event.type === "todo.updated") {
        const session = sessions.get(event.properties.sessionID) ?? { title: "Untitled session", state: "running" as const }
        const inProgress = event.properties.todos.findIndex((item) => item.status === "in_progress")
        const complete = event.properties.todos.every((item) => item.status === "completed" || item.status === "cancelled")
        touch(event.properties.sessionID, { ...session, todo: { current: inProgress >= 0 ? inProgress + 1 : complete ? event.properties.todos.length : 0, total: event.properties.todos.length } })
      } else if (event.type === "session.deleted") {
        const session = sessions.get(event.properties.info.id)
        if (session) touch(event.properties.info.id, { ...session, state: "ready" })
      }
    },
  }
}
