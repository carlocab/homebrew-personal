class Flang < Formula
  desc "Fortran front end for LLVM"
  homepage "https://flang.llvm.org"
  url "https://github.com/llvm/llvm-project/releases/download/llvmorg-11.0.0/flang-11.0.0.src.tar.xz"
  sha256 "b7b639fc675fa1c86dd6d0bc32267be9eb34451748d2efd03f674b773000e92b"
  license "Apache-2.0"

  option "with-llvm", "Build with LLVM Clang"
  option "with-flang-new", "Build with experimental Flang driver"

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "gcc" => :test # for gfortran
  depends_on "llvm"
  depends_on "mlir"

  def install
    llvm_lib = Formula["llvm"].opt_lib
    mlir_lib = Formula["mlir"].opt_lib

    args = %W[
      -DLLVM_DIR=#{llvm_lib}/cmake/llvm
      -DMLIR_DIR=#{mlir_lib}/cmake/mlir
      -DCLANG_DIR=#{llvm_lib}/cmake/clang
    ]

    llvm_clang_flag = "-DCMAKE_CXX_COMPILER=#{Formula["llvm"].opt_bin}/clang++"
    args << llvm_clang_flag if build.with? "llvm"

    if build.with? "flang-new"
      # Add compiler flag for LLVM Clang unless it has already been included
      args << llvm_clang_flag unless build.with? "llvm"
      args << "-DFLANG_BUILD_NEW_DRIVER=ON"
    end

    mkdir "build" do
      system "cmake", "-G", "Ninja", "..", *(std_cmake_args + args)
      system "cmake", "--build", "."
      system "cmake", "--install", "."
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
