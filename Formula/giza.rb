class Giza < Formula
  desc "Scientific plotting library for C/Fortran built on cairo"
  homepage "http://giza.sourceforge.net"
  url "https://downloads.sourceforge.net/project/giza/v1.1.0/giza-1.1.0.tar.gz"
  sha256 "69f6b8187574eeb66ec3c1edadf247352b0ffebc6fc6ffbb050bafd324d3e300"
  license "GPL-2.0-only"

  depends_on "pkg-config" => :build
  depends_on "cairo"
  depends_on "gcc" # for gfortran
  depends_on "libx11"

  fails_with :clang do
    build 1200
    cause "error: unrecognised option: '-DHAVE_CONFIG_H'"
  end

  def install
    system "./configure", "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! For Homebrew/homebrew-core
    # this will need to be a test that verifies the functionality of the
    # software. Run the test with `brew test giza`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    system "false"
  end
end
