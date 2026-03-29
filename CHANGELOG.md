# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.4] - 2026-03-29

### Added
- `ping` method support for MCP clients that send periodic health checks
- Language code validation: unsupported codes now return a clear error with the list of supported values
- Short language aliases for all supported languages (`ja`, `ko`, `fr`, `de`, `it`, `es`, `pt`, `ar`, `ru`, `th`, `vi`, `uk`)

### Changed
- Default `format` changed from `structured` to `auto` (single line → plain text, multiple lines → markdown table)
- URL download replaced with `URLSession`-based async download (30s timeout, 50 MB size limit); `file://` URLs handled locally without network overhead
- Markdown table column headers now clarify bounding box coordinate system (`Y (px, from bottom)`)
- `format` and `lang` tool descriptions updated with full details on supported values and coordinate system

### Fixed
- CI and release workflows pin Xcode to `"16"` instead of `"16.4"` to avoid unavailable version errors on GitHub Actions

## [1.0.3] - 2026-03-29

### Added
- Standard MCP lifecycle support for `initialize`, `notifications/initialized`, `tools/list`, and `tools/call`
- Public core target for easier testing and future protocol extensions
- Automated tests covering MCP initialization, tool discovery, and tool error handling
- OCR integration tests covering local path, file URL, HTTP URL, and base64 inputs

### Changed
- Replaced the custom `ocr_text` request flow with the MCP tool `ocr_extract_text`
- Updated documentation to reflect the actual MCP handshake and tool call flow
- Mapped `enhanced` to Vision recognition level selection (`accurate` vs `fast`)
- Unified release packaging around `scripts/build-release.sh` and `scripts/update-formula.sh`
- Aligned CI and release workflows with the same packaging flow and release artifact names

### Fixed
- Removed stdout banner output that could corrupt MCP stdio responses
- Fixed nested `output` argument parsing for comment rendering options
- Unified runtime version metadata with the released package version
- Return explicit tool errors instead of silently returning empty OCR results for invalid inputs
- Prepared the release workflow to sync the Homebrew formula back to the default branch after publishing

## [1.0.0] - 2025-10-29

### Added
- Initial release of ocrtool-mcp
- macOS native OCR using Vision Framework
- MCP (Model Context Protocol) JSON-RPC interface
- Support for Chinese and English text recognition
- Multiple image input methods (local path, URL, Base64)
- Flexible output formats (text, markdown table, JSON, code comments)
- Universal binary support (Intel + Apple Silicon)
- Homebrew installation support
- Comprehensive documentation for multiple AI IDE tools:
  - Claude Desktop (Claude Code)
  - Cursor
  - Continue
  - Windsurf
  - Cline (VSCode Extension)
  - Cherry Studio

### Documentation
- English README with installation and configuration guides
- Chinese README (简体中文文档)
- Python integration example
- Troubleshooting guide
- Parameter reference table

## [Unreleased]

[1.0.3]: https://github.com/ihugang/ocrtool-mcp/releases/tag/v1.0.3
[1.0.0]: https://github.com/ihugang/ocrtool-mcp/releases/tag/v1.0.0
