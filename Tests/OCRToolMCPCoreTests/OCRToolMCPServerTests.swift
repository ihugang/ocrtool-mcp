import AppKit
import Foundation
import XCTest
@testable import OCRToolMCPCore

final class OCRToolMCPServerTests: XCTestCase {
    func testInitializeReturnsServerCapabilities() throws {
        var server = OCRToolMCPServer()

        let responseText = try XCTUnwrap(
            server.handleLine(#"{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.4"}}}"#)
        )
        let response = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(responseText.utf8)) as? [String: Any]
        )
        let result = try XCTUnwrap(response["result"] as? [String: Any])
        let serverInfo = try XCTUnwrap(result["serverInfo"] as? [String: Any])
        let capabilities = try XCTUnwrap(result["capabilities"] as? [String: Any])
        let tools = try XCTUnwrap(capabilities["tools"] as? [String: Any])

        XCTAssertEqual(result["protocolVersion"] as? String, "2024-11-05")
        XCTAssertEqual(serverInfo["name"] as? String, "ocrtool-mcp")
        XCTAssertEqual(serverInfo["version"] as? String, OCRToolMCPServer.serverVersion)
        XCTAssertEqual(tools["listChanged"] as? Bool, false)
    }

    func testToolsListRequiresInitializedNotification() throws {
        var server = OCRToolMCPServer()
        _ = server.handleLine(#"{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.4"}}}"#)

        let response = try XCTUnwrap(
            server.handleLine(#"{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}"#)
        )

        XCTAssertTrue(response.contains("Server not ready"))
    }

    func testToolsListReturnsOCRToolAfterInitialization() throws {
        var server = OCRToolMCPServer()
        _ = server.handleLine(#"{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.4"}}}"#)
        _ = server.handleLine(#"{"jsonrpc":"2.0","method":"notifications/initialized"}"#)

        let response = try XCTUnwrap(
            server.handleLine(#"{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}"#)
        )

        XCTAssertTrue(response.contains(#""name":"ocr_extract_text""#))
        XCTAssertTrue(response.contains(#""inputSchema""#))
    }

    func testToolCallReturnsToolErrorForMissingImageInput() throws {
        var server = OCRToolMCPServer()
        _ = server.handleLine(#"{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.4"}}}"#)
        _ = server.handleLine(#"{"jsonrpc":"2.0","method":"notifications/initialized"}"#)

        let response = try XCTUnwrap(
            server.handleLine(#"{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"ocr_extract_text","arguments":{"format":"text","output":{"insertAsComment":true,"language":"python"}}}}"#)
        )

        XCTAssertTrue(response.contains(#""isError":true"#))
        XCTAssertTrue(response.contains("Exactly one of"))
    }

    func testToolCallRecognizesLocalImagePath() throws {
        let imageURL = try makeTestImage(text: "HELLO")
        defer { try? FileManager.default.removeItem(at: imageURL) }

        let response = try callTool(arguments: [
            "image_path": imageURL.path,
            "format": "text",
            "lang": "en"
        ])

        let toolText = try extractToolText(response)
        XCTAssertTrue(normalized(toolText).contains("HELLO"), "Unexpected OCR output: \(toolText)")
    }

    func testToolCallRecognizesFileURLInput() throws {
        let imageURL = try makeTestImage(text: "HELLO")
        defer { try? FileManager.default.removeItem(at: imageURL) }

        let response = try callTool(arguments: [
            "url": imageURL.absoluteString,
            "format": "text",
            "lang": "en"
        ])

        let toolText = try extractToolText(response)
        XCTAssertTrue(normalized(toolText).contains("HELLO"), "Unexpected OCR output: \(toolText)")
    }

    func testToolCallRecognizesHTTPURLInput() throws {
        let imageURL = try makeTestImage(text: "HELLO")
        defer { try? FileManager.default.removeItem(at: imageURL) }

        let server = try LocalHTTPServer(rootDirectory: imageURL.deletingLastPathComponent())
        defer { server.stop() }

        let response = try callTool(arguments: [
            "url": server.url(for: imageURL.lastPathComponent).absoluteString,
            "format": "text",
            "lang": "en"
        ])

        let toolText = try extractToolText(response)
        XCTAssertTrue(normalized(toolText).contains("HELLO"), "Unexpected OCR output: \(toolText)")
    }

    func testToolCallRecognizesBase64ImageInput() throws {
        let imageURL = try makeTestImage(text: "HELLO")
        defer { try? FileManager.default.removeItem(at: imageURL) }

        let imageData = try Data(contentsOf: imageURL)
        let response = try callTool(arguments: [
            "base64": imageData.base64EncodedString(),
            "format": "structured",
            "lang": "en"
        ])

        let toolText = try extractToolText(response)
        let structuredPayload = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: Data(toolText.utf8)) as? [String: Any]
        )
        let lines = try XCTUnwrap(structuredPayload["lines"] as? [[String: Any]])
        let recognizedText = lines
            .compactMap { $0["text"] as? String }
            .joined(separator: " ")

        XCTAssertFalse(lines.isEmpty)
        XCTAssertTrue(normalized(recognizedText).contains("HELLO"), "Unexpected OCR output: \(recognizedText)")
    }

    private func callTool(arguments: [String: Any]) throws -> [String: Any] {
        var server = makeInitializedServer()
        let line = try jsonString([
            "jsonrpc": "2.0",
            "id": 2,
            "method": "tools/call",
            "params": [
                "name": "ocr_extract_text",
                "arguments": arguments
            ]
        ])

        let responseText = try XCTUnwrap(server.handleLine(line))
        return try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(responseText.utf8)) as? [String: Any]
        )
    }

    private func makeInitializedServer() -> OCRToolMCPServer {
        var server = OCRToolMCPServer()
        _ = server.handleLine(#"{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.4"}}}"#)
        _ = server.handleLine(#"{"jsonrpc":"2.0","method":"notifications/initialized"}"#)
        return server
    }

    private func extractToolText(_ response: [String: Any]) throws -> String {
        let result = try XCTUnwrap(response["result"] as? [String: Any])
        XCTAssertEqual(result["isError"] as? Bool, false)
        let content = try XCTUnwrap(result["content"] as? [[String: Any]])
        return try XCTUnwrap(content.first?["text"] as? String)
    }

    private func makeTestImage(text: String) throws -> URL {
        let size = NSSize(width: 720, height: 240)
        let image = NSImage(size: size)
        image.lockFocus()

        NSColor.white.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 120, weight: .bold),
            .foregroundColor: NSColor.black,
            .paragraphStyle: paragraphStyle
        ]

        let textRect = NSRect(x: 40, y: 60, width: size.width - 80, height: 140)
        (text as NSString).draw(in: textRect, withAttributes: attributes)
        image.unlockFocus()

        guard
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData),
            let pngData = bitmap.representation(using: .png, properties: [:])
        else {
            XCTFail("Failed to generate PNG test image.")
            throw NSError(domain: "OCRToolMCPServerTests", code: 1)
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("png")
        try pngData.write(to: url)
        return url
    }

    private func normalized(_ text: String) -> String {
        text.uppercased().replacingOccurrences(of: " ", with: "")
    }

    private func jsonString(_ object: [String: Any]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: object, options: [])
        return try XCTUnwrap(String(data: data, encoding: .utf8))
    }
}

private final class LocalHTTPServer {
    private let process: Process
    private let port: Int

    init(rootDirectory: URL) throws {
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        let script = """
import functools
import http.server
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(root))
server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
print(server.server_address[1], flush=True)
server.serve_forever()
"""

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = ["-c", script, rootDirectory.path]
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        try process.run()

        self.process = process
        self.port = try LocalHTTPServer.readPort(from: stdoutPipe.fileHandleForReading)
    }

    func url(for pathComponent: String) -> URL {
        URL(string: "http://127.0.0.1:\(port)/\(pathComponent)")!
    }

    func stop() {
        guard process.isRunning else { return }
        process.terminate()
        process.waitUntilExit()
    }

    private static func readPort(from fileHandle: FileHandle) throws -> Int {
        var data = Data()
        let deadline = Date().addingTimeInterval(5)

        while Date() < deadline {
            if let chunk = try fileHandle.read(upToCount: 1), !chunk.isEmpty {
                if chunk == Data([0x0A]) {
                    break
                }
                data.append(chunk)
            } else {
                usleep(50_000)
            }
        }

        guard
            let string = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
            let port = Int(string)
        else {
            throw NSError(domain: "LocalHTTPServer", code: 1)
        }

        return port
    }
}
