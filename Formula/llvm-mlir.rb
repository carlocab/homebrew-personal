class LlvmMlir < Formula
  desc "Multi-level IR Compiler Framework"
  homepage "https://mlir.llvm.org/"
  # The LLVM Project is under the Apache License v2.0 with LLVM Exceptions
  license "Apache-2.0"
  head "https://github.com/llvm/llvm-project.git"

  stable do
    url "https://github.com/llvm/llvm-project/releases/download/llvmorg-11.0.0/llvm-project-11.0.0.tar.xz"
    sha256 "b7b639fc675fa1c86dd6d0bc32267be9eb34451748d2efd03f674b773000e92b"

    patch do
      url "https://github.com/llvm/llvm-project/commit/c86f56e32e724c6018e579bb2bc11e667c96fc96.patch?full_index=1"
      sha256 "6e13e01b4f9037bb6f43f96cb752d23b367fe7db4b66d9bf2a4aeab9234b740a"
    end

    patch do
      url "https://github.com/llvm/llvm-project/commit/31e5f7120bdd2f76337686d9d169b1c00e6ee69c.patch?full_index=1"
      sha256 "f025110aa6bf80bd46d64a0e2b1e2064d165353cd7893bef570b6afba7e90b4d"
    end

    patch do
      url "https://github.com/llvm/llvm-project/commit/3c7bfbd6831b2144229734892182d403e46d7baf.patch?full_index=1"
      sha256 "62014ddad6d5c485ecedafe3277fe7978f3f61c940976e3e642536726abaeb68"
    end

    patch do
      url "https://github.com/llvm/llvm-project/commit/c4d7536136b331bada079b2afbb2bd09ad8296bf.patch?full_index=1"
      sha256 "2b894cbaf990510969bf149697882c86a068a1d704e749afa5d7b71b6ee2eb9f"
    end
  end

  livecheck do
    url :homepage
    regex(/LLVM (\d+.\d+.\d+)/i)
  end

  # Clang cannot find system headers if Xcode CLT is not installed
  pour_bottle? do
    reason "The bottle needs the Xcode CLT to be installed."
    satisfy { MacOS::CLT.installed? }
  end

  # https://llvm.org/docs/GettingStarted.html#requirement
  # We intentionally use Make instead of Ninja.
  # See: Homebrew/homebrew-core/issues/35513
  depends_on "cmake" => :build

  uses_from_macos "llvm"

  # Upstream ARM patch for OpenMP runtime, remove in next version
  # https://reviews.llvm.org/D91002
  # https://bugs.llvm.org/show_bug.cgi?id=47609
  patch do
    url "https://raw.githubusercontent.com/Homebrew/formula-patches/6166a68c/llvm/openmp_arm.patch"
    sha256 "70fe3836b423e593688cd1cc7a3d76ee6406e64b9909f1a2f780c6f018f89b1e"
  end

  def install
    # Apple's libstdc++ is too old to build LLVM
    ENV.libcxx if ENV.compiler == :clang

    # compiler-rt has some iOS simulator features that require i386 symbols
    # I'm assuming the rest of clang needs support too for 32-bit compilation
    # to work correctly, but if not, perhaps universal binaries could be
    # limited to compiler-rt. llvm makes this somewhat easier because compiler-rt
    # can almost be treated as an entirely different build from llvm.
    ENV.permit_arch_flags

    args = %W[
      -DLLVM_ENABLE_PROJECTS=mlir
      -DLLVM_BUILD_EXAMPLES=ON
      -DLLVM_TARGETS_TO_BUILD=all
      -DLLVM_ENABLE_ASSERTIONS=ON
      -DCMAKE_C_COMPILER=clang
      -DCMAKE_CXX_COMPILER=clang++
    ]

    sdk = MacOS.sdk_path_if_needed
    args << "-DDEFAULT_SYSROOT=#{sdk}" if sdk

    if MacOS.version == :mojave && MacOS::CLT.installed?
      # Mojave CLT linker via software update is older than Xcode.
      # Use it to retain compatibility.
      args << "-DCMAKE_LINKER=/Library/Developer/CommandLineTools/usr/bin/ld"
    end

    llvmpath = buildpath/"llvm"
    mkdir llvmpath/"build" do
      system "cmake", "-G", "Unix Makefiles", "..", *(std_cmake_args + args)
      system "make"
      system "make", "install"
    end
  end

  test do
    system "false"
  end
end
