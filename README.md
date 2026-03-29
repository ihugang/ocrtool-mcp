# ocrtool-mcp

[🇨🇳 中文文档](README.zh.md)

**ocrtool-mcp** is an open-source macOS-native OCR MCP server built with Swift and the Vision framework. It is designed for local stdio integrations in tools like Claude Desktop, Cursor, Continue, Windsurf, Cline, Cherry Studio, or custom agents using JSON-RPC over stdin.

![platform](https://img.shields.io/badge/platform-macOS-blue)
![language](https://img.shields.io/badge/language-Swift-orange)
![mcp](https://img.shields.io/badge/MCP-compatible-brightgreen)
![license](https://img.shields.io/github/license/ihugang/ocrtool-mcp)

---

## ✨ Features

- ✅ Accurate OCR powered by macOS Vision Framework
- ✅ Recognizes both Chinese and English text
- ✅ Standard MCP lifecycle with `initialize`, `tools/list`, and `tools/call`
- ✅ Bundled `ocr-workflow` skill for agent platforms that prefer skills over raw MCP
- ✅ Returns line-wise OCR results with bounding boxes (in pixels)
- ✅ Multiple image input methods (local path, URL, Base64)
- ✅ Flexible output formats (plain text, Markdown table, JSON, code comments)
- ✅ Lightweight, fast, and fully offline
- ✅ Open source free software

---

## 📦 Installation

### Which One Should You Use?

For most users, the choice is simple:

- Use the **bundled skill** when your agent platform supports skills and you want a more guided, natural-language workflow.
- Use **MCP** when your agent platform supports MCP servers and you want `ocrtool-mcp` exposed as a standard tool.

In practical terms:

- **Codex / Claude with skills support**: install the skill first
- **Claude Desktop / Cursor / Continue / Windsurf / Cline / Cherry Studio**: connect the MCP server
- **Not sure**: start with the skill if your platform has a skills directory; otherwise use MCP

### Method 1: Using Homebrew (Easiest)

Homebrew availability follows the release pipeline: install or upgrade with Homebrew after the GitHub Actions release workflow finishes and syncs `Formula/ocrtool-mcp.rb`.

```bash
brew tap ihugang/ocrtool
brew install ocrtool-mcp
```

Ready to use after installation:
```bash
ocrtool-mcp --help
```

### Method 2: Download Pre-built Binary

Download the pre-compiled Universal Binary that supports all Macs (Intel and Apple Silicon):

```bash
VERSION="<release-version>"
curl -L -O "https://github.com/ihugang/ocrtool-mcp/releases/download/v${VERSION}/ocrtool-mcp-v${VERSION}-universal-macos.tar.gz"

# Extract
tar -xzf "ocrtool-mcp-v${VERSION}-universal-macos.tar.gz"

# Make executable
chmod +x "ocrtool-mcp-v${VERSION}-universal"

# Move to system path (recommended)
sudo mv "ocrtool-mcp-v${VERSION}-universal" /usr/local/bin/ocrtool-mcp

# Verify installation
ocrtool-mcp --help
```

**Alternatively**, you can download directly from the [GitHub Releases](https://github.com/ihugang/ocrtool-mcp/releases) page.

### Method 3: Build from Source

If you prefer to build from source or contribute to development:

```bash
git clone https://github.com/ihugang/ocrtool-mcp.git
cd ocrtool-mcp
swift build -c release
```

The executable will be located at `.build/release/ocrtool-mcp`

### Method 4: Install the Bundled Skill

If your agent platform supports skills, this repo ships a reusable `ocr-workflow` skill that wraps the local `ocrtool-mcp` binary.

Install into Codex:

```bash
./scripts/install-skill.sh codex
```

Install into Claude:

```bash
./scripts/install-skill.sh claude
```

The skill bundle lives in `skill/ocr-workflow/` and can also be copied into another skill directory manually.

#### What a normal user should do

1. Install or build `ocrtool-mcp`
2. Install the skill into the agent's skills directory
3. Restart the agent if needed
4. Ask naturally:
   - `Extract text from ~/Desktop/receipt.png`
   - `OCR this screenshot and return markdown`

If your agent does not support skills, skip this and use the MCP setup below.

---

## 🚀 Quick Start

### Use as a Skill

After installing the bundled skill, ask your agent for OCR work in plain language, for example:

- `Extract the text from ~/Desktop/receipt.png`
- `OCR this screenshot and return a markdown table`
- `Read this image and turn the text into Python comments`

### View Help

```bash
ocrtool-mcp --help
# Or if built from source
.build/release/ocrtool-mcp --help
```

### Run as MCP Module

```bash
ocrtool-mcp
# Or if built from source
.build/release/ocrtool-mcp
```

Typical MCP lifecycle over stdin:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "initialize",
  "params": {
    "protocolVersion": "2024-11-05",
    "capabilities": {},
    "clientInfo": {
      "name": "example-client",
      "version": "0.1.0"
    }
  }
}
```

Then send:

```json
{"jsonrpc":"2.0","method":"notifications/initialized"}
```

List available tools:

```json
{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}
```

Call the OCR tool:

```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "tools/call",
  "params": {
    "name": "ocr_extract_text",
    "arguments": {
      "image_path": "test.jpg",
      "lang": "zh+en",
      "format": "text"
    }
  }
}
```

---

## 📋 Parameters

### Core Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `image` / `image_path` | String | Local image path (supports relative path and `~` expansion) | `"~/Desktop/test.jpg"` |
| `url` | String | Image URL (auto-download) | `"https://example.com/img.jpg"` |
| `base64` | String | Base64-encoded image data | `"iVBORw0KGgo..."` |
| `lang` | String | Recognition languages, separated by `+` | `"zh+en"` (default)<br>`"en"` |
| `enhanced` | Boolean | Use enhanced recognition | `true` (default) |
| `format` | String | Output format | See format options below |
| `output.insertAsComment` | Boolean | Format result as code comments | `true` / `false` |
| `output.language` | String | Language style for code comments | `"python"`, `"swift"`, `"html"` |

**Note**: Exactly one of `image`/`image_path`, `url`, or `base64` must be provided. In MCP calls, these fields live under `params.arguments`.

### Output Format Options (`format` parameter)

| Format Value | Description | Output Example |
|--------------|-------------|----------------|
| `text` / `simple` | Plain text, one line per result | `Hello\nWorld` |
| `table` / `markdown` | Markdown table (with coordinates) | See examples below |
| `structured` / `full` | JSON string containing OCR lines with bounding boxes | `{"lines":[...]}` |
| `auto` | Auto-select: text for single line, table for multiple | - |

---

## 🛠 AI Tool Configuration Guide

### For ordinary users: how to make an agent use this project

There are two integration styles:

1. **Skill mode**
   - Best when the agent supports skills
   - You install the bundled `ocr-workflow` skill
   - The agent then uses natural-language OCR workflows backed by the local binary

2. **MCP mode**
   - Best when the agent supports MCP server configuration
   - You point the agent at the `ocrtool-mcp` executable
   - The agent sees `ocr_extract_text` as a tool

Rule of thumb:

- If the product asks you for a **skills folder**, install the skill
- If the product asks you for an **MCP server command**, configure MCP
- If it supports both, skill is the friendlier user experience and MCP is the lower-level tool integration

### Claude Desktop (Claude Code)

Claude Desktop uses `claude_desktop_config.json` to configure MCP servers.

**Configuration File Location**:
- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`

**Configuration Example**:

```json
{
  "mcpServers": {
    "ocrtool": {
      "command": "/path/to/ocrtool-mcp/.build/release/ocrtool-mcp"
    }
  }
}
```

**Usage**:

In Claude Desktop chat:
```
Please recognize this image: ~/Desktop/screenshot.png
```

Or more specifically:
```
Use `ocr_extract_text` to recognize text in `~/Desktop/receipt.jpg` and output as a table
```

The tool name is now `ocr_extract_text`.

### Cursor

**Configuration File Location**:
- macOS: `~/.cursor/config.json` or via Cursor Settings UI

**Configuration Example**:

```json
{
  "mcpServers": {
    "ocrtool-mcp": {
      "command": "/path/to/ocrtool-mcp/.build/release/ocrtool-mcp"
    }
  }
}
```

**Usage**:

In Cursor AI chat:
```
@ocrtool-mcp recognize text from this image: ./assets/diagram.png
```

### Continue

**Configuration File Location**:
- macOS: `~/.continue/config.json`

**Configuration Example**:

```json
{
  "experimental": {
    "modelContextProtocolServers": [
      {
        "name": "ocrtool-mcp",
        "command": "/path/to/ocrtool-mcp/.build/release/ocrtool-mcp"
      }
    ]
  }
}
```

### Windsurf

**Configuration** (via Settings UI):

1. Open Windsurf Settings
2. Find MCP Servers configuration
3. Add new server:
   - Name: `ocrtool-mcp`
   - Command: `/path/to/ocrtool-mcp/.build/release/ocrtool-mcp`

### Cline (VSCode Extension)

**Configuration File Location**:
- macOS: `~/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`

**Configuration Example**:

```json
{
  "mcpServers": {
    "ocrtool-mcp": {
      "command": "/path/to/ocrtool-mcp/.build/release/ocrtool-mcp"
    }
  }
}
```

### Cherry Studio

**Configuration** (via UI):

1. Open Cherry Studio Settings
2. Navigate to `Settings → MCP Servers → Add Server`
3. Fill in server information:
   - **Name**: `ocrtool-mcp`
   - **Type**: `STDIO`
   - **Command**: `/path/to/ocrtool-mcp/.build/release/ocrtool-mcp`
   - **Arguments**: (leave empty)
   - **Environment Variables**: (leave empty)
4. Save configuration

**Usage**:

In Cherry Studio chat interface, if the model supports MCP tool calls, you'll see a wrench icon to directly invoke OCR functionality:
```
Recognize text from this image: ~/Desktop/screenshot.png
```

---

## 💡 Usage Examples

### Example 1: Recognize Local Image (Plain Text Output)

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "ocr_extract_text",
    "arguments": {
      "image_path": "~/Desktop/screenshot.png",
      "format": "text"
    }
  }
}
```

**Output**:
```
你好世界
Hello World
```

### Example 2: Recognize Image from URL (Markdown Table)

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "tools/call",
  "params": {
    "name": "ocr_extract_text",
    "arguments": {
      "url": "https://example.com/receipt.jpg",
      "lang": "zh+en",
      "format": "markdown"
    }
  }
}
```

**Output**:
```markdown
| Text | X | Y | Width | Height |
|------|---|---|--------|--------|
| 商品名称 | 120 | 50 | 200 | 30 |
| 总计：¥99.00 | 120 | 450 | 250 | 28 |
```

### Example 3: Base64 Image Recognition

```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "tools/call",
  "params": {
    "name": "ocr_extract_text",
    "arguments": {
      "base64": "iVBORw0KGgoAAAANSUhEUgAAAAUA...",
      "format": "structured"
    }
  }
}
```

### Example 4: Generate Python Comment Format

```json
{
  "jsonrpc": "2.0",
  "id": 4,
  "method": "tools/call",
  "params": {
    "name": "ocr_extract_text",
    "arguments": {
      "image_path": "./code_screenshot.png",
      "output": {
        "insertAsComment": true,
        "language": "python"
      }
    }
  }
}
```

**Output**:
```python
# def hello():
#     print("Hello World")
```

---

## 🐍 Python Usage Example

The project includes a practical Python example script `test/python/rename_images_by_ocr.py` that demonstrates how to use OCR to automatically rename garbled image files on the desktop.

```python
import json
import subprocess

def ocr_image(image_path, ocr_tool_path):
    """Call ocrtool-mcp through the MCP tools/call interface."""
    initialize = json.dumps({
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {"name": "python-example", "version": "0.1.0"}
        }
    })
    initialized = json.dumps({
        "jsonrpc": "2.0",
        "method": "notifications/initialized"
    })
    tool_call = json.dumps({
        "jsonrpc": "2.0",
        "id": 2,
        "method": "tools/call",
        "params": {
            "name": "ocr_extract_text",
            "arguments": {
                "image_path": image_path,
                "format": "structured",
                "lang": "zh+en"
            }
        }
    })

    cmd = f"printf '%s\\n%s\\n%s\\n' '{initialize}' '{initialized}' '{tool_call}' | {ocr_tool_path}"
    proc = subprocess.Popen(cmd, shell=True,
                          stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE)
    out, err = proc.communicate()

    responses = [json.loads(line) for line in out.decode().splitlines() if line.strip()]
    tool_result = responses[-1]["result"]["content"][0]["text"]
    return json.loads(tool_result).get("lines", [])

# Usage example
lines = ocr_image("~/Desktop/test.png",
                  "/path/to/ocrtool-mcp/.build/release/ocrtool-mcp")
for line in lines:
    print(f"Text: {line['text']}, BBox: {line['bbox']}")
```

---

## 🔧 Troubleshooting

### Issue 1: "command not found"

**Solution**: Use the full path to the compiled executable, e.g.:
```bash
/Users/username/ocrtool-mcp/.build/release/ocrtool-mcp
```

### Issue 2: Claude Desktop Cannot Call MCP Server

**Solution**:
1. Check that the configuration file path is correct
2. Restart Claude Desktop application
3. Check log files (if available) for error messages

### Issue 3: Empty Recognition Results

**Solution**:
1. Verify the image path is correct and file exists
2. Verify the image format is supported (PNG, JPG, JPEG, BMP, GIF, TIFF)
3. Check if the image contains recognizable text
4. Try using `enhanced: true` parameter for better accuracy

### Issue 4: Permission Error

**Solution**:
```bash
chmod +x .build/release/ocrtool-mcp
```

---

## 📁 Project Structure

```
.
├── Package.swift                      # Swift package configuration
├── Sources/OCRToolMCP/main.swift      # Main program source
├── test/python/rename_images_by_ocr.py # Python usage example
├── README.md                          # English documentation
├── README.zh.md                       # Chinese documentation
├── LICENSE                            # MIT License
└── .gitignore
```

---

## 👨‍💻 Author

- Hu Gang ([ihugang](https://github.com/ihugang))

## 🤝 Contributing

Issues and Pull Requests are welcome!

## 📝 License

MIT License
