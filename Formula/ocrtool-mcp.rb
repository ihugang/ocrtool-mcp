class OcrtoolMcp < Formula
  desc "macOS native OCR MCP server powered by the Vision framework"
  homepage "https://github.com/ihugang/ocrtool-mcp"
  url "https://github.com/ihugang/ocrtool-mcp/releases/download/v1.0.3/ocrtool-mcp-v1.0.3-universal-macos.tar.gz"
  sha256 "d5ced4ad2a4e19586b313ca3937f93a9b9836a1ab57ea4bcbaacdb3dd2cc20a4"
  license "MIT"

  depends_on :macos

  def install
    bin.install "ocrtool-mcp-v1.0.3-universal" => "ocrtool-mcp"
  end

  test do
    assert_match "OCRToolMCP Help", shell_output("#{bin}/ocrtool-mcp --help")
  end
end
