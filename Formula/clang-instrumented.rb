class ClangInstrumented < Formula
  desc "Instrumented Clang Compiler"
  homepage "https://clang.llvm.org/"
  url "https://github.com/llvm/llvm-project/releases/download/llvmorg-12.0.1/llvm-project-12.0.1.src.tar.xz"
  sha256 "129cb25cd13677aad951ce5c2deb0fe4afc1e9d98950f53b51bdcfb5a73afa0e"
  # The LLVM Project is under the Apache License v2.0 with LLVM Exceptions
  license "Apache-2.0" => { with: "LLVM-exception" }
  head "https://github.com/llvm/llvm-project.git", branch: "main"

  livecheck do
    url "https://llvm.org"
    regex(/LLVM (\d+\.\d+\.\d+)/i)
  end

  bottle do
    root_url "https://ghcr.io/v2/carlocab/personal"
    rebuild 1
    sha256 cellar: :any,                 big_sur:      "3657aed11575fb96dc1111be0658333d9c5ec027820fbf23ec4f672e93b159d1"
    sha256 cellar: :any,                 catalina:     "8d7ef086ea8257e12ab39cbce0897bd30772ebe91da4339f1a6496f8d26e0be6"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "11afe2f0252a9a2ef105ac69c4398ddb5837680d9ab779831ee531e85640a13f"
  end

  # Clang cannot find system headers if Xcode CLT is not installed
  pour_bottle? only_if: :clt_installed

  keg_only <<~EOS
    this formula is mainly used internally for bootstrapping.
    Users are advised to install the `llvm` formula instead
  EOS

  # https://llvm.org/docs/GettingStarted.html#requirement
  # We intentionally use Make instead of Ninja.
  # See: Homebrew/homebrew-core/issues/35513
  depends_on "cmake" => :build
  depends_on "llvm" => :build
  depends_on "python@3.9" => :build

  on_linux do
    depends_on "glibc" if Formula["glibc"].any_version_installed?
    depends_on "pkg-config" => :build
    depends_on "binutils" # needed for gold
  end

  def install
    require "timeout"

    args = %W[
      -DLLVM_TARGETS_TO_BUILD=Native
      -DLLVM_ENABLE_PROJECTS=clang;compiler-rt;lld
      -DLLVM_ENABLE_FFI=OFF
      -DLLVM_INCLUDE_DOCS=OFF
      -DLLVM_ENABLE_Z3_SOLVER=OFF
      -DLLVM_OPTIMIZED_TABLEGEN=ON
      -DLLVM_CREATE_XCODE_TOOLCHAIN=OFF
      -DBUG_REPORT_URL=#{tap.issues_url}
    ]

    sdk = MacOS.sdk_path_if_needed
    if OS.mac?
      # Prevent linkage with LLVM libc++
      ENV.remove "HOMEBREW_LIBRARY_PATHS", Formula["llvm"].opt_lib

      args << "-DLLVM_ENABLE_LIBCXX=ON"
      args << "-DRUNTIMES_CMAKE_ARGS=-DCMAKE_INSTALL_RPATH=#{rpath}"
      args << "-DDEFAULT_SYSROOT=#{sdk}" if sdk
    end

    if OS.linux?
      args << "-DLLVM_ENABLE_ZLIB=OFF"
      args << "-DLLVM_ENABLE_LIBXML2=OFF"
      args << "-DLLVM_ENABLE_TERMINFO=OFF"
      args << "-DHAVE_HISTEDIT_H=OFF"
      args << "-DHAVE_LIBEDIT=OFF"
      args << "-DLLVM_ENABLE_LIBCXX=OFF"
      args << "-DCLANG_DEFAULT_CXX_STDLIB=libstdc++"
      # Enable llvm gold plugin for LTO
      args << "-DLLVM_BINUTILS_INCDIR=#{Formula["binutils"].opt_include}"
      runtime_args = %w[
        -DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=OFF
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON
      ]
      args << "-DRUNTIMES_CMAKE_ARGS=#{runtime_args.join(";")}"
    end

    cflags = ENV.cflags&.split || []
    cxxflags = ENV.cxxflags&.split || []

    # The later stage builds avoid the shims, and the build
    # will target Penryn unless otherwise specified
    if Hardware::CPU.intel?
      cflags << "-march=#{Hardware.oldest_cpu}"
      cxxflags << "-march=#{Hardware.oldest_cpu}"
    end

    begin
      Timeout.timeout(19200) do # 5 hours, 20 minutes
        # First, build an instrumented stage2 compiler using Homebrew clang
        llvmpath = buildpath/"llvm"
        mkdir llvmpath/"stage2" do
          # LLVM Profile runs out of static counters
          # https://reviews.llvm.org/D92669, https://reviews.llvm.org/D93281
          # Without this, the build produces many warnings of the form
          # LLVM Profile Warning: Unable to track new values: Running out of static counters.
          instrumented_cflags = cflags + ["-Xclang -mllvm -Xclang -vp-counters-per-site=6"]
          instrumented_cxxflags = cxxflags + ["-Xclang -mllvm -Xclang -vp-counters-per-site=6"]
          llvm = Formula["llvm"]

          system "cmake", "-G", "Unix Makefiles", "..",
                          "-DCMAKE_C_COMPILER=#{llvm.opt_bin}/clang",
                          "-DCMAKE_CXX_COMPILER=#{llvm.opt_bin}/clang++",
                          "-DLLVM_BUILD_INSTRUMENTED=IR",
                          "-DLLVM_BUILD_RUNTIME=NO",
                          "-DLLVM_PROFILE_DATA_DIR=#{var}/llvm/profiles",
                          "-DCMAKE_C_FLAGS=#{instrumented_cflags.join(" ")}",
                          "-DCMAKE_CXX_FLAGS=#{instrumented_cxxflags.join(" ")}",
                          *args, *std_cmake_args
          system "cmake", "--build", ".", "--target", "clang", "lld"

          # We run some `check-*` targets to increase profiling
          # coverage. These do not need to succeed.
          begin
            system "cmake", "--build", ".", "--target", "check-clang", "check-llvm", "--", "--keep-going"
          rescue RuntimeError
            nil
          end

          system "cmake", "--build", ".", "--target", "install"
        end

        # Our just-built Clang needs a little help finding C++ headers,
        # since we don't build libc++, and the atomic and type_traits
        # headers are not in the SDK on macOS versions before Big Sur.
        if OS.mac?
          if MacOS.version <= :catalina && sdk
            toolchain_path = if MacOS::CLT.installed?
              MacOS::CLT::PKG_PATH
            else
              MacOS::Xcode.toolchain_path
            end

            cxxflags << "-isystem#{toolchain_path}/usr/include/c++/v1"
            cxxflags << "-isystem#{toolchain_path}/usr/include"
            cxxflags << "-isystem#{sdk}/usr/include"
          end
        end

        args << "-DCMAKE_C_FLAGS=#{cflags.join(" ")}" unless cflags.empty?
        args << "-DCMAKE_CXX_FLAGS=#{cxxflags.join(" ")}" unless cxxflags.empty?

        # Then, generate the profile data
        mkdir llvmpath/"stage2-profdata" do
          system "cmake", "-G", "Unix Makefiles", "..",
                          "-DCMAKE_C_COMPILER=#{bin}/clang",
                          "-DCMAKE_CXX_COMPILER=#{bin}/clang++",
                          *args, *std_cmake_args

          # This build is for profiling, so it is safe to ignore errors.
          # We pass `--keep-going` to `make` to ignore the error that requires
          # deparallelisation on ARM. (See llvm.rb.)
          begin
            system "cmake", "--build", ".", "--", "--keep-going"
          rescue RuntimeError
            nil
          end
        end
      end
    rescue Timeout::Error
      ohai "The build timed out."
    end

    # Finally, merge the generated profile data
    pkgshare.mkpath
    system "llvm-profdata",
           "merge",
           "-output=#{pkgshare}/pgo_profile.prof",
           *Dir[var/"llvm/profiles/*.profraw"]
  end

  def caveats
    s = ""
    on_macos do
      sdk = MacOS.sdk_path_if_needed
      toolchain_path = if MacOS::CLT.installed?
        MacOS::CLT::PKG_PATH
      else
        MacOS::Xcode.toolchain_path
      end

      if MacOS.version <= :catalina && sdk
        s += <<~EOS
          This formula does not include libc++ and is not configured to find your
          system C++ headers. To compile C++ code, you will need to pass
            -isystem#{toolchain_path}/usr/include/c++/v1
          to clang++.
        EOS
      end
    end

    s += <<~EOS
      The generated profile data is stored in

        #{opt_pkgshare}/profiles

      Use this profile data with Homebrew LLVM to build an optimised compiler for your application.
    EOS

    s
  end

  test do
    assert_predicate pkgshare/"pgo_profile.prof", :exist?, "Profile data not generated"
  end
end
