class Flang < Formula
  desc "Fortran front end for LLVM"
  homepage "http://flang.llvm.org"
  url "https://github.com/llvm/llvm-project/releases/download/llvmorg-11.1.0/flang-11.1.0.src.tar.xz"
  sha256 "7e29e3799fe6c8253c6300a226d3aab7514c07a295821df6eab33d2984eef348"
  license "Apache-2.0"
  head "https://github.com/llvm/llvm-project.git"

  bottle do
    root_url "https://github.com/carlocab/homebrew-personal/releases/download/flang-11.1.0"
    sha256 big_sur:  "0f26ed7835de8e5f864be291393662743b847984c2cec3901417a59a3db1aa5e"
    sha256 catalina: "70e8f137c2b52f8c9770401b3df29fdcde48dc194119323499a4d9676224a78c"
  end

  option "with-flang-new", "Build with experimental Flang driver"

  depends_on "cmake" => :build
  depends_on "gcc" => :test # for gfortran
  depends_on "llvm"

  def install
    llvm_cmake_lib = Formula["llvm"].opt_lib/"cmake"

    args = %W[
      -DLLVM_DIR=#{llvm_cmake_lib}/llvm
      -DMLIR_DIR=#{llvm_cmake_lib}/mlir
    ]

    on_linux do
      args.concat %w[
        -DCMAKE_C_COMPILER=clang
        -DCMAKE_CXX_COMPILER=clang++
      ]
    end

    if build.with? "flang-new"
      args.concat %W[
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
