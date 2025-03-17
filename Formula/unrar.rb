class Unrar < Formula
  desc "Extract, view, and test RAR archives"
  homepage "https://www.rarlab.com/"
  url "https://www.rarlab.com/rar/unrarsrc-7.1.5.tar.gz"
  sha256 "d1acac7ed5b45db587294b357fdd6e74982ce21f5edfcb113c4ca263bc0c666d"
  license :cannot_represent

  livecheck do
    url "https://www.rarlab.com/rar_add.htm"
    regex(/href=.*?unrarsrc[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    root_url "https://ghcr.io/v2/carlocab/personal"
    sha256 cellar: :any,                 arm64_sequoia: "1a57e04052f4bae4172d546a7927c645fc29d2ef5fafbec19d08ee1dddc542fb"
    sha256 cellar: :any,                 arm64_sonoma:  "a58cf9af5d04d3d5709b5337f3793586087a79e178da51d1f3978c0c13b8cf34"
    sha256 cellar: :any,                 ventura:       "6d8b90b2cbb31dcb78394c6540f5454cd57232fc309921173814f880e63718f0"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "cd5faac2834ba79e39429b9aac99e4f69d6e6023cbb1cbcd0b62e94cfc69bb2a"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "457d3e9bd0c287483e27f29a488a18c90e1f55be076fc49b07942ef396c419be"
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
