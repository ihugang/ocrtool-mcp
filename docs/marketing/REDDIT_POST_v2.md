# Reddit Post v2: ocrtool-mcp

---

## Title Options

1. **[Show HN] I built a macOS OCR tool for agents that works as both MCP and a reusable skill**
2. **[Release] ocrtool-mcp v1.0.6 - macOS OCR for agents, now with both MCP and skill workflows**
3. **Built a local OCR tool for AI agents on macOS: use it as MCP or install it as a skill**

---

## Post Body

I’ve been working on a local OCR project for macOS called `ocrtool-mcp`.

It started as a pure MCP server, but after iterating on real usage I realized a lot of people don’t actually want to think in terms of “protocols” first. They just want:

- their agent to read text from screenshots / receipts / scanned images
- a simple way to install it
- a workflow that feels natural in chat

So I pushed the project in a more practical direction:

- **MCP mode** for tools that support MCP servers
- **skill mode** for tools/agents that work better with installable skills

That means the same OCR core can now be used in two ways:

1. **As an MCP server**
   - agent sees `ocr_extract_text` as a tool
   - works well for Claude Desktop, Cursor, Continue, Windsurf, Cline, Cherry Studio, etc.

2. **As a bundled skill**
   - better for agent platforms where users think in “install a skill, then ask naturally”
   - wraps the local OCR binary instead of reimplementing OCR

### What it does

`ocrtool-mcp` is a lightweight macOS-native OCR tool built with Swift + Vision framework.

It can extract text from:

- local image paths
- image URLs
- base64 image data

And it can return results as:

- plain text
- markdown tables
- structured JSON
- code comments

### Why I think the skill + MCP split matters

I used to assume “if it’s MCP-compatible, that’s enough”.

In practice, that’s only true for users who already know how to wire MCP servers.

For many normal users, the real question is:

- “Do I install a skill?”
- “Do I configure an MCP command?”
- “Which one does my agent support?”

So the repo now explicitly supports both mental models.

### Current release highlights

- macOS native OCR via Vision Framework
- offline / privacy-friendly
- universal binary for Intel + Apple Silicon
- MCP tool interface
- bundled `ocr-workflow` skill
- installer script for skill-based setups
- release workflow that publishes binary artifacts and syncs the Homebrew formula

### Example install paths

**If your agent supports MCP:**

point it at the binary:

```json
{
  "mcpServers": {
    "ocrtool": {
      "command": "/usr/local/bin/ocrtool-mcp"
    }
  }
}
```

**If your agent supports skills:**

install the bundled skill:

```bash
./scripts/install-skill.sh codex
```

or:

```bash
./scripts/install-skill.sh claude
```

### Why I built it

I wanted OCR in agent workflows without:

- cloud OCR APIs
- Python environment friction
- glue code for every tool
- manually copy-pasting text out of screenshots all day

The project is still intentionally small and local-first.

### Tech details

- Swift
- macOS Vision Framework
- JSON-RPC / MCP over stdio
- local binary + skill wrapper
- MIT licensed

### Links

- GitHub: https://github.com/ihugang/ocrtool-mcp
- Latest release: https://github.com/ihugang/ocrtool-mcp/releases/tag/v1.0.6
- README: https://github.com/ihugang/ocrtool-mcp/blob/master/README.md

### Feedback I’d love

- Which agent/tool would you want this packaged for next?
- Do you prefer using OCR via MCP or via a skill?
- If you’re a normal user, is the install story understandable now?

---

## Suggested Subreddits

- r/MacOS
- r/LocalLLaMA
- r/opensource
- r/programming
- r/swift

---

## Posting Angle

If posting to more technical communities, emphasize:

- local OCR on macOS
- Vision framework
- MCP implementation details
- release automation / formula sync

If posting to more agent-focused communities, emphasize:

- “works as both MCP and skill”
- ordinary-user install path
- natural-language OCR workflow
