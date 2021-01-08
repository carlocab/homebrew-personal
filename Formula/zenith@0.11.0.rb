class ZenithAT0110 < Formula
  desc "In terminal graphical metrics for your *nix system"
  homepage "https://github.com/bvaisvil/zenith/"
  url "https://github.com/bvaisvil/zenith/archive/0.11.0.tar.gz"
  sha256 "be216df5d4e9bc0271971a17e8e090d3abe513f501c69e69174899a30c857254"
  license "MIT"
  head "https://github.com/bvaisvil/zenith.git"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    require "pty"
    require "io/console"

    (testpath/"zenith").mkdir
    r, w, pid = PTY.spawn "#{bin}/zenith --db zenith"
    r.winsize = [80, 43]
    sleep 1
    w.write "q"
    assert_match /PID\s+USER\s+P\s+N\s+↓CPU%\s+MEM%/, r.read
  ensure
    Process.kill("TERM", pid)
  end
end
