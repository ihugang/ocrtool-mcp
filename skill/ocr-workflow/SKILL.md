---
name: ocr-workflow
description: Use when the user wants OCR on images, screenshots, scans, receipts, diagrams, or image files; extract text from a local image path, image URL, or base64 image; convert OCR output to plain text, markdown table, structured JSON, or code comments; or rename, summarize, or post-process files based on recognized text. Prefer this skill for image-to-text workflows backed by the local ocrtool-mcp binary.
---

# OCR Workflow

Use this skill for OCR tasks powered by the local `ocrtool-mcp` binary.

## What this skill is for

- Extract text from images, screenshots, scanned documents, receipts, whiteboards, and diagrams
- Accept local file paths, remote URLs, or base64 image data
- Return OCR output as plain text, markdown table, structured JSON, or code comments
- Feed OCR output into follow-up work such as renaming files, summarization, or markdown conversion

## Execution path

Prefer the bundled script:

```bash
python3 skill/ocr-workflow/scripts/run_ocr.py --image-path "/path/to/image.png"
```

The script handles the MCP lifecycle against the local `ocrtool-mcp` binary and prints the OCR result.

## Binary resolution

The bundled script looks for `ocrtool-mcp` in this order:

1. `--binary` argument
2. `OCRTOOL_MCP_BIN` environment variable
3. repo-local `./ocrtool-mcp`
4. repo-local `./.build/release/ocrtool-mcp`
5. `ocrtool-mcp` from `PATH`

If the binary is not available, tell the user to build or install it first.

## Common commands

Local image to plain text:

```bash
python3 skill/ocr-workflow/scripts/run_ocr.py \
  --image-path "/path/to/image.png" \
  --format text
```

Image URL to markdown table:

```bash
python3 skill/ocr-workflow/scripts/run_ocr.py \
  --url "https://example.com/receipt.png" \
  --format markdown
```

OCR as structured JSON:

```bash
python3 skill/ocr-workflow/scripts/run_ocr.py \
  --image-path "/path/to/image.png" \
  --format structured \
  --json
```

OCR as code comments:

```bash
python3 skill/ocr-workflow/scripts/run_ocr.py \
  --image-path "/path/to/image.png" \
  --format text \
  --insert-as-comment \
  --comment-language python
```

## Parameters

- `--image-path <path>`: local image path
- `--url <url>`: remote image URL
- `--base64-file <path>`: read base64 payload from a file
- `--lang <codes>`: OCR languages such as `zh+en`
- `--format <text|markdown|structured|auto>`: output format
- `--insert-as-comment`: return comment-formatted output
- `--comment-language <lang>`: comment style language when comment mode is enabled
- `--json`: print raw MCP result envelope instead of only OCR text

Exactly one of `--image-path`, `--url`, or `--base64-file` must be provided.

## Working style

- For straightforward OCR requests, run the script directly instead of manually constructing JSON-RPC.
- If the user asks for post-processing, perform OCR first, then transform the result.
- When OCR fails, surface the tool error clearly and include the failing input mode.
- If the request is batch-oriented, loop over files outside the binary rather than modifying the MCP server protocol.

## Notes

- This skill is macOS-oriented because `ocrtool-mcp` uses Vision/AppKit.
- The binary is the source of OCR truth. Do not reimplement OCR logic in the skill.
