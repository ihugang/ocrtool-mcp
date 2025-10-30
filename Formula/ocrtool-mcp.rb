class OcrtoolMcp < Formula
  desc "macOS native OCR tool implementing Model Context Protocol"
  homepage "https://github.com/ihugang/ocrtool-mcp"
  url "https://github.com/ihugang/ocrtool-mcp/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "c4a99345e9bb7dc51e74b0e59f36187aa295376f8b6a6a929068be89189f231a"
  license "MIT"

  depends_on :macos
  depends_on xcode: ["14.0", :build]

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox", "--arch", "arm64", "--arch", "x86_64"
    bin.install ".build/apple/Products/Release/ocrtool-mcp"
  end

  test do
    assert_match "OCRToolMCP Help", shell_output("#{bin}/ocrtool-mcp --help")
  end
end
