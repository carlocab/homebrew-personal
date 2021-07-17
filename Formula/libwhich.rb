class Libwhich < Formula
  desc "Like `which`, for dynamic libraries"
  homepage "https://github.com/vtjnash/libwhich"
  url "https://github.com/vtjnash/libwhich/archive/v1.1.0.tar.gz"
  sha256 "f1c30bf7396859ad437a5db74e9e328fb4b4e1379457121e28a3524b1e3a0b3f"
  license "MIT"
  head "https://github.com/vtjnash/libwhich.git"

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
