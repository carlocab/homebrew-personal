class Flang < Formula
  desc "Fortran front end for LLVM"
  homepage "https://flang.llvm.org"
  url "https://github.com/llvm/llvm-project/releases/download/llvmorg-11.0.0/flang-11.0.0.src.tar.xz"
  sha256 "7447cf8af7875f39b653a4932d33ba89288a1d3aaad1f46c3da1196b092de633"
  license "Apache-2.0"
  head "https://github.com/llvm/llvm-project.git"

  option "with-flang-new", "Build with experimental Flang driver"

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "gcc" => :test # for gfortran
  depends_on "llvm"

  def install
    llvm_lib = Formula["llvm"].opt_lib

    args = %W[
      -DLLVM_DIR=#{llvm_lib}/cmake/llvm
      -DMLIR_DIR=#{llvm_lib}/cmake/mlir
    ]

    if build.with? "flang-new"
      args.concat %W[
        -DFLANG_BUILD_NEW_DRIVER=ON
        -DCLANG_DIR=#{llvm_lib}/cmake/clang
      ]
    end

    cd "flang" if build.head?

    mkdir "build" do
      system "cmake", "-G", "Ninja", "..", *(std_cmake_args + args)
      system "cmake", "--build", "."
      system "cmake", "--install", "."
    end
  end

  def caveats
    <<~EOS
      Flang currently requires an external Fortran compiler to compile and link
      Fortran source files. You can install one with
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
