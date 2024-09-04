class Libwhich < Formula
  desc "Like `which`, for dynamic libraries"
  homepage "https://github.com/vtjnash/libwhich"
  url "https://github.com/vtjnash/libwhich/archive/refs/tags/v1.2.0.tar.gz"
  sha256 "aa13017310f3f9b008267283c155992bb7e0f6002dafaf82e6f0dbd270c18b0a"
  license "MIT"
  head "https://github.com/vtjnash/libwhich.git"

  bottle do
    root_url "https://ghcr.io/v2/carlocab/personal"
    sha256 cellar: :any_skip_relocation, big_sur:      "a43faeef4fe0d6884d7f6b83f78f1dd5c724cbac574361c689086334b0722f64"
    sha256 cellar: :any_skip_relocation, catalina:     "279c630cfddf07d58d9c98e0208c6f02f452176585f8d30e3009b8886e32ff02"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "6633347026a69c78afc5eb57d2fb22c4f2cd01fed72b412d9b02030e1728e22c"
  end

  on_linux do
    depends_on "gnu-sed" => :test
  end

  def install
    system "make"
    bin.install "libwhich"
    inreplace "test-libwhich.sh", "./libwhich", "#{bin}/libwhich"
    libexec.install "test-libwhich.sh"
  end

  test do
    assert_equal "/usr/lib/libSystem.B.dylib", shell_output("#{bin}/libwhich -p libSystem.B.dylib") if OS.mac?
    return unless OS.linux?

    ENV.prepend_path "PATH", Formula["gnu-sed"].opt_libexec/"gnubin"
    system ENV.cc, "-o", shared_library("libz"), "-shared", "-x", "c", "/dev/null"
    system libexec/"test-libwhich.sh"
  end
end
