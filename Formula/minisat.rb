class Minisat < Formula
  desc "Minimalistic and high-performance SAT solver"
  homepage "https://github.com/stp/minisat"
  url "https://github.com/stp/minisat/archive/releases/2.2.1.tar.gz"
  sha256 "432985833596653fcd698ab439588471cc0f2437617d0df2bb191a0252ba423d"
  license "MIT"
  head "https://github.com/stp/minisat.git"

  bottle do
    root_url "https://github.com/carlocab/homebrew-personal/releases/download/minisat-2.2.1"
    sha256 cellar: :any,                 big_sur:      "4c0d3e442b4d6b0c09788a16a700e6b9a72fd4a4fe6b6679e23406c1a988f0b0"
    sha256 cellar: :any,                 catalina:     "c2f2dfd1254dd99debacea9c92c46305613bcdcd7cd71069483a2bb24fc81c76"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "2ebcc1b11de138365ac66d3f765ba7ccf23d847047b7eead7b0ebb89565fb4b1"
  end

  depends_on "cmake" => :build

  uses_from_macos "zlib"

  def install
    mkdir "build" do
      system "cmake", "..", *std_cmake_args, "-DSTATIC_BINARIES=OFF"
      system "make"
      system "make", "install"
    end
  end

  test do
    (testpath/"test.cnf").write <<~EOS
      p cnf 5 3
      1 -5 4 0
      -1 5 3 4 0
      -3 -4 0
    EOS

    assert_match "SATISFIABLE", shell_output("#{bin}/minisat test.cnf 2>&1", 10)
  end
end
