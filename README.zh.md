# ocrtool-mcp

[🇺🇸 English Documentation](README.md)

**ocrtool-mcp** 是一个基于 macOS Vision 框架构建的原生 OCR MCP Server，使用 Swift 实现，面向本地 stdio 集成，可被 Claude Desktop、Cursor、Continue、Windsurf、Cline、Cherry Studio 等工具调用。

![platform](https://img.shields.io/badge/platform-macOS-blue)
![language](https://img.shields.io/badge/language-Swift-orange)
![mcp](https://img.shields.io/badge/MCP-compatible-brightgreen)
![license](https://img.shields.io/github/license/ihugang/ocrtool-mcp)

---

## ✨ 功能特性

- ✅ 基于 macOS 原生 Vision 框架的高精度 OCR
- ✅ 支持中文和英文混合识别
- ✅ 提供标准 MCP 生命周期：`initialize`、`tools/list`、`tools/call`
- ✅ 内置 `ocr-workflow` skill，适合更偏向 skill 的 agent 平台
- ✅ 返回包含像素坐标的逐行文字识别结果
- ✅ 支持多种图片输入方式（本地路径、URL、Base64）
- ✅ 灵活的输出格式（纯文本、Markdown 表格、JSON、代码注释）
- ✅ 快速、轻量、离线运行
- ✅ 开源免费软件

---

## 📦 安装

### 我该选 Skill 还是 MCP？

对大多数普通用户，可以直接这样判断：

- 如果你的 agent 平台支持 **skill**，优先用仓库内置的 skill，体验更像自然语言工作流
- 如果你的 agent 平台支持 **MCP server** 配置，就接入 `ocrtool-mcp` 作为工具

实际可按下面理解：

- **Codex / Claude 且支持 skills**：优先安装 skill
- **Claude Desktop / Cursor / Continue / Windsurf / Cline / Cherry Studio**：优先配置 MCP
- **不确定**：如果平台有 skills 目录，就先装 skill；否则就走 MCP

### 方法 1：使用 Homebrew（最简单）

Homebrew 的可用状态以发布流水线为准：请在 GitHub Actions 的 release workflow 完成并同步 `Formula/ocrtool-mcp.rb` 之后，再执行 Homebrew 安装或升级。

```bash
brew tap ihugang/ocrtool
brew install ocrtool-mcp
```

安装完成后直接可用：
```bash
ocrtool-mcp --help
```

### 方法 2：下载预编译版本

直接下载已编译好的 Universal Binary，支持所有 Mac（Intel 和 Apple Silicon）：

```bash
VERSION="<release-version>"
curl -L -O "https://github.com/ihugang/ocrtool-mcp/releases/download/v${VERSION}/ocrtool-mcp-v${VERSION}-universal-macos.tar.gz"

# 解压
tar -xzf "ocrtool-mcp-v${VERSION}-universal-macos.tar.gz"

# 授予执行权限
chmod +x "ocrtool-mcp-v${VERSION}-universal"

# 移动到系统路径（推荐）
sudo mv "ocrtool-mcp-v${VERSION}-universal" /usr/local/bin/ocrtool-mcp

# 验证安装
ocrtool-mcp --help
```

**或者**，你也可以直接从 [GitHub Releases](https://github.com/ihugang/ocrtool-mcp/releases) 页面下载。

### 方法 3：从源码编译

如果你想自己编译或参与开发：

```bash
git clone https://github.com/ihugang/ocrtool-mcp.git
cd ocrtool-mcp
swift build -c release
```

编译完成后，可执行文件位于 `.build/release/ocrtool-mcp`

### 方法 4：安装仓库内置 Skill

如果你的 agent 平台更适合走 skill 而不是直接接 MCP，这个仓库内置了可复用的 `ocr-workflow` skill，并由本地 `ocrtool-mcp` 二进制提供能力。

安装到 Codex：

```bash
./scripts/install-skill.sh codex
```

安装到 Claude：

```bash
./scripts/install-skill.sh claude
```

skill 源码位于 `skill/ocr-workflow/`，也可以手动复制到其他 skill 目录。

#### 普通用户怎么做

1. 先安装或编译 `ocrtool-mcp`
2. 把 skill 安装到 agent 的 skills 目录
3. 如有需要，重启 agent
4. 然后直接用自然语言提需求，例如：
   - `提取 ~/Desktop/receipt.png 里的文字`
   - `把这张截图 OCR 成 markdown`

如果你的 agent 不支持 skill，就跳过这里，直接看下面的 MCP 配置。

---

## 🚀 快速开始

### 作为 Skill 使用

安装 skill 后，可以直接让 agent 用自然语言做 OCR，例如：

- `提取 ~/Desktop/receipt.png 里的文字`
- `把这张截图 OCR 成 markdown 表格`
- `识别图片中的文本并转成 Python 注释`

### 查看帮助信息

```bash
ocrtool-mcp --help
# 或者如果从源码编译
.build/release/ocrtool-mcp --help
```

### 作为 MCP 模块运行

```bash
ocrtool-mcp
# 或者如果从源码编译
.build/release/ocrtool-mcp
```

通过 stdin 走典型 MCP 生命周期：
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

然后发送：

```json
{"jsonrpc":"2.0","method":"notifications/initialized"}
```

列出工具：

```json
{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}
```

调用 OCR 工具：

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

## 📋 参数说明

### 核心参数

| 参数名 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `image` / `image_path` | String | 本地图片路径（支持相对路径和 `~` 扩展） | `"~/Desktop/test.jpg"` |
| `url` | String | 图片 URL 地址（自动下载） | `"https://example.com/img.jpg"` |
| `base64` | String | Base64 编码的图片数据 | `"iVBORw0KGgo..."` |
| `lang` | String | 识别语言，用 `+` 分隔 | `"zh+en"`（默认）<br>`"en"` |
| `enhanced` | Boolean | 是否使用增强识别 | `true`（默认） |
| `format` | String | 输出格式 | 见下方格式说明 |
| `output.insertAsComment` | Boolean | 是否将结果格式化为代码注释 | `true` / `false` |
| `output.language` | String | 代码注释的语言风格 | `"python"`, `"swift"`, `"html"` |

**注意**：`image`/`image_path`、`url`、`base64` 三者必须且只能提供一个。在 MCP 调用里，这些字段位于 `params.arguments` 下。

## 文档结构

- 根目录核心文档：
  - `README.md`
  - `README.zh.md`
  - `CHANGELOG.md`
  - `VERSION`
- 补充文档：
  - [`docs/README.md`](docs/README.md)
  - [`docs/CODE_SIGNING.md`](docs/CODE_SIGNING.md)

### 输出格式说明（`format` 参数）

| 格式值 | 说明 | 输出示例 |
|--------|------|----------|
| `text` / `simple` | 纯文本，每行一个识别结果 | `你好\nHello` |
| `table` / `markdown` | Markdown 表格（包含坐标） | 见下方示例 |
| `structured` / `full` | 包含 bbox 的 JSON 字符串 | `{"lines":[...]}` |
| `auto` | 自动选择：单行用 text，多行用 table | - |

---

## 🛠 AI 工具配置指南

### 给普通用户：怎样让 agent 用上这个项目

这个项目有两种接入方式：

1. **Skill 模式**
   - 适合支持 skills 的 agent 平台
   - 你安装内置的 `ocr-workflow` skill
   - agent 通过自然语言工作流调用本地 OCR 能力

2. **MCP 模式**
   - 适合支持 MCP server 配置的平台
   - 你把 `ocrtool-mcp` 可执行文件接进去
   - agent 会把 `ocr_extract_text` 当成工具使用

经验法则：

- 如果产品让你配置 **skills 目录**，就安装 skill
- 如果产品让你配置 **MCP server command**，就接 MCP
- 如果两者都支持，skill 更适合普通用户，MCP 更适合底层工具集成

### Claude Desktop (Claude Code)

Claude Desktop 使用 `claude_desktop_config.json` 配置 MCP 服务器。

**配置文件位置**：
- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`

**配置示例**：

```json
{
  "mcpServers": {
    "ocrtool": {
      "command": "/path/to/ocrtool-mcp/.build/release/ocrtool-mcp"
    }
  }
}
```

**使用方式**：

在 Claude Desktop 中直接对话：
```
请识别这张图片：~/Desktop/screenshot.png
```

或者更具体：
```
使用 `ocr_extract_text` 识别 `~/Desktop/receipt.jpg` 中的文字，并输出为表格格式
```

当前工具名为 `ocr_extract_text`。

### Cursor

**配置文件位置**：
- macOS: `~/.cursor/config.json` 或通过 Cursor 设置界面

**配置示例**：

```json
{
  "mcpServers": {
    "ocrtool-mcp": {
      "command": "/path/to/ocrtool-mcp/.build/release/ocrtool-mcp"
    }
  }
}
```

**使用方式**：

在 Cursor 的 AI 聊天窗口中：
```
@ocrtool-mcp 识别这个图片的文字：./assets/diagram.png
```

### Continue

**配置文件位置**：
- macOS: `~/.continue/config.json`

**配置示例**：

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

**配置方式**（通过设置界面）：

1. 打开 Windsurf 设置
2. 找到 MCP Servers 配置
3. 添加新服务器：
   - Name: `ocrtool-mcp`
   - Command: `/path/to/ocrtool-mcp/.build/release/ocrtool-mcp`

### Cline (VSCode 插件)

**配置文件位置**：
- macOS: `~/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`

**配置示例**：

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

**配置方式**（通过 UI 界面）：

1. 打开 Cherry Studio 设置
2. 进入 `设置 → MCP 服务器 → 添加服务器`
3. 填写服务器信息：
   - **名称 (Name)**: `ocrtool-mcp`
   - **类型 (Type)**: `STDIO`
   - **命令 (Command)**: `/path/to/ocrtool-mcp/.build/release/ocrtool-mcp`
   - **参数 (Arguments)**: （留空）
   - **环境变量**: （留空）
4. 保存配置

**使用方式**：

在 Cherry Studio 聊天界面中，如果模型支持 MCP 工具调用，你会看到扳手图标，可以直接调用 OCR 功能：
```
识别这张图片中的文字：~/Desktop/screenshot.png
```

---

## 💡 使用示例

### 示例 1：识别本地图片（纯文本输出）

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

**输出**：
```
你好世界
Hello World
```

### 示例 2：识别网络图片（Markdown 表格）

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

**输出**：
```markdown
| Text | X | Y | Width | Height |
|------|---|---|--------|--------|
| 商品名称 | 120 | 50 | 200 | 30 |
| 总计：¥99.00 | 120 | 450 | 250 | 28 |
```

### 示例 3：Base64 图片识别

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

### 示例 4：生成 Python 注释格式

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

**输出**：
```python
# def hello():
#     print("Hello World")
```

---

## 🐍 Python 调用示例

项目包含一个实用的 Python 示例脚本 `test/python/rename_images_by_ocr.py`，演示如何使用 OCR 自动重命名桌面上的乱码图片文件。

```python
import json
import subprocess

def ocr_image(image_path, ocr_tool_path):
    """通过 MCP 的 tools/call 接口调用 ocrtool-mcp。"""
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

# 使用示例
lines = ocr_image("~/Desktop/test.png",
                  "/path/to/ocrtool-mcp/.build/release/ocrtool-mcp")
for line in lines:
    print(f"文字: {line['text']}, 坐标: {line['bbox']}")
```

---

## 🔧 故障排查

### 问题 1：提示 "command not found"

**解决方案**：确保使用编译后可执行文件的完整路径，例如：
```bash
/Users/username/ocrtool-mcp/.build/release/ocrtool-mcp
```

### 问题 2：Claude Desktop 无法调用 MCP 服务器

**解决方案**：
1. 检查配置文件路径是否正确
2. 重启 Claude Desktop 应用
3. 查看日志文件（如果有）确认错误信息

### 问题 3：识别结果为空

**解决方案**：
1. 确认图片路径正确且文件存在
2. 确认图片格式支持（PNG、JPG、JPEG、BMP、GIF、TIFF）
3. 检查图片是否包含可识别文字
4. 尝试使用 `enhanced: true` 参数提高识别精度

### 问题 4：权限错误

**解决方案**：
```bash
chmod +x .build/release/ocrtool-mcp
```

---

## 📁 项目结构

```
.
├── Package.swift                      # Swift 包配置
├── Sources/OCRToolMCP/main.swift      # 主程序源码
├── test/python/rename_images_by_ocr.py # Python 调用示例
├── README.md                          # 英文文档
├── README.zh.md                       # 中文文档
├── LICENSE                            # MIT 许可证
└── .gitignore
```

---

## 👨‍💻 作者

- 胡刚 ([ihugang](https://github.com/ihugang))

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📝 许可协议

MIT License
