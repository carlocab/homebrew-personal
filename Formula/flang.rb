class Flang < Formula
  desc "Fortran front end for LLVM"
  homepage "http://flang.llvm.org"
  url "https://github.com/llvm/llvm-project/releases/download/llvmorg-12.0.1/flang-12.0.1.src.tar.xz"
  sha256 "4741c9a2c8bf28f098173ef4a55d440e015b8039b96ffbb1473fb553c7b4394f"
  license "Apache-2.0" => { with: "LLVM-exception" }
  head "https://github.com/llvm/llvm-project.git", branch: "main"

  bottle do
    root_url "https://ghcr.io/v2/carlocab/personal"
    sha256 cellar: :any,                 big_sur:      "2391c4a231e21a5af3310e2b3f686e861a0620209f4eabf7a9623fb6eb8f30c9"
    sha256 cellar: :any,                 catalina:     "84d3135ac6244d59eb44c62ba9065bb7e01cb47a843b58d6723323cb87281802"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "1c06931f6555047e570f94200469f0b3ce858b01c8621eed30487cb27bad0c38"
  end

  option "with-flang-new", "Build with experimental Flang driver"

  depends_on "cmake" => :build
  depends_on "gcc" => :test # for gfortran
  depends_on "llvm"
  uses_from_macos "zlib"

  fails_with gcc: "5"
  fails_with gcc: "6"
  fails_with :gcc if OS.linux?

  def install
    llvm_cmake_lib = Formula["llvm"].opt_lib/"cmake"
    args = %W[
      -DLLVM_DIR=#{llvm_cmake_lib}/llvm
      -DMLIR_DIR=#{llvm_cmake_lib}/mlir
      -DLLVM_ENABLE_ZLIB=ON
      -DFLANG_INCLUDE_TESTS=OFF
    ]

    # Build by default when the following commit lands in a release:
    # https://github.com/llvm/llvm-project/commit/97a71ae6259191c09de644c55deb4448a259a1b1
    if build.head? || build.with?("flang-new")
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
