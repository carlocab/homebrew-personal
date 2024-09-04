class Libwhich < Formula
  desc "Like `which`, for dynamic libraries"
  homepage "https://github.com/vtjnash/libwhich"
  url "https://github.com/vtjnash/libwhich/archive/refs/tags/v1.2.0.tar.gz"
  sha256 "aa13017310f3f9b008267283c155992bb7e0f6002dafaf82e6f0dbd270c18b0a"
  license "MIT"
  head "https://github.com/vtjnash/libwhich.git"

  bottle do
    root_url "https://ghcr.io/v2/carlocab/personal"
    sha256 cellar: :any_skip_relocation, arm64_sonoma: "f894b78904dc4df92d137e0d13033b827a53876838f9130c989c9cf6db8a5b29"
    sha256 cellar: :any_skip_relocation, ventura:      "3bc4295c6e3c148d30ee8b6e6cb613ab36cbbcef5083873776f9c57093c02222"
    sha256 cellar: :any_skip_relocation, monterey:     "8bddfa1aa39e024f6768c03a456ac61d3f488c3c348e461e1a836f1f5fd391d9"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "a55b7b93beffa1a446572913d8463811e23748ec880b85a93a06c68a7c30ef0c"
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
