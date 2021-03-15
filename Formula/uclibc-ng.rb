class UclibcNg < Formula
  desc "Small C library for developing embedded Linux systems"
  homepage "https://uclibc-ng.org"
  url "https://downloads.uclibc-ng.org/releases/1.0.37/uClibc-ng-1.0.37.tar.xz"
  sha256 "b2b815d20645cf604b99728202bf3ecb62507ce39dfa647884b4453caf86212c"
  license "LGPL-2.1-or-later"

  depends_on :linux

  def install
    system "make", "defconfig"
    system "make", "PREFIX=#{prefix}", "install"
  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! For Homebrew/homebrew-core
    # this will need to be a test that verifies the functionality of the
    # software. Run the test with `brew test uClibc-ng`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    system "true"
  end
end
