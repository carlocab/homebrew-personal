class Libwhich < Formula
  desc "Like `which`, for dynamic libraries"
  homepage "https://github.com/vtjnash/libwhich"
  url "https://github.com/vtjnash/libwhich/archive/refs/tags/v1.2.0.tar.gz"
  sha256 "aa13017310f3f9b008267283c155992bb7e0f6002dafaf82e6f0dbd270c18b0a"
  license "MIT"
  head "https://github.com/vtjnash/libwhich.git"

  bottle do
    root_url "https://ghcr.io/v2/carlocab/personal"
    rebuild 2
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "1b49fd5b5df4d0526193b8e37d103464940430009c9af170876d945be8ea5a9c"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "e4d13ccdacedc55416224231f83a08977a1c85d35456dcb713683d45a90750e2"
    sha256 cellar: :any_skip_relocation, ventura:       "5548500b01ed6afa0b6171e714fda2c09605fe33287afc96a7b0cb3629251359"
    sha256 cellar: :any_skip_relocation, monterey:      "ca4d5466bf11bfe87654ce6242040680dfb799cdda623c416ceb7827fd3e2cdb"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "c3926f38987795b2359f31afbe1ba9d2955d4174f2b7aaf927e34f5fdecb39b0"
  end

  depends_on "gnu-sed" => :test

  def install
    ENV.append "LDFLAGS", "-Wl,-rpath,#{rpath(target: HOMEBREW_PREFIX/"lib")}"
    system "make", "prefix=#{prefix}", "install"
    inreplace "test-libwhich.sh", "./libwhich", "#{bin}/libwhich"
    libexec.install "test-libwhich.sh"
  end

  test do
    ENV.prepend_path "PATH", Formula["gnu-sed"].opt_libexec/"gnubin"
    system libexec/"test-libwhich.sh"
  end
end
