class OcrtoolMcp < Formula
  desc "macOS native OCR MCP server powered by the Vision framework"
  homepage "https://github.com/ihugang/ocrtool-mcp"
  url "https://github.com/ihugang/ocrtool-mcp/releases/download/v1.0.6/ocrtool-mcp-v1.0.6-universal-macos.tar.gz"
  sha256 "acabe911d786ec6feefe7331da74673ef52747a8c7bf6f0222e60e1ca75735ea"
  license "MIT"

  depends_on :macos

  def install
    bin.install "ocrtool-mcp-v1.0.6-universal" => "ocrtool-mcp"
  end

  test do
    assert_match "OCRToolMCP Help", shell_output("#{bin}/ocrtool-mcp --help")
  end
end
