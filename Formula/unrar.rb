class Unrar < Formula
  desc "Extract, view, and test RAR archives"
  homepage "https://www.rarlab.com/"
  url "https://www.rarlab.com/rar/unrarsrc-7.1.3.tar.gz"
  sha256 "f7edb6f55fb53611206781d9e56f2625ef4411a6b129768800196617d9df920a"
  license :cannot_represent

  livecheck do
    url "https://www.rarlab.com/rar_add.htm"
    regex(/href=.*?unrarsrc[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    root_url "https://ghcr.io/v2/carlocab/personal"
    sha256 cellar: :any,                 arm64_sonoma: "8e3b1546f64223163e4857f85adb2a8d7b15712a89d61e8f6279968437694faa"
    sha256 cellar: :any,                 ventura:      "d9a13d72496f303eb1b6035f53ef761fa83a0b22472ca98db84cad92860837e9"
    sha256 cellar: :any,                 monterey:     "a7af063c9241e5ff83ca667d9b0ec4d83d58362072dd4530ba64ca1dbfe6e5ba"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "fd30d7d473b7279be7f6799b81cc200ee1fd4d7faef4e3d1380b1ac0d4f0f852"
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
