import { Socket } from "node:net"
import { Plugin } from "@opencode/plugin"

export default Plugin.define({
  id: "notify",
  async setup(ctx) {
    const socketPath = process.env.OPENCODE_BRIDGE_SOCKET
    if (!socketPath) return
    const controller = new AbortController()
    const { signal } = controller
    const awaitingAttention = new Set<string>()
    const startedAt = new Map<string, number>()
    const checklistSessions = new Set<string>()

    const notify = async (sessionID: string, title: string, body: string, urgency: string) => {
      const session = await ctx.session.get({ sessionID }, { signal }).catch(() => undefined)
      if (!session || session.parentID || session.location.directory !== ctx.location.directory || signal.aborted) return
      const socket = new Socket({ signal })
      const timeout = setTimeout(() => socket.destroy(), 10_000)
      socket.on("connect", () => socket.end(`${JSON.stringify({ type: "notification", title, body, urgency })}\n`))
      socket.on("close", () => clearTimeout(timeout))
      socket.on("error", () => {})
      socket.connect(socketPath)
    }

    await ctx.tool.hook("execute.after", ({ tool, status, sessionID, input }) => {
      if (tool !== "todowrite" || status !== "completed") return
      const todos = (input as { todos?: unknown[] } | undefined)?.todos
      if (Array.isArray(todos) && todos.length) checklistSessions.add(sessionID)
    })

    void (async () => {
      for await (const event of ctx.event.subscribe({
        types: ["permission.asked", "permission.replied", "form.created", "form.replied", "form.cancelled", "session.execution.started", "session.execution.succeeded", "session.execution.failed", "session.execution.interrupted", "session.deleted"],
        signal,
      })) {
        const sessionID = event.type === "form.created" ? event.data.form.sessionID : event.data.sessionID
        if (event.location) {
          if (event.location.directory !== ctx.location.directory || event.location.workspaceID !== ctx.location.workspaceID) continue
        } else if (event.type !== "session.deleted") {
          const session = await ctx.session.get({ sessionID }, { signal }).catch(() => undefined)
          if (session?.location.directory !== ctx.location.directory) continue
        }
        if (event.type === "permission.asked") {
          awaitingAttention.add(sessionID)
          await notify(sessionID, "Agent needs approval", "Review the requested operation in OpenCode.", "critical")
        } else if (event.type === "form.created") {
          awaitingAttention.add(sessionID)
          await notify(sessionID, "Agent needs input", "Answer the question in OpenCode.", "normal")
        } else if (event.type === "permission.replied" || event.type === "form.replied" || event.type === "form.cancelled") {
          awaitingAttention.delete(sessionID)
        } else if (event.type === "session.execution.started") {
          startedAt.set(sessionID, event.created)
        } else {
          const start = startedAt.get(sessionID)
          startedAt.delete(sessionID)
          const usedChecklist = checklistSessions.delete(sessionID)
          const waiting = awaitingAttention.delete(sessionID)
          if (event.type === "session.execution.succeeded" && !waiting && (usedChecklist || (start !== undefined && event.created - start > 30_000))) {
            await notify(sessionID, "Agent completed task", "Agent is ready for your next request.", "low")
          }
        }
      }
    })().catch((error) => { if (!signal.aborted) console.error("notify event stream failed", error) })

    return () => controller.abort()
  },
})
