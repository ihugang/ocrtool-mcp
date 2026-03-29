import AppKit
import Foundation
import Vision

public struct BoundingBox: Codable, Equatable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double
}

public struct OCRLine: Codable, Equatable {
    public let text: String
    public let bbox: BoundingBox
}

public struct OCRResult: Codable, Equatable {
    public let lines: [OCRLine]

    public var plainText: String {
        lines.map(\.text).joined(separator: "\n")
    }

    public var markdownTable: String {
        guard !lines.isEmpty else { return "No text found." }

        let header = "| Text | X (px) | Y (px, from bottom) | Width (px) | Height (px) |"
        let separator = "|------|--------|----------------------|------------|-------------|"
        let rows = lines.map { line in
            let box = line.bbox
            return "| \(line.text.replacingOccurrences(of: "|", with: "\\|")) | \(Int(box.x)) | \(Int(box.y)) | \(Int(box.width)) | \(Int(box.height)) |"
        }

        let note = "\n> Bounding box origin is at the **bottom-left** of the image; Y increases upward."
        return ([header, separator] + rows).joined(separator: "\n") + note
    }

    public func commented(language: String) -> String {
        let normalized = language.lowercased()

        switch normalized {
        case "python", "shell", "bash":
            return plainText
                .split(separator: "\n", omittingEmptySubsequences: false)
                .map { "# " + $0 }
                .joined(separator: "\n")
        case "html", "xml":
            return "<!--\n\(plainText)\n-->"
        default:
            return plainText
                .split(separator: "\n", omittingEmptySubsequences: false)
                .map { "// " + $0 }
                .joined(separator: "\n")
        }
    }

    public func rendered(format: OCRFormat, commentStyle: CommentStyle?) -> String {
        if let commentStyle {
            return commented(language: commentStyle.language)
        }

        switch format {
        case .text:
            return plainText
        case .markdown:
            return markdownTable
        case .structured:
            let payload: [String: Any] = [
                "lines": lines.map {
                    [
                        "text": $0.text,
                        "bbox": [
                            "x": $0.bbox.x,
                            "y": $0.bbox.y,
                            "width": $0.bbox.width,
                            "height": $0.bbox.height
                        ]
                    ]
                }
            ]

            guard
                let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
                let string = String(data: data, encoding: .utf8)
            else {
                return #"{"lines":[]}"#
            }

            return string
        case .auto:
            return lines.count <= 1 ? plainText : markdownTable
        }
    }
}

public enum OCRFormat: String {
    case text
    case markdown
    case structured
    case auto

    init?(rawInput: String?) {
        guard let rawInput else {
            self = .auto
            return
        }

        switch rawInput.lowercased() {
        case "text", "simple":
            self = .text
        case "table", "markdown":
            self = .markdown
        case "full", "structured":
            self = .structured
        case "auto":
            self = .auto
        default:
            return nil
        }
    }
}

public struct CommentStyle: Equatable {
    public let language: String
}

public struct OCRToolArguments {
    public let imagePath: String?
    public let url: String?
    public let base64: String?
    public let languageCodes: [String]
    public let recognitionLevel: VNRequestTextRecognitionLevel
    public let format: OCRFormat
    public let commentStyle: CommentStyle?
}

enum OCRExecutionError: Error {
    case invalidArguments(String)
    case downloadFailed(String)
    case decodeFailed(String)
    case fileNotFound(String)
    case unreadableImage(String)
    case visionFailed(String)

    var message: String {
        switch self {
        case .invalidArguments(let message),
             .downloadFailed(let message),
             .decodeFailed(let message),
             .fileNotFound(let message),
             .unreadableImage(let message),
             .visionFailed(let message):
            return message
        }
    }
}

public struct OCRToolMCPServer {
    public static let serverName = "ocrtool-mcp"
    public static let serverVersion = "1.0.6"
    public static let protocolVersion = "2024-11-05"
    public static let toolName = "ocr_extract_text"

