class Flang < Formula
  desc "Fortran front end for LLVM"
  homepage "http://flang.llvm.org"
  url "https://github.com/llvm/llvm-project/releases/download/llvmorg-12.0.0/flang-12.0.0.src.tar.xz"
  sha256 "dc9420c9f55c6dde633f0f46fe3f682995069cc5247dfdef225cbdfdca79123a"
  license "Apache-2.0"
  revision 1
  head "https://github.com/llvm/llvm-project.git"

  bottle do
    root_url "https://github.com/carlocab/homebrew-personal/releases/download/flang-12.0.0_1"
    sha256                               big_sur:      "755206e7c9a600d0e6a7a9ff0957287e838d01f5f4206e3bf471ee13eb188990"
    sha256                               catalina:     "653837d0717655a945dcbd48eb50ed85c275ec258e7c70d81741b3acfc4240d3"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "4ef4cf853268ece42b1be2f359a1623af96360e13eb743b6efc2740a4a754421"
  end

  option "with-flang-new", "Build with experimental Flang driver"

  depends_on "cmake" => :build
  depends_on "gcc" => :test # for gfortran
  depends_on "llvm"

  uses_from_macos "zlib"

  fails_with gcc: "5"

  def install
    llvm_cmake_lib = Formula["llvm"].opt_lib/"cmake"
    args = %W[
      -DLLVM_DIR=#{llvm_cmake_lib}/llvm
      -DMLIR_DIR=#{llvm_cmake_lib}/mlir
      -DLLVM_ENABLE_ZLIB=ON
      -DFLANG_INCLUDE_TESTS=OFF
    ]

    if build.with? "flang-new"
      args += %W[
        -DFLANG_BUILD_NEW_DRIVER=ON
        -DCLANG_DIR=#{llvm_cmake_lib}/clang
      ]
    end

    cd "flang" if build.head?
    mkdir "build" do
      system "cmake", "-G", "Unix Makefiles", "..", *(std_cmake_args + args)
      system "cmake", "--build", "."
      system "cmake", "--install", "."
    end
  end

  def caveats
    on_macos do
      <<~EOS
        Flang currently requires an external Fortran compiler to compile
        and link Fortran source files. You can install one with
          brew install gcc
      EOS
    end
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

    system "#{bin}/flang", "-fopenmp", "omptest.f90", "-o", "omptest"
    testresult = shell_output("./omptest")

    sorted_testresult = testresult.split("\n").sort.join("\n")
    assert_equal expected_result.strip, sorted_testresult.strip

    (testpath/"test.f90").write <<~EOS
      PROGRAM test
        WRITE(*,'(A)') 'Hello World!'
      ENDPROGRAM
    EOS

    system "#{bin}/flang", "test.f90", "-o", "test"
    assert_equal "Hello World!", shell_output("./test").chomp
  end
end
