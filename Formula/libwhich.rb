class Libwhich < Formula
  desc "Like `which`, for dynamic libraries"
  homepage "https://github.com/vtjnash/libwhich"
  url "https://github.com/vtjnash/libwhich/archive/refs/tags/v1.2.0.tar.gz"
  sha256 "aa13017310f3f9b008267283c155992bb7e0f6002dafaf82e6f0dbd270c18b0a"
  license "MIT"
  head "https://github.com/vtjnash/libwhich.git"

  bottle do
    root_url "https://ghcr.io/v2/carlocab/personal"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "71a5dda4fc65ded27ad4b0339b4341d562be871ffb1b2eb69ba06ea91d234ded"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "c7ea378d55b175a2197b3a1eb6f3f1deb9fa0bea1ead38ebcb9cc1591ce5e187"
    sha256 cellar: :any_skip_relocation, ventura:       "7060045b6ee2e1aff0cad8151440cd9b26b3a6f4875b47062a0d68b401bf64aa"
    sha256 cellar: :any_skip_relocation, monterey:      "da9995ccab645cd58c98ee8ff2954782dfaada5d5be0a668e6adbb4ff4cf5bdc"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "f7b0d2c795443617f7cba3455f02838bb28aad3295cf575bd18e5e56cfc3e566"
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