    // Vision Framework supported recognition languages (macOS 12+)
    static let supportedVisionLanguages: Set<String> = [
        "zh-Hans", "zh-Hant", "en-US",
        "fr-FR", "it-IT", "de-DE", "es-ES", "pt-BR",
        "ar-SA", "ru-RU", "ko-KR", "ja-JP",
        "uk-UA", "th-TH", "vi-VN"
    ]

    private var initializeCompleted = false
    private var initializedNotificationReceived = false

    public init() {}

    public mutating func handleLine(_ line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        guard let data = trimmed.data(using: .utf8) else {
            return makeErrorResponse(id: nil, code: -32700, message: "Invalid UTF-8 input.")
        }

        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            return makeErrorResponse(id: nil, code: -32700, message: "Parse error.", data: ["details": error.localizedDescription])
        }

        guard let message = object as? [String: Any] else {
            return makeErrorResponse(id: nil, code: -32600, message: "Invalid request.")
        }

        guard (message["jsonrpc"] as? String) == "2.0" else {
            return makeErrorResponse(id: message["id"], code: -32600, message: "Invalid request: jsonrpc must be '2.0'.")
        }

        let id = message["id"]
        let method = message["method"] as? String
        let params = message["params"] as? [String: Any] ?? [:]

        if let method {
            return handleRequestOrNotification(method: method, id: id, params: params)
        }

