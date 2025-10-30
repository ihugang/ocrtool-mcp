# Reddit Post: ocrtool-mcp

---

## Title

**[Release] ocrtool-mcp v1.0.0 - Native macOS OCR tool implementing Model Context Protocol**

---

## Post Body

I've built a lightweight macOS-native OCR tool that implements the Model Context Protocol (MCP), making it easy to add OCR capabilities to AI assistants like Claude Desktop, Cursor, and other MCP-compatible tools.

### What is it?

ocrtool-mcp is a command-line OCR tool that uses macOS Vision Framework for text recognition. It implements MCP (Model Context Protocol), which means AI tools can directly call it to extract text from images during conversations.

### Key Features

- Uses macOS native Vision Framework (high accuracy, no external dependencies)
- Supports Chinese and English text recognition
- Returns text with bounding box coordinates
- Multiple input methods: local files, URLs, or base64-encoded images
- Flexible output formats (plain text, markdown tables, JSON, code comments)
- Fully offline and privacy-friendly
- Universal binary supporting both Intel and Apple Silicon Macs

### Supported AI Tools

The tool works with any MCP-compatible client, including:

- Claude Desktop (Claude Code)
- Cursor
- Continue
- Windsurf
- Cline (VSCode extension)
- Cherry Studio

### Installation

**Option 1: Pre-built binary (recommended)**

```bash
curl -L -O https://github.com/ihugang/ocrtool-mcp/releases/download/v1.0.0/ocrtool-mcp-v1.0.0-universal-macos.tar.gz
tar -xzf ocrtool-mcp-v1.0.0-universal-macos.tar.gz
chmod +x ocrtool-mcp-v1.0.0-universal
sudo mv ocrtool-mcp-v1.0.0-universal /usr/local/bin/ocrtool-mcp
```

**Option 2: Build from source**

```bash
git clone https://github.com/ihugang/ocrtool-mcp.git
cd ocrtool-mcp
swift build -c release
```

### Configuration Example (Claude Desktop)

Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "ocrtool": {
      "command": "/usr/local/bin/ocrtool-mcp"
    }
  }
}
```

Restart Claude Desktop, and you can now ask it to OCR images directly.

### Why I built this

I needed a simple way to extract text from screenshots and images while working with Claude Desktop. Existing solutions either required Python environments, external services, or didn't integrate well with MCP. This tool runs entirely offline using macOS native capabilities, so it's fast, private, and has no dependencies.

### Technical Details

- Written in Swift
- Uses Vision Framework for OCR
- Implements MCP JSON-RPC protocol over stdin/stdout
- Binary size: 444 KB (universal binary)
- License: MIT

### Links

- GitHub: https://github.com/ihugang/ocrtool-mcp
- Documentation: See README for detailed configuration examples
- Release: https://github.com/ihugang/ocrtool-mcp/releases/tag/v1.0.0

### Feedback Welcome

This is the first stable release. I'd appreciate any feedback, bug reports, or feature requests. Feel free to open issues on GitHub or comment here.

---

## Suggested Subreddits

- r/MacOS
- r/ClaudeDev (if exists)
- r/LocalLLaMA
- r/programming
- r/swift (for technical discussion)
- r/opensource

---

## Tips for Posting

1. Read each subreddit's rules before posting
2. Use appropriate flair (e.g., "Show and Tell", "Project", "Release")
3. Be responsive to comments and questions
4. Don't cross-post too frequently (wait a few days between posts)
5. Consider different angles for different subreddits:
   - r/MacOS: Focus on macOS integration
   - r/LocalLLaMA: Focus on MCP and AI integration
   - r/programming: Focus on technical implementation
