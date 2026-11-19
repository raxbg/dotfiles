import { randomUUID } from "node:crypto"
import { createConnection, type Socket } from "node:net"
import { basename, join } from "node:path"
import { Plugin } from "@opencode/plugin"

type Session = {
  title: string
  state: "running" | "ready"
  todo?: { current: number; total: number }
}

const escape = (text: string) => text.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;")

async function setup(ctx: Plugin.Context) {
  const runtime = process.env.XDG_RUNTIME_DIR
  if (!runtime) return
  const socketPath = join(runtime, "waybar-agent-status", "socket")
  const workspace = (process.env.OPENCODE_WORKSPACE ?? basename(ctx.location.directory)).slice(0, 200)
  const id = randomUUID()
  const sessions = new Map<string, Session>()
  let socket: Socket | undefined
  let connected = false
  let retry: ReturnType<typeof setTimeout> | undefined

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
      retry = setTimeout(connect, 1000).unref()
    })
  }

  // V2 has no public todo.updated event.
  await ctx.tool.hook("execute.after", ({ tool, status, sessionID, input }) => {
    if (tool !== "todowrite" || status !== "completed") return
    const todos = (input as { todos?: { status: string }[] } | undefined)?.todos
    if (!Array.isArray(todos)) return
    const session = sessions.get(sessionID) ?? { title: "Untitled session", state: "running" as const }
    const inProgress = todos.findIndex((item) => item.status === "in_progress")
    const complete = todos.every((item) => item.status === "completed" || item.status === "cancelled")
    touch(sessionID, { ...session, todo: { current: inProgress >= 0 ? inProgress + 1 : complete ? todos.length : 0, total: todos.length } })
  })

  const controller = new AbortController()
  connect()
  void (async () => {
    for await (const event of ctx.event.subscribe({
      types: ["session.created", "session.renamed", "session.status", "session.idle", "session.deleted"],
      signal: controller.signal,
    })) {
      const { sessionID } = event.data
      // Rename and delete events can omit the location; only apply those to tracked sessions.
      if (event.location ? event.location.directory !== ctx.location.directory || event.location.workspaceID !== ctx.location.workspaceID : !sessions.has(sessionID)) continue
      const session = sessions.get(sessionID) ?? { title: "Untitled session", state: "ready" as const }
      if (event.type === "session.created" || event.type === "session.renamed") {
        touch(sessionID, { ...session, title: event.data.title?.slice(0, 200) || "Untitled session" })
      } else if (event.type === "session.deleted") {
        if (sessions.delete(sessionID)) publish()
      } else {
        touch(sessionID, { ...session, state: event.type === "session.status" && event.data.status.type !== "idle" ? "running" : "ready" })
      }
    }
  })().catch((error) => { if (!controller.signal.aborted) console.error("agent-status event stream failed", error) })

  return () => {
    controller.abort()
    clearTimeout(retry)
    socket?.destroy()
    socket = undefined
  }
}

export default Plugin.define({ id: "agent-status", setup })