        return makeErrorResponse(id: id, code: -32600, message: "Invalid request: method is required.")
    }

    private mutating func handleRequestOrNotification(method: String, id: Any?, params: [String: Any]) -> String? {
        switch method {
        case "initialize":
            guard let id else {
                return nil
            }

            initializeCompleted = true
            let result: [String: Any] = [
                "protocolVersion": Self.protocolVersion,
                "capabilities": [
                    "tools": [
                        "listChanged": false
                    ]
                ],
                "serverInfo": [
                    "name": Self.serverName,
                    "version": Self.serverVersion
                ]
            ]
            return makeResultResponse(id: id, result: result)
        case "notifications/initialized":
            initializedNotificationReceived = true
            return nil
        case "tools/list":
            guard let id else { return nil }
            guard ensureOperational(id: id) else { return currentOperationalErrorResponse(for: id) }
            return makeResultResponse(id: id, result: ["tools": [toolDefinition()]])
        case "tools/call":
            guard let id else { return nil }
            guard ensureOperational(id: id) else { return currentOperationalErrorResponse(for: id) }
            return handleToolCall(id: id, params: params)
        case "ping":
            guard let id else { return nil }
            return makeResultResponse(id: id, result: [:] as [String: Any])
        case "shutdown":
            guard let id else { return nil }
            return makeResultResponse(id: id, result: NSNull())
        case "notifications/cancelled":
            return nil
        default:
            if let id {
                return makeErrorResponse(id: id, code: -32601, message: "Method not found: \(method)")
            }
            return nil
        }
    }

    private func ensureOperational(id: Any) -> Bool {
        initializeCompleted && initializedNotificationReceived
    }

    private func currentOperationalErrorResponse(for id: Any) -> String {
        if !initializeCompleted {
            return makeErrorResponse(id: id, code: -32002, message: "Server not initialized. Call 'initialize' first.")
        }

        return makeErrorResponse(id: id, code: -32002, message: "Server not ready. Wait for initialize to complete and send 'notifications/initialized'.")
    }

    private func handleToolCall(id: Any, params: [String: Any]) -> String {
        guard let name = params["name"] as? String else {
            return makeErrorResponse(id: id, code: -32602, message: "Invalid params: tool name is required.")
        }

        guard name == Self.toolName else {
            return makeErrorResponse(id: id, code: -32602, message: "Unknown tool: \(name)")
        }

        let arguments = params["arguments"] as? [String: Any] ?? [:]

        do {
            let request = try parseOCRArguments(arguments)
            let result = try runOCR(request)
            let text = result.rendered(format: request.format, commentStyle: request.commentStyle)

            return makeResultResponse(id: id, result: [
                "content": [
                    [
                        "type": "text",
                        "text": text
                    ]
                ],
                "isError": false
            ])
        } catch let error as OCRExecutionError {
            return makeResultResponse(id: id, result: [
                "content": [
                    [
                        "type": "text",
                        "text": error.message
                    ]
                ],
                "isError": true
            ])
        } catch {
            return makeErrorResponse(id: id, code: -32603, message: "Internal server error.", data: ["details": error.localizedDescription])
        }
    }

    private func parseOCRArguments(_ arguments: [String: Any]) throws -> OCRToolArguments {
        let imagePath = firstString(arguments["image_path"], arguments["image"])
        let url = stringValue(arguments["url"])
        let base64 = stringValue(arguments["base64"])

        let providedInputs = [imagePath, url, base64].reduce(into: [String]()) { partialResult, value in
            if let value, !value.isEmpty {
                partialResult.append(value)
            }
        }

        guard providedInputs.count == 1 else {
            throw OCRExecutionError.invalidArguments("Exactly one of 'image_path' (or 'image'), 'url', or 'base64' must be provided.")
        }

        guard let format = OCRFormat(rawInput: stringValue(arguments["format"])) else {
            throw OCRExecutionError.invalidArguments("Invalid 'format'. Allowed values: text, markdown, structured, auto.")
        }

        let output = arguments["output"] as? [String: Any] ?? [:]
        let insertAsComment = boolValue(output["insertAsComment"]) ?? boolValue(arguments["output.insertAsComment"]) ?? false
        let commentLanguage = stringValue(output["language"]) ?? stringValue(arguments["output.language"]) ?? "swift"
        let commentStyle = insertAsComment ? CommentStyle(language: commentLanguage) : nil

        let rawLangTokens = (stringValue(arguments["lang"]) ?? "zh+en")
            .split(separator: "+")
            .map { String($0) }

        let langTokens = try rawLangTokens.map { token -> String in
            let normalized = normalizeVisionLanguage(token)
            guard Self.supportedVisionLanguages.contains(normalized) else {
                throw OCRExecutionError.invalidArguments(
                    "Unsupported language code '\(token)'. Supported values: \(Self.supportedVisionLanguages.sorted().joined(separator: ", "))."
                )
            }
            return normalized
        }

        let enhanced = boolValue(arguments["enhanced"]) ?? true

        return OCRToolArguments(
            imagePath: normalizeLocalPath(imagePath),
            url: url,
            base64: base64,
            languageCodes: langTokens.isEmpty ? ["zh-Hans", "en-US"] : langTokens,
            recognitionLevel: enhanced ? .accurate : .fast,
            format: format,
            commentStyle: commentStyle
        )
    }

    private static let maxDownloadBytes = 50 * 1024 * 1024  // 50 MB
    private static let downloadTimeout: TimeInterval = 30

    private func downloadImage(from remoteURL: URL) throws -> Data {
        // file:// URLs are handled synchronously without network
        if remoteURL.isFileURL {
            do {
                return try Data(contentsOf: remoteURL)
            } catch {
                throw OCRExecutionError.downloadFailed("Failed to read file URL: \(error.localizedDescription)")
            }
        }

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Self.downloadTimeout
        config.timeoutIntervalForResource = Self.downloadTimeout
        let session = URLSession(configuration: config)

        var downloadedData: Data?
        var downloadError: Error?

        let semaphore = DispatchSemaphore(value: 0)
        let task = session.dataTask(with: remoteURL) { data, response, error in
            defer { semaphore.signal() }
            if let error {
                downloadError = error
                return
            }
            guard let data else {
                downloadError = NSError(domain: "OCRToolMCP", code: 1, userInfo: [NSLocalizedDescriptionKey: "Empty response body."])
                return
            }
            if data.count > Self.maxDownloadBytes {
                downloadError = NSError(domain: "OCRToolMCP", code: 2, userInfo: [NSLocalizedDescriptionKey: "Image exceeds maximum allowed size of \(Self.maxDownloadBytes / 1024 / 1024) MB."])
                return
            }
            downloadedData = data
        }
        task.resume()
        semaphore.wait()

        if let downloadError {
            throw OCRExecutionError.downloadFailed("Failed to download image from URL: \(downloadError.localizedDescription)")
        }
        guard let data = downloadedData else {
            throw OCRExecutionError.downloadFailed("Failed to download image from URL: no data received.")
        }
        return data
    }

    private func runOCR(_ request: OCRToolArguments) throws -> OCRResult {
        let localImageURL: URL
        var temporaryURL: URL?

        if let urlString = request.url {
            guard let remoteURL = URL(string: urlString) else {
                throw OCRExecutionError.invalidArguments("Invalid 'url'.")
            }

            let data = try downloadImage(from: remoteURL)
            do {
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".img")
                try data.write(to: tempURL, options: .atomic)
                temporaryURL = tempURL
                localImageURL = tempURL
            } catch {
                throw OCRExecutionError.downloadFailed("Failed to persist downloaded image: \(error.localizedDescription)")
            }
        } else if let base64 = request.base64 {
            guard let data = Data(base64Encoded: base64) else {
                throw OCRExecutionError.decodeFailed("Invalid base64 image data.")
            }

            do {
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".img")
                try data.write(to: tempURL, options: .atomic)
                temporaryURL = tempURL
                localImageURL = tempURL
            } catch {
                throw OCRExecutionError.decodeFailed("Failed to persist decoded image data: \(error.localizedDescription)")
            }
        } else if let imagePath = request.imagePath {
            localImageURL = URL(fileURLWithPath: imagePath)
        } else {
            throw OCRExecutionError.invalidArguments("No image input provided.")
        }

        defer {
            if let temporaryURL {
                try? FileManager.default.removeItem(at: temporaryURL)
            }
        }

        let path = localImageURL.path
        guard FileManager.default.fileExists(atPath: path) else {
            throw OCRExecutionError.fileNotFound("Image file not found at path: \(path)")
        }

        guard
            let image = NSImage(contentsOf: localImageURL),
            let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else {
            throw OCRExecutionError.unreadableImage("Unsupported or unreadable image at path: \(path)")
        }

        let size = CGSize(width: cgImage.width, height: cgImage.height)
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        var lines: [OCRLine] = []

        let requestHandler = VNRecognizeTextRequest { request, error in
            guard error == nil else { return }
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }

            lines = observations.compactMap { observation in
                guard let candidate = observation.topCandidates(1).first else { return nil }
                let rect = VNImageRectForNormalizedRect(observation.boundingBox, Int(size.width), Int(size.height))
                return OCRLine(
                    text: candidate.string,
                    bbox: BoundingBox(
                        x: Double(rect.origin.x),
                        y: Double(rect.origin.y),
                        width: Double(rect.width),
                        height: Double(rect.height)
                    )
                )
            }
        }

        requestHandler.recognitionLevel = request.recognitionLevel
        requestHandler.usesLanguageCorrection = true
        requestHandler.recognitionLanguages = request.languageCodes

        do {
            try handler.perform([requestHandler])
        } catch {
            throw OCRExecutionError.visionFailed("Vision OCR failed: \(error.localizedDescription)")
        }

        return OCRResult(lines: lines)
    }

    private func toolDefinition() -> [String: Any] {
        [
            "name": Self.toolName,
            "description": "Extract text from an image on macOS using the Vision framework. Accepts a local image path, URL, or base64 image data.",
            "inputSchema": [
                "type": "object",
                "properties": [
                    "image_path": [
                        "type": "string",
                        "description": "Absolute or relative path to a local image file. Alias: image."
                    ],
                    "image": [
                        "type": "string",
                        "description": "Alias of image_path."
                    ],
                    "url": [
                        "type": "string",
                        "description": "Remote image URL to download before OCR."
                    ],
                    "base64": [
                        "type": "string",
                        "description": "Base64-encoded image bytes."
                    ],
                    "lang": [
                        "type": "string",
                        "description": "OCR languages separated by '+'. Aliases: zh=zh-Hans, zh-tw=zh-Hant, en=en-US. Supported: zh-Hans, zh-Hant, en-US, fr-FR, it-IT, de-DE, es-ES, pt-BR, ar-SA, ru-RU, ko-KR, ja-JP, uk-UA, th-TH, vi-VN. Default: zh+en."
                    ],
                    "enhanced": [
                        "type": "boolean",
                        "description": "Use accurate OCR when true, or faster OCR when false."
                    ],
                    "format": [
                        "type": "string",
                        "enum": ["text", "markdown", "structured", "auto"],
                        "description": "How the OCR result should be rendered. 'text': plain lines. 'markdown': table with bounding boxes (origin bottom-left, Y increases upward). 'structured': JSON with full bbox data. 'auto': text for single line, markdown table for multiple lines."
                    ],
                    "output": [
                        "type": "object",
                        "description": "Optional formatting controls for comment output.",
                        "properties": [
                            "insertAsComment": [
                                "type": "boolean",
                                "description": "Render the OCR text as code comments."
                            ],
                            "language": [
                                "type": "string",
                                "description": "Comment style language, for example python, swift, or html."
                            ]
                        ]
                    ]
                ],
                "anyOf": [
                    ["required": ["image_path"]],
                    ["required": ["image"]],
                    ["required": ["url"]],
                    ["required": ["base64"]]
                ]
            ]
        ]
    }

    private func makeResultResponse(id: Any, result: Any) -> String {
        makeMessage([
            "jsonrpc": "2.0",
            "id": id,
            "result": result
        ])
    }

    private func makeErrorResponse(id: Any?, code: Int, message: String, data: Any? = nil) -> String {
        var errorObject: [String: Any] = [
            "code": code,
            "message": message
        ]

        if let data {
            errorObject["data"] = data
        }

        var payload: [String: Any] = [
            "jsonrpc": "2.0",
            "error": errorObject
        ]
        payload["id"] = id ?? NSNull()
        return makeMessage(payload)
    }

    private func makeMessage(_ object: [String: Any]) -> String {
        guard
            JSONSerialization.isValidJSONObject(object),
            let data = try? JSONSerialization.data(withJSONObject: object, options: []),
            let string = String(data: data, encoding: .utf8)
        else {
            return #"{"jsonrpc":"2.0","id":null,"error":{"code":-32603,"message":"Internal server error."}}"#
        }

        return string
    }
}

