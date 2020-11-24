class Mlir < Formula
  desc "Novel approach to building reusable and extensible compiler infrastructure"
  homepage "https://mlir.llvm.org"
  url "https://github.com/llvm/llvm-project/releases/download/llvmorg-11.0.0/llvm-project-11.0.0.tar.xz"
  sha256 "b7b639fc675fa1c86dd6d0bc32267be9eb34451748d2efd03f674b773000e92b"
  license "Apache-2.0"

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "llvm" => :optional

  def install
    args = %w[
      -DLLVM_ENABLE_PROJECTS=mlir
      -DLLVM_TARGETS_TO_BUILD=all
      -DLLVM_ENABLE_ASSERTIONS=ON
    ]

    if build.with? "llvm"
      llvm_bin = Formula["llvm"].opt_bin
      args.concat %W[
        -DCMAKE_C_COMPILER=#{llvm_bin}/clang
        -DCMAKE_CXX_COMPILER=#{llvm_bin}/clang++
      ]
    end

    mkdir "build" do
      system "cmake", "-G", "Ninja", "../llvm", *(std_cmake_args + args)
      system "cmake", "--build", ".", "--target", "check-mlir"
      system "cmake", "--install", "."
    end
  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! For Homebrew/homebrew-core
    # this will need to be a test that verifies the functionality of the
    # software. Run the test with `brew test mlir`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    system "false"
  end
end
