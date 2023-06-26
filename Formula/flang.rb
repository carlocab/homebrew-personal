class Flang < Formula
  desc "Fortran front end for LLVM"
  homepage "https://flang.llvm.org"
  url "https://github.com/llvm/llvm-project/releases/download/llvmorg-16.0.6/flang-16.0.6.src.tar.xz"
  sha256 "0a15d253d0d81c6f4619cd834f7a934e6ae69cfc74eeed9ba3c8372648253017"
  license "Apache-2.0" => { with: "LLVM-exception" }
  head "https://github.com/llvm/llvm-project.git", branch: "main"

  bottle do
    root_url "https://ghcr.io/v2/carlocab/personal"
    sha256 cellar: :any,                 monterey:     "7287a85c68d694728ea4590ad984372171b270790bb8c42f73f64ad4b4b2ea51"
    sha256 cellar: :any,                 big_sur:      "d0fb48e06cd899a6160744bf3d4db6705aff5a37800be117c156158d1a2b39a5"
    sha256 cellar: :any,                 catalina:     "408878fa4c14121c404691ae215cb9ec0087c1072bf807f1509149d2e17e0c2c"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "89b6b575df7fcc31081dedcd67f2b28f26f972d288fa5862054bb534eeb36765"
  end

  option "with-ninja", "Build with `ninja` instead of `make`"
  option "without-flang-new", "Disable the new Flang driver"

  depends_on "cmake" => :build
  depends_on "ninja" => :build if build.with?("ninja")
  depends_on "bash" # `flang` script uses `local -n`
  depends_on "gcc" # for gfortran
  depends_on "llvm"
  uses_from_macos "zlib"

  # We need to compile with Homebrew GCC 11.
  fails_with gcc: "5"
  fails_with gcc: "6"
  fails_with gcc: "7"
  fails_with gcc: "8"
  fails_with gcc: "9"
  fails_with gcc: "10"

  def llvm
    deps.map(&:to_formula)
        .find { |f| f.name.match?(/^llvm(@\d+(\.\d+)*)?$/) }
  end

  def install
    llvm_cmake_lib = llvm.opt_lib/"cmake"
    args = %W[
      -DLLVM_DIR=#{llvm_cmake_lib}/llvm
      -DMLIR_DIR=#{llvm_cmake_lib}/mlir
      -DCLANG_DIR=#{llvm_cmake_lib}/clang
      -DFLANG_BUILD_NEW_DRIVER=#{build.with?("flang-new") ? "ON" : "OFF"}
      -DFLANG_INCLUDE_TESTS=OFF
      -DLLVM_ENABLE_ZLIB=ON
    ]

    source = build.head? ? "flang" : "flang-#{version}.src"
    cmake_generator = build.with?("ninja") ? "Ninja" : "Unix Makefiles"
    system "cmake", "-G", cmake_generator,
                    "-S", source, "-B", "build",
                    *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"omptest.f90").write <<~EOS
      PROGRAM omptest
      USE omp_lib
      !$OMP PARALLEL NUM_THREADS(4)
      WRITE(*,'(A,I1,A,I1)') 'Hello from thread ', OMP_GET_THREAD_NUM(), ', nthreads ', OMP_GET_NUM_THREADS()
      !$OMP END PARALLEL
      ENDPROGRAM
    EOS

    expected_result = <<~EOS
      Hello from thread 0, nthreads 4
      Hello from thread 1, nthreads 4
      Hello from thread 2, nthreads 4
      Hello from thread 3, nthreads 4
    EOS

    system bin/"flang", "-fopenmp", "omptest.f90", "-o", "omptest"
    testresult = shell_output("./omptest")

    sorted_testresult = testresult.split("\n").sort.join("\n")
    assert_equal expected_result.strip, sorted_testresult.strip

    (testpath/"test.f90").write <<~EOS
      PROGRAM test
        WRITE(*,'(A)') 'Hello World!'
      ENDPROGRAM
    EOS

    system bin/"flang", "test.f90", "-o", "test"
    assert_equal "Hello World!", shell_output("./test").chomp
  end
end
