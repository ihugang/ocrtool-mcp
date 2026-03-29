# 知乎想法版

最近把自己做的一个 macOS OCR 小工具整理成了正式项目：`ocrtool-mcp`。

它最早只是一个 MCP server，用 Swift + Vision Framework 做本地 OCR，让 Agent 可以直接读取截图、收据、扫描件里的文字。

但做着做着我发现一个很现实的问题：

**如果一个项目只考虑 MCP，工程上可能是对的，但对普通用户不一定友好。**

因为普通用户真正会问的不是：

- 这是不是标准 MCP？

而是：

- 我到底该装 skill，还是接 MCP？
- 我这个 agent 支不支持 skills？
- 我能不能装完就直接说“帮我识别这张图”？

所以我后来把这个项目改成了双入口：

1. **MCP 模式**
   适合 Claude Desktop、Cursor、Continue、Windsurf、Cline、Cherry Studio 这类支持 MCP 的工具

2. **Skill 模式**
   适合支持 skills 的 Agent，让用户更像“安装一个能力”，而不是“配置一个协议”

这次最大的感受其实不是 OCR 本身，而是一个更普遍的判断：

> Agent 时代，一个能力“能被调用”不够，它还得“能被普通用户理解和安装”。

MCP 更像底层能力接口。

Skill 更像用户入口。

如果只做前者，开发者会觉得很标准；如果把后者也补上，普通用户才更容易真的用起来。

这也是我现在越来越认同的一件事：

**很多 Agent 工具，最终都应该走向 Skill + MCP 双层结构。**

项目地址：
https://github.com/ihugang/ocrtool-mcp

当前版本：
https://github.com/ihugang/ocrtool-mcp/releases/tag/v1.0.6
