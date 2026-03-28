// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ocrtool-mcp",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(name: "OCRToolMCPCore", targets: ["OCRToolMCPCore"]),
        .executable(name: "ocrtool-mcp", targets: ["OCRToolMCP"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "OCRToolMCPCore",
            path: "Sources/OCRToolMCPCore"
        ),
        .executableTarget(
            name: "OCRToolMCP",
            dependencies: ["OCRToolMCPCore"],
            path: "Sources/OCRToolMCP"
        ),
        .testTarget(
            name: "OCRToolMCPCoreTests",
            dependencies: ["OCRToolMCPCore"],
            path: "Tests/OCRToolMCPCoreTests"
        )
    ]
)
