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
    sha256 cellar: :any,                 arm64_sequoia: "722fc8feb62166154794e1a2c360f17720b0820c3d2a7afbb6e19e11ca5ec9f9"
    sha256 cellar: :any,                 arm64_sonoma:  "c7e117b0488d86217814cf0efd34db3c17b3a1fc132f45935a7ced137ba9c33a"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "5574b29df97ae259bada086b737b8d4e6e14348b09161e8ccad2911335ce7d80"
    sha256 cellar: :any,                 ventura:       "fb6fbf52e4e73ec54171d9ba9677ecc00d950993ef19cc11c0014b74955aad1f"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "061bfb66ee9e2294a13f5b97a6a97a188dba6454af59e47338fa1b262df57e3b"
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
