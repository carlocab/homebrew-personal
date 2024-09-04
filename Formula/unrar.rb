class Unrar < Formula
  desc "Extract, view, and test RAR archives"
  homepage "https://www.rarlab.com/"
  url "https://www.rarlab.com/rar/unrarsrc-6.1.7.tar.gz"
  sha256 "de75b6136958173fdfc530d38a0145b72342cf0d3842bf7bb120d336602d88ed"
  license :cannot_represent

  livecheck do
    url "https://www.rarlab.com/rar_add.htm"
    regex(/href=.*?unrarsrc[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    root_url "https://ghcr.io/v2/carlocab/personal"
    sha256 cellar: :any,                 monterey:     "c4755a788f211d4fbf771f393c462b03f06187175336b07a63bd58f49f3c48b7"
    sha256 cellar: :any,                 big_sur:      "810c07909efee01a9e53565ac5c3fa0e23c4a7366513e25cc999a56c676ea9f4"
    sha256 cellar: :any,                 catalina:     "d4d1a01ac88e72703c8ece503f575a4d78d66627c1439e3fccb690c2ac68ba28"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "dc1653e57cf64fe30b92c0889c0a92ee3b08ae8616b3cd4532e5a1eda635c1f1"
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
    assert_equal contentpath, shell_output("#{bin}/unrar lb #{rarpath}").strip
    assert_equal 0, $CHILD_STATUS.exitstatus

    system "#{bin}/unrar", "x", rarpath, testpath
    assert_equal "Homebrew", (testpath/contentpath).read.chomp
  end
end
