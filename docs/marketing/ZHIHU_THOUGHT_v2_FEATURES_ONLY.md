# 知乎想法版：只介绍功能

最近整理了一个自己在用的 OCR 项目：`ocrtool-mcp`。

它是一个运行在 macOS 上的本地 OCR 工具，主要给 AI Agent 用，可以直接从图片里提取文字。

目前支持这些功能：

- 识别截图、扫描件、收据、照片里的文字
- 支持本地图片路径、图片 URL、base64 图片输入
- 支持中英文识别
- 输出可以是：
  - 纯文本
  - Markdown 表格
  - 结构化 JSON
  - 代码注释格式
- 基于 macOS 原生 Vision Framework
- 本地运行，不走云端 OCR
- 支持 Intel 和 Apple Silicon

使用方式也比较直接：

- 如果你的 Agent 支持 MCP，就把它作为 MCP server 接进去
- 如果你的 Agent 支持 skills，也可以直接安装内置的 `ocr-workflow` skill

适合的场景比如：

- 让 Agent 读取截图里的文字
- 识别票据、表格、文档照片
- 把图片文字转成 markdown 或结构化数据
- 从代码截图里提取内容，再继续处理

项目地址：
https://github.com/ihugang/ocrtool-mcp

当前版本：
https://github.com/ihugang/ocrtool-mcp/releases/tag/v1.0.6
