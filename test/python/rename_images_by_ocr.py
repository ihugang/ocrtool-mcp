import os
import re
import json
import subprocess
from collections import Counter

# 配置
DESKTOP = os.path.expanduser("~/Desktop")
OCR_TOOL = "/Users/shrek/Downloads/Dev/2025/Swift/ocrit-mcp/ocrtool-mcp"
IMG_EXTS = (".png", ".jpg", ".jpeg", ".bmp", ".gif", ".tiff")

def is_garbled(filename):
    # 仅字母数字且长度大于8，或包含特殊字符
    name, _ = os.path.splitext(filename)
    if re.fullmatch(r'[A-Za-z0-9\-_\.]+', name) and len(name) > 8:
        return True
    if re.search(r'[^A-Za-z0-9\u4e00-\u9fa5]', name) and not re.search(r'[\u4e00-\u9fa5A-Za-z]', name):
        return True
    return False

def ocr_image(image_path):
    print(f"OCR识别图片: {image_path}")
    initialize = json.dumps({
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {"name": "rename-images-by-ocr", "version": "1.0.1"}
        }
    })
    initialized = json.dumps({
        "jsonrpc": "2.0",
        "method": "notifications/initialized"
    })
    tool_call = json.dumps({
        "jsonrpc": "2.0",
        "id": 2,
        "method": "tools/call",
        "params": {
            "name": "ocr_extract_text",
            "arguments": {
                "image_path": os.path.expanduser(image_path),
                "format": "structured",
                "lang": "zh+en"
            }
        }
    })

    cmd = f"printf '%s\\n%s\\n%s\\n' '{initialize}' '{initialized}' '{tool_call}' | {OCR_TOOL}"
    proc = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, err = proc.communicate()

    try:
        responses = [json.loads(line) for line in out.decode(errors='ignore').splitlines() if line.strip()]
        result = responses[-1]["result"]
        print("识别到的文本：", result)
        if result.get("isError"):
            print("OCR工具返回错误：", result["content"][0]["text"])
            return []

        lines = json.loads(result["content"][0]["text"]).get("lines", [])
        print("识别到的文本行：", lines)
        return lines
    except Exception as e:
        print("解析OCR结果出错：", e)
        return []

def pick_best_text_by_height(lines):
    # lines: OCR结构化结果的所有行（dict列表）
    if not lines:
        return None
    max_line = max(lines, key=lambda l: l.get("bbox", {}).get("height", 0))
    return max_line.get("text", None)

def safe_filename(s, ext):
    # 只保留中英文、数字、下划线，空格变下划线
    s = re.sub(r'[^\u4e00-\u9fa5A-Za-z0-9_ ]', '', s)
    s = s.strip().replace(' ', '_')
    return s[:30] + ext  # 文件名最长30字符    

def main():
    files = [f for f in os.listdir(DESKTOP) if f.lower().endswith(IMG_EXTS)]
    garbled_files = [f for f in files if is_garbled(f)]
    print(f"检测到疑似乱码图片文件：{garbled_files}")

    for fname in garbled_files:
        img_path = os.path.join(DESKTOP, fname)
        print(f"\n处理图片: {img_path}")
        lines = ocr_image(img_path)
        best = pick_best_text_by_height(lines)
        print("选中的最大高度段落：", best)
        if not best:
            print(f"{fname} 未识别到有效文字，跳过")
            continue

        ext = os.path.splitext(fname)[1]
        new_base = safe_filename(best, ext)
        new_name = new_base
        i = 1
        while os.path.exists(os.path.join(DESKTOP, new_name)):
            new_name = f"{safe_filename(best, '')}_{i}{ext}"
            i += 1

        os.rename(img_path, os.path.join(DESKTOP, new_name))
        print(f"{fname} -> {new_name}")

if __name__ == "__main__":
    main()
