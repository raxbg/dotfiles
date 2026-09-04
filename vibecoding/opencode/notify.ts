import { createConnection } from "node:net"

function notify(title: string, body: string, urgency = "normal") {
  const socketPath = process.env.OPENCODE_BRIDGE_SOCKET
  if (!socketPath) return Promise.resolve()

  return new Promise<void>((resolve) => {
    const socket = createConnection(socketPath)
    const timeout = setTimeout(() => socket.destroy(), 10_000)

    socket.on("connect", () => socket.end(`${JSON.stringify({ type: "notification", title, body, urgency })}\n`))
    socket.on("close", () => {
      clearTimeout(timeout)
      resolve()
    })
    socket.on("error", () => {})
  })
}

export default async () => {
  const awaitingAttention = new Set<string>()
  const startedAt = new Map<string, number>()
  const checklistSessions = new Set<string>()
  const subagentSessions = new Set<string>()

  return {
    event: async ({ event }) => {
      if (event.type === "session.created" && event.properties.info.parentID) {
        subagentSessions.add(event.properties.info.id)
      }

      if ("sessionID" in event.properties && subagentSessions.has(event.properties.sessionID)) return

      if (event.type === "permission.asked") {
        awaitingAttention.add(event.properties.sessionID)
        await notify("Agent needs approval", "Review the requested operation in OpenCode.", "critical")
      } else if (event.type === "question.asked") {
        awaitingAttention.add(event.properties.sessionID)
        await notify("Agent needs input", "Answer the question in OpenCode.", "normal")
      } else if (event.type === "permission.replied" || event.type === "question.replied") {
        awaitingAttention.delete(event.properties.sessionID)
      } else if (event.type === "session.status" && event.properties.status.type === "busy") {
        if (!startedAt.has(event.properties.sessionID)) startedAt.set(event.properties.sessionID, Date.now())
      } else if (event.type === "todo.updated" && event.properties.todos.length) {
        checklistSessions.add(event.properties.sessionID)
      } else if (event.type === "session.idle") {
        const sessionID = event.properties.sessionID
        const tookMoreThan30Seconds = Date.now() - (startedAt.get(sessionID) ?? Date.now()) > 30_000
        startedAt.delete(sessionID)
        const shouldNotify = !awaitingAttention.has(sessionID) && (tookMoreThan30Seconds || checklistSessions.has(sessionID))
        if (!awaitingAttention.has(sessionID)) checklistSessions.delete(sessionID)
        if (shouldNotify) {
          await notify("Agent completed task", "Agent is ready for your next request.", "low")
        }
      } else if (event.type === "session.deleted") {
        awaitingAttention.delete(event.properties.sessionID)
        startedAt.delete(event.properties.sessionID)
        checklistSessions.delete(event.properties.sessionID)
      }
    },
  }
}
