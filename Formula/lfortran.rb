class Lfortran < Formula
  desc "Modern interactive LLVM-based Fortran compiler"
  homepage "https://lfortran.org"
  url "https://lfortran.github.io/tarballs/release/lfortran-0.10.0.tar.gz"
  sha256 "53b727fa795dd1f44656c50c647f80885c4eede98f719ab7129ee6502e27684f"
  license "BSD-3-Clause"

  head do
    url "https://gitlab.com/lfortran/lfortran.git"

    depends_on "binutils" => :build
    depends_on "bison" => :build
    depends_on "re2c" => :build
  end

  depends_on "cmake" => :build
  depends_on "llvm" => [:build, :recommended]
  depends_on "fmt" => :recommended
  depends_on "rapidjson" => :recommended

  uses_from_macos "libxml2"
  uses_from_macos "zlib"

  def install
    inreplace "src/lfortran/CMakeLists.txt", "p::zlib", "system_zlib"
    inreplace "cmake/FindZLIB.cmake", "p::zlib", "system_zlib"

    args = std_cmake_args
    args << "-DWITH_LLVM=on" if build.with? "llvm"
    args << "-DWITH_FMT=on" if build.with? "fmt"
    args << "-DWITH_JSON=on" if build.with? "rapidjson"

    system "./build0.sh" if build.head?
    system "cmake", "-S", ".", "-B", "build", *args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.f90").write <<~EOS
      PROGRAM test
        WRITE(*,'(A)') 'Hello World!'
      ENDPROGRAM
    EOS

    system "#{bin}/lfortran", "test.f90", "-o", "test"
    assert_equal "Hello World!", shell_output("./test").chomp
  end
end
