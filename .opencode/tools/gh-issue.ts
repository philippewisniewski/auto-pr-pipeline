import { tool } from "@opencode-ai/plugin"
import { mkdtempSync, writeFileSync } from "fs"
import { join } from "path"
import { tmpdir } from "os"

export const list = tool({
  description: "List GitHub issues with filters",
  args: {
    limit: tool.schema.number().optional().default(10),
    state: tool.schema.enum(["open", "closed", "all"]).optional().default("open"),
    label: tool.schema.string().optional(),
  },
  async execute(args, context) {
    const cmd = ["gh", "issue", "list", "--limit", String(args.limit!), "--state", args.state!, "--json", "number,title,labels,state"]
    if (args.label) cmd.push("--label", args.label)
    const proc = Bun.spawn(cmd)
    const result = await new Response(proc.stdout).text()
    return result.trim()
  },
})

export const view = tool({
  description: "View a GitHub issue's title, body, labels, and comments",
  args: {
    number: tool.schema.number(),
    includeComments: tool.schema.boolean().optional().default(false),
  },
  async execute(args, context) {
    if (args.includeComments) {
      const cmd = ["gh", "issue", "view", String(args.number), "--comments", "--json", "title,body,comments,labels", "--jq", "."]
      const proc = Bun.spawn(cmd)
      const result = await new Response(proc.stdout).text()
      if (result.trim()) return result.trim()
    }
    const cmd = ["gh", "issue", "view", String(args.number), "--json", "title,body,labels", "--jq", "."]
    const proc = Bun.spawn(cmd)
    const result = await new Response(proc.stdout).text()
    return result.trim()
  },
})

export const create = tool({
  description: "Create a new GitHub issue",
  args: {
    title: tool.schema.string(),
    body: tool.schema.string(),
    labels: tool.schema.string().optional(),
  },
  async execute(args, context) {
    const tmp = mkdtempSync(join(tmpdir(), "gh-issue-"))
    const bodyFile = join(tmp, "body.md")
    writeFileSync(bodyFile, args.body, "utf-8")
    const cmd = ["gh", "issue", "create", "--title", args.title, "--body-file", bodyFile]
    if (args.labels) cmd.push("--label", args.labels)
    const proc = Bun.spawn(cmd)
    const url = await new Response(proc.stdout).text()
    const number = url.trim().split("/").pop()
    return JSON.stringify({ url: url.trim(), number })
  },
})
