class OcrtoolMcp < Formula
  desc "macOS native OCR MCP server powered by the Vision framework"
  homepage "https://github.com/ihugang/ocrtool-mcp"
  url "https://github.com/ihugang/ocrtool-mcp/releases/download/v1.0.5/ocrtool-mcp-v1.0.5-universal-macos.tar.gz"
  sha256 "23a6b3c58d3ff4acbe5ff0433b2ad89854b79b9054766ba4a3a2eaf4e73265d2"
  license "MIT"

  depends_on :macos

  def install
    bin.install "ocrtool-mcp-v1.0.5-universal" => "ocrtool-mcp"
  end

  test do
    assert_match "OCRToolMCP Help", shell_output("#{bin}/ocrtool-mcp --help")
  end
end
