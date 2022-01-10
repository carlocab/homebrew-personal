class Flang < Formula
  desc "Fortran front end for LLVM"
  homepage "http://flang.llvm.org"
  url "https://github.com/llvm/llvm-project/releases/download/llvmorg-13.0.0/flang-13.0.0.src.tar.xz"
  sha256 "13bc580342bec32b6158c8cddeb276bd428d9fc8fd23d13179c8aa97bbba37d5"
  license "Apache-2.0" => { with: "LLVM-exception" }
  head "https://github.com/llvm/llvm-project.git", branch: "main"

  bottle do
    root_url "https://ghcr.io/v2/carlocab/personal"
    sha256 cellar: :any,                 big_sur:      "90f74d6c4df829bb93f6affcc63836d6036ce475ea249082cc4bd94112166955"
    sha256 cellar: :any,                 catalina:     "714f547d882e944af211bea3cc5ba567f77820861d1b3883f5ed0b01eb6b1128"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "0dee756d8679676a0d8f9ca99ef9944cf3dbcf47edd8c466ab15dbf09339490f"
  end

  option "with-ninja", "Build with `ninja` instead of `make`"
  option "without-flang-new", "Disable the new Flang driver"
  option "with-test", "Enable build-time tests"

  depends_on "cmake" => :build
  depends_on "lit" => :build
  depends_on "ninja" => :build
  depends_on "gcc" => :test # for gfortran
  depends_on "bash" # `flang` script uses `local -n`
  depends_on "llvm"
  uses_from_macos "zlib"

  fails_with gcc: "5"
  fails_with gcc: "6"
  fails_with :gcc if OS.linux?

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
      -DFLANG_INCLUDE_TESTS=#{build.with?("test") ? "ON" : "OFF"}
      -DLLVM_EXTERNAL_LIT=#{Formula["lit"].opt_bin/"lit"}
      -DLLVM_ENABLE_ZLIB=ON
    ]

    source = build.head? ? "flang" : "."
    cmake_generator = build.with?("ninja") ? "Ninja" : "Unix Makefiles"
    system "cmake", "-G", cmake_generator,
                    "-S", source, "-B", "build",
                    *std_cmake_args, *args
    system "cmake", "--build", "build"

    # Reconfigure to evade the shims which break the test suite
    if build.with? "test"
      system "cmake", "-G", cmake_generator,
                      "-S", source, "-B", "build",
                      "-DCMAKE_C_COMPILER=#{DevelopmentTools.locate(ENV.cc)}",
                      "-DCMAKE_CXX_COMPILER=#{DevelopmentTools.locate(ENV.cxx)}",
                      *std_cmake_args, *args
      system "cmake", "--build", "build", "--target", "check-all"
    end

    system "cmake", "--install", "build"
  end

  def caveats
    <<~EOS
      Flang currently requires an external Fortran compiler to compile
      and link Fortran source files. You can install one with
        brew install gcc
    EOS
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

    # FIXME: OpenMP seems broken for some reason.
    # expected_result = <<~EOS
    #   Hello from thread 0, nthreads 4
    #   Hello from thread 1, nthreads 4
    #   Hello from thread 2, nthreads 4
    #   Hello from thread 3, nthreads 4
    # EOS

    # system bin/"flang", "-fopenmp", "omptest.f90", "-o", "omptest"
    # testresult = shell_output("./omptest")

    # sorted_testresult = testresult.split("\n").sort.join("\n")
    # assert_equal expected_result.strip, sorted_testresult.strip

    (testpath/"test.f90").write <<~EOS
      PROGRAM test
        WRITE(*,'(A)') 'Hello World!'
      ENDPROGRAM
    EOS

    system bin/"flang", "test.f90", "-o", "test"
    assert_equal "Hello World!", shell_output("./test").chomp
  end
end