private func stringValue(_ value: Any?) -> String? {
    value as? String
}

private func boolValue(_ value: Any?) -> Bool? {
    value as? Bool
}

private func firstString(_ values: Any?...) -> String? {
    for value in values {
        if let string = value as? String, !string.isEmpty {
            return string
        }
    }
    return nil
}

private func normalizeLocalPath(_ path: String?) -> String? {
    guard let path, !path.isEmpty else { return nil }

    let expanded = (path as NSString).expandingTildeInPath
    if expanded.hasPrefix("/") {
        return expanded
    }

    return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent(expanded)
        .path
}

private func normalizeVisionLanguage(_ token: String) -> String {
    switch token.lowercased() {
    case "zh", "zh-cn", "zh-hans":
        return "zh-Hans"
    case "zh-tw", "zh-hk", "zh-hant":
        return "zh-Hant"
    case "en", "en-us":
        return "en-US"
    case "fr", "fr-fr":
        return "fr-FR"
    case "it", "it-it":
        return "it-IT"
    case "de", "de-de":
        return "de-DE"
    case "es", "es-es":
        return "es-ES"
    case "pt", "pt-br":
        return "pt-BR"
    case "ar", "ar-sa":
        return "ar-SA"
    case "ru", "ru-ru":
        return "ru-RU"
    case "ko", "ko-kr":
        return "ko-KR"
    case "ja", "ja-jp":
        return "ja-JP"
    case "uk", "uk-ua":
        return "uk-UA"
    case "th", "th-th":
        return "th-TH"
    case "vi", "vi-vn":
        return "vi-VN"
    default:
        return token
    }
}
