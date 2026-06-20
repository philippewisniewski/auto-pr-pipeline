import { tool } from "@opencode-ai/plugin"
import { mkdtempSync, writeFileSync } from "fs"
import { join } from "path"
import { tmpdir } from "os"

export const list = tool({
  description: "List pull requests with filters",
  args: {
    limit: tool.schema.number().optional().default(5),
    state: tool.schema.enum(["open", "closed", "merged", "all"]).optional().default("open"),
    head: tool.schema.string().optional(),
    base: tool.schema.string().optional(),
  },
  async execute(args, context) {
    const cmd = ["gh", "pr", "list", "--limit", String(args.limit!), "--state", args.state!, "--json", "number,title,headRefName,baseRefName,state"]
    if (args.head) cmd.push("--head", args.head)
    if (args.base) cmd.push("--base", args.base)
    const proc = Bun.spawn(cmd)
    const result = await new Response(proc.stdout).text()
    return result.trim()
  },
})

export const view = tool({
  description: "View a pull request's details",
  args: {
    number: tool.schema.number(),
  },
  async execute(args, context) {
    const cmd = ["gh", "pr", "view", String(args.number), "--json", "title,body,headRefName,baseRefName,state,labels,comments,additions,deletions,files", "--jq", "."]
    const proc = Bun.spawn(cmd)
    const result = await new Response(proc.stdout).text()
    return result.trim()
  },
})

export const create = tool({
  description: "Create a pull request",
  args: {
    title: tool.schema.string(),
    body: tool.schema.string(),
    head: tool.schema.string(),
    base: tool.schema.string().optional().default("main"),
  },
  async execute(args, context) {
    const tmp = mkdtempSync(join(tmpdir(), "gh-pr-"))
    const bodyFile = join(tmp, "body.md")
    writeFileSync(bodyFile, args.body, "utf-8")
    const cmd = ["gh", "pr", "create", "--title", args.title, "--body-file", bodyFile, "--base", args.base!, "--head", args.head]
    const proc = Bun.spawn(cmd)
    const result = await new Response(proc.stdout).text()
    return result.trim()
  },
})
