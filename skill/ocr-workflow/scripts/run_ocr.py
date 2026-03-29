#!/usr/bin/env python3

import argparse
import base64
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path
from typing import List, Optional


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run OCR through the local ocrtool-mcp binary."
    )
    parser.add_argument("--binary", help="Path to the ocrtool-mcp binary")
    parser.add_argument("--image-path", help="Local image path")
    parser.add_argument("--url", help="Remote image URL")
    parser.add_argument("--base64-file", help="Path to a file containing base64 image data")
    parser.add_argument("--lang", default="zh+en", help="OCR languages, e.g. zh+en")
    parser.add_argument(
        "--format",
        default="auto",
        choices=["text", "markdown", "structured", "auto"],
        help="OCR output format",
    )
    parser.add_argument(
        "--insert-as-comment",
        action="store_true",
        help="Return OCR output formatted as source comments",
    )
    parser.add_argument(
        "--comment-language",
        default="swift",
        help="Comment style language used with --insert-as-comment",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Print the raw MCP result envelope",
    )
    return parser.parse_args()


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def repo_root() -> Path:
    return Path(__file__).resolve().parents[3]


def resolve_binary(cli_value: Optional[str]) -> str:
    candidates: List[Path] = []
    if cli_value:
        candidates.append(Path(cli_value).expanduser())

    env_value = os.environ.get("OCRTOOL_MCP_BIN")
    if env_value:
        candidates.append(Path(env_value).expanduser())

    root = repo_root()
    candidates.extend(
        [
            root / "ocrtool-mcp",
            root / ".build" / "release" / "ocrtool-mcp",
        ]
    )

    for candidate in candidates:
        if candidate.is_file():
            return str(candidate)

    path_candidate = shutil.which("ocrtool-mcp")
    if path_candidate:
        return path_candidate

    fail(
        "Unable to find ocrtool-mcp. Build it with `swift build -c release`, "
        "pass --binary, or set OCRTOOL_MCP_BIN."
    )


def build_arguments(args: argparse.Namespace) -> dict:
    provided = [bool(args.image_path), bool(args.url), bool(args.base64_file)]
    if sum(provided) != 1:
        fail("Exactly one of --image-path, --url, or --base64-file is required.")

    arguments = {
        "lang": args.lang,
        "format": "text" if args.insert_as_comment else args.format,
    }

    if args.insert_as_comment:
        arguments["output"] = {
            "insertAsComment": True,
            "language": args.comment_language,
        }

    if args.image_path:
        arguments["image_path"] = str(Path(args.image_path).expanduser())
    elif args.url:
        arguments["url"] = args.url
    else:
        payload = Path(args.base64_file).expanduser().read_text(encoding="utf-8").strip()
        if not payload:
            fail(f"Base64 file is empty: {args.base64_file}")
        try:
            base64.b64decode(payload, validate=True)
        except Exception as error:  # noqa: BLE001
            fail(f"Invalid base64 payload in {args.base64_file}: {error}")
        arguments["base64"] = payload

    return arguments


def mcp_lines(arguments: dict) -> list[str]:
    return [
        json.dumps(
            {
                "jsonrpc": "2.0",
                "id": 1,
                "method": "initialize",
                "params": {
                    "protocolVersion": "2024-11-05",
                    "capabilities": {},
                    "clientInfo": {"name": "ocr-workflow-skill", "version": "0.1.0"},
                },
            }
        ),
        json.dumps({"jsonrpc": "2.0", "method": "notifications/initialized"}),
        json.dumps(
            {
                "jsonrpc": "2.0",
                "id": 2,
                "method": "tools/call",
                "params": {"name": "ocr_extract_text", "arguments": arguments},
            }
        ),
    ]


def run_mcp(binary: str, lines: list[str]) -> dict:
    proc = subprocess.run(
        [binary],
        input="\n".join(lines) + "\n",
        text=True,
        capture_output=True,
        check=False,
    )

    if proc.returncode != 0:
        fail(proc.stderr.strip() or f"ocrtool-mcp exited with code {proc.returncode}")

    responses = []
    for raw_line in proc.stdout.splitlines():
        stripped = raw_line.strip()
        if not stripped:
            continue
        try:
            responses.append(json.loads(stripped))
        except json.JSONDecodeError as error:
            fail(f"Failed to parse MCP response line as JSON: {error}: {stripped}")

    if not responses:
        fail("ocrtool-mcp returned no JSON-RPC responses.")

    final = responses[-1]
    if "error" in final:
        fail(json.dumps(final["error"], ensure_ascii=False))

    result = final.get("result")
    if not isinstance(result, dict):
        fail(f"Unexpected MCP result payload: {json.dumps(final, ensure_ascii=False)}")

    return result


def extract_text(result: dict) -> str:
    if result.get("isError"):
        content = result.get("content") or []
        if content and isinstance(content[0], dict):
            fail(content[0].get("text") or "ocrtool-mcp returned an error result")
        fail("ocrtool-mcp returned an error result")

    content = result.get("content") or []
    if not content or not isinstance(content[0], dict):
        fail("ocrtool-mcp returned no content.")

    text = content[0].get("text")
    if not isinstance(text, str):
        fail("ocrtool-mcp returned non-text content.")

    return text


def main() -> None:
    args = parse_args()
    binary = resolve_binary(args.binary)
    arguments = build_arguments(args)
    result = run_mcp(binary, mcp_lines(arguments))

    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return

    print(extract_text(result))


if __name__ == "__main__":
    main()
