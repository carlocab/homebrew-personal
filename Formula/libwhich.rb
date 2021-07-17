class Libwhich < Formula
  desc "Like `which`, for dynamic libraries"
  homepage "https://github.com/vtjnash/libwhich"
  url "https://github.com/vtjnash/libwhich/archive/v1.1.0.tar.gz"
  sha256 "f1c30bf7396859ad437a5db74e9e328fb4b4e1379457121e28a3524b1e3a0b3f"
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

  # Fix `test-libwhich.sh` on Linux
  # https://github.com/vtjnash/libwhich/pull/15
  patch do
    url "https://github.com/vtjnash/libwhich/commit/87cffe10080c98e7b5786c5166e420bf1ada1d41.patch?full_index=1"
    sha256 "3fde7731301750c6d1756e5b64d232ff6eebec8ed35ece3fde55f2a8fb3ca3cb"
  end

  def install
    system "make"
    bin.install "libwhich"
    inreplace "test-libwhich.sh", "./libwhich", "#{bin}/libwhich"
    libexec.install "test-libwhich.sh"
  end

  test do
    on_macos do
      assert_equal "/usr/lib/libSystem.B.dylib", shell_output("#{bin}/libwhich -p libSystem.B.dylib")
    end

    on_linux do
      ENV.prepend_path "PATH", Formula["gnu-sed"].opt_libexec/"gnubin"
      system ENV.cc, "-o", shared_library("libz"), "-shared", "-x", "c", "/dev/null"
      system libexec/"test-libwhich.sh"
    end
  end
end
