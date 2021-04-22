class Unrar < Formula
  desc "Extract, view, and test RAR archives"
  homepage "https://www.rarlab.com/"
  url "https://www.rarlab.com/rar/unrarsrc-6.0.5.tar.gz"
  sha256 "7e34064c9e97464462c81aed80c25619149f71d4900995021780787f51dd63f0"
  license :cannot_represent

  livecheck do
    url "https://www.rarlab.com/rar_add.htm"
    regex(/href=.*?unrarsrc[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    root_url "https://github.com/carlocab/homebrew-personal/releases/download/unrar-6.0.5"
    sha256 cellar: :any,                 big_sur:      "ef3c8b89d82cb01ade1c5095907af009052fe02def16c9e641335943f09a8017"
    sha256 cellar: :any,                 catalina:     "db7f67801ff43dd8640f31a0d82fa0d2e5a195573b76c3034822b39b6ce3edcb"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "6cdf679c528baebcd1fdcad865fd659507f56ea34d69251169e753415a8c851c"
  end

  def install
    # upstream doesn't particularly care about their unix targets,
    # so we do the dirty work of renaming their shared objects to
    # dylibs for them.
    inreplace "makefile", "libunrar.so", "libunrar.dylib" if OS.mac?

    system "make"
    bin.install "unrar"

    # Explicitly clean up for the library build to avoid an issue with an
    # apparent implicit clean which confuses the dependencies.
    system "make", "clean"
    system "make", "lib"
    lib.install shared_library("libunrar")

    prefix.install "license.txt"
  end

  def caveats
    <<~EOS
      We agreed to the UnRAR license for you:
        #{opt_prefix}/license.txt
      If this is unacceptable you should uninstall the formula.
    EOS
  end

  test do
    contentpath = "directory/file.txt"
    rarpath = testpath/"archive.rar"
    data =  "UmFyIRoHAM+QcwAADQAAAAAAAACaCHQggDIACQAAAAkAAAADtPej1LZwZE" \
            "QUMBIApIEAAGRpcmVjdG9yeVxmaWxlLnR4dEhvbWVicmV3CsQ9ewBABwA="

    rarpath.write data.unpack1("m")
    assert_equal contentpath, `#{bin}/unrar lb #{rarpath}`.strip
    assert_equal 0, $CHILD_STATUS.exitstatus

    system "#{bin}/unrar", "x", rarpath, testpath
    assert_equal "Homebrew\n", (testpath/contentpath).read
  end
end
