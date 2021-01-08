class RustscanAT201 < Formula
  desc "Modern Day Portscanner"
  homepage "https://github.com/rustscan/rustscan"
  url "https://github.com/RustScan/RustScan/archive/2.0.1.tar.gz"
  sha256 "1d458cb081cbed2db38472ff33f9546a6640632148b4396bd12f0229ca9de7eb"
  license "GPL-3.0-or-later"

  depends_on "rust" => :build
  depends_on "nmap"

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_no_match /panic/, shell_output("#{bin}/rustscan --greppable -a 127.0.0.1")
    assert_no_match /panic/, shell_output("#{bin}/rustscan --greppable -a 0.0.0.0")
  end
end
