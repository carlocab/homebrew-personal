class WebsocatAT160 < Formula
  desc "Command-line client for WebSockets"
  homepage "https://github.com/vi/websocat"
  url "https://github.com/vi/websocat/archive/v1.6.0.tar.gz"
  sha256 "3f7e5e99d766b387292af56c8e4b39ce9a7f0da54ff558a6080ddc1024a33896"
  license "MIT"

  livecheck do
    url :stable
    regex(/v([\d.]+$)/i)
  end

  depends_on "pkg-config" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "openssl@1.1"
  end

  def install
    system "cargo", "install", "--features", "ssl", *std_cargo_args
  end

  test do
    system "#{bin}/websocat", "-t", "literal:qwe", "assert:qwe"
  end
end
