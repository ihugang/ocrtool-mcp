import Foundation
import OCRToolMCPCore

private func showHelpAndExit() -> Never {
    let helpText = """
    OCRToolMCP Help

    Transport:
      stdio with newline-delimited JSON-RPC 2.0 / MCP messages

    Lifecycle:
      1. initialize
      2. notifications/initialized
      3. tools/list
      4. tools/call

    Tool:
      ocr_extract_text

    Example initialize request:
    {"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"example-client","version":"1.0.3"}}}

    Example tool call:
    {"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"ocr_extract_text","arguments":{"image_path":"./test.jpg","lang":"zh+en","format":"markdown"}}}
    """
    print(helpText)
    exit(0)
}

if CommandLine.arguments.contains("--help") {
    showHelpAndExit()
}

var server = OCRToolMCPServer()

while let line = readLine(strippingNewline: true) {
    if let response = server.handleLine(line) {
        fputs(response + "\n", stdout)
        fflush(stdout)
    }
}
