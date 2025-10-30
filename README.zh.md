# ocrtool-mcp

[🇺🇸 English Documentation](README.md)

**ocrtool-mcp** 是一个基于 macOS Vision 框架构建的原生 OCR 模块，使用 Swift 实现，遵循 [Model Context Protocol (MCP)](https://modelcontextprotocol.io) 协议，可被如 Claude Desktop、Cursor、Continue、Windsurf、Cline、Cherry Studio 等 AI IDE 工具调用。

![platform](https://img.shields.io/badge/platform-macOS-blue)
![language](https://img.shields.io/badge/language-Swift-orange)
![mcp](https://img.shields.io/badge/MCP-compatible-brightgreen)
![license](https://img.shields.io/github/license/ihugang/ocrtool-mcp)

---

## ✨ 功能特性

- ✅ 基于 macOS 原生 Vision 框架的高精度 OCR
- ✅ 支持中文和英文混合识别
- ✅ 提供标准 MCP JSON-RPC 接口
- ✅ 返回包含像素坐标的逐行文字识别结果
- ✅ 支持多种图片输入方式（本地路径、URL、Base64）
- ✅ 灵活的输出格式（纯文本、Markdown 表格、JSON、代码注释）
- ✅ 快速、轻量、离线运行
- ✅ 开源免费软件

---

## 📦 安装

### 方法 1：使用 Homebrew（最简单）

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
# 下载最新版本 (v1.0.0)
curl -L -O https://github.com/ihugang/ocrtool-mcp/releases/download/v1.0.0/ocrtool-mcp-v1.0.0-universal-macos.tar.gz

# 解压
tar -xzf ocrtool-mcp-v1.0.0-universal-macos.tar.gz

# 授予执行权限
chmod +x ocrtool-mcp-v1.0.0-universal

# 移动到系统路径（推荐）
sudo mv ocrtool-mcp-v1.0.0-universal /usr/local/bin/ocrtool-mcp

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

---

## 🚀 快速开始

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

向 stdin 发送 JSON-RPC 请求：
```json
{
  "jsonrpc": "2.0",
  "id": "1",
  "method": "ocr_text",
  "params": {
    "image": "test.jpg",
    "lang": "zh+en",
    "format": "text"
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

**注意**：`image`/`image_path`、`url`、`base64` 三者必须且只能提供一个。

### 输出格式说明（`format` 参数）

| 格式值 | 说明 | 输出示例 |
|--------|------|----------|
| `text` / `simple` | 纯文本，每行一个识别结果 | `你好\nHello` |
| `table` / `markdown` | Markdown 表格（包含坐标） | 见下方示例 |
| `structured` / `full` | 完整 JSON-RPC 响应（包含 bbox） | 见快速开始部分 |
| `auto` | 自动选择：单行用 text，多行用 table | - |

---

## 🛠 AI 工具配置指南

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
使用 ocr_text 工具识别 ~/Desktop/receipt.jpg 中的文字，输出为表格格式
```

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
  "id": "1",
  "method": "ocr_text",
  "params": {
    "image": "~/Desktop/screenshot.png",
    "format": "text"
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
  "id": "2",
  "method": "ocr_text",
  "params": {
    "url": "https://example.com/receipt.jpg",
    "lang": "zh+en",
    "format": "markdown"
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
  "id": "3",
  "method": "ocr_text",
  "params": {
    "base64": "iVBORw0KGgoAAAANSUhEUgAAAAUA...",
    "format": "structured"
  }
}
```

### 示例 4：生成 Python 注释格式

```json
{
  "jsonrpc": "2.0",
  "id": "4",
  "method": "ocr_text",
  "params": {
    "image": "./code_screenshot.png",
    "output.insertAsComment": true,
    "output.language": "python"
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
    """调用 ocrtool-mcp 识别图片"""
    json_rpc = json.dumps({
        "jsonrpc": "2.0",
        "id": "1",
        "method": "ocr_text",
        "params": {
            "image": image_path,
            "format": "structured",
            "lang": "zh+en"
        }
    })

    cmd = f"echo '{json_rpc}' | {ocr_tool_path}"
    proc = subprocess.Popen(cmd, shell=True,
                          stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE)
    out, err = proc.communicate()

    result = json.loads(out.decode())
    return result.get("result", {}).get("lines", [])

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