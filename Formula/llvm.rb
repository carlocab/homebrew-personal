class Llvm < Formula
  desc "Next-gen compiler infrastructure"
  homepage "https://llvm.org/"
  url "https://github.com/llvm/llvm-project/releases/download/llvmorg-12.0.0/llvm-project-12.0.0.src.tar.xz"
  sha256 "9ed1688943a4402d7c904cc4515798cdb20080066efa010fe7e1f2551b423628"
  # The LLVM Project is under the Apache License v2.0 with LLVM Exceptions
  license "Apache-2.0" => { with: "LLVM-exception" }
  head "https://github.com/llvm/llvm-project.git", branch: "main"

  livecheck do
    url :homepage
    regex(/LLVM (\d+\.\d+\.\d+)/i)
  end

  # Clang cannot find system headers if Xcode CLT is not installed
  pour_bottle? only_if: :clt_installed

  # https://llvm.org/docs/GettingStarted.html#requirement
  # We intentionally use Make instead of Ninja.
  # See: Homebrew/homebrew-core/issues/35513
  depends_on "cmake" => :build
  depends_on "swig" => :build
  depends_on "python@3.9"

  uses_from_macos "libedit"
  uses_from_macos "libffi", since: :catalina
  uses_from_macos "libxml2"
  uses_from_macos "ncurses"
  uses_from_macos "zlib"

  on_linux do
    depends_on "pkg-config" => :build
    depends_on "binutils" # needed for gold
    depends_on "libelf" # openmp requires <gelf.h>
  end

  def install
    projects = %w[
      clang
      clang-tools-extra
      lld
      lldb
      openmp
      polly
      mlir
    ]
    runtimes = %w[
      compiler-rt
      libcxx
      libcxxabi
      libunwind
    ]

    py_ver = Language::Python.major_minor_version("python3")
    site_packages = Language::Python.site_packages("python3").delete_prefix("lib/")

    # Apple's libstdc++ is too old to build LLVM
    ENV.libcxx if ENV.compiler == :clang

    # compiler-rt has some iOS simulator features that require i386 symbols
    # I'm assuming the rest of clang needs support too for 32-bit compilation
    # to work correctly, but if not, perhaps universal binaries could be
    # limited to compiler-rt. llvm makes this somewhat easier because compiler-rt
    # can almost be treated as an entirely different build from llvm.
    ENV.permit_arch_flags

    # we install the lldb Python module into libexec to prevent users from
    # accidentally importing it with a non-Homebrew Python or a Homebrew Python
    # in a non-default prefix. See https://lldb.llvm.org/resources/caveats.html
    args = %W[
      -DLLVM_ENABLE_PROJECTS=#{projects.join(";")}
      -DLLVM_ENABLE_RUNTIMES=#{runtimes.join(";")}
      -DLLVM_POLLY_LINK_INTO_TOOLS=ON
      -DLLVM_BUILD_EXTERNAL_COMPILER_RT=ON
      -DLLVM_LINK_LLVM_DYLIB=ON
      -DLLVM_ENABLE_EH=ON
      -DLLVM_ENABLE_FFI=ON
      -DLLVM_ENABLE_RTTI=ON
      -DLLVM_INCLUDE_DOCS=OFF
      -DLLVM_INCLUDE_TESTS=OFF
      -DLLVM_INSTALL_UTILS=ON
      -DLLVM_ENABLE_Z3_SOLVER=OFF
      -DLLVM_OPTIMIZED_TABLEGEN=ON
      -DLLVM_TARGETS_TO_BUILD=all
      -DLLDB_USE_SYSTEM_DEBUGSERVER=ON
      -DLLDB_ENABLE_PYTHON=ON
      -DLLDB_ENABLE_LUA=OFF
      -DLLDB_ENABLE_LZMA=ON
      -DLLDB_PYTHON_RELATIVE_PATH=libexec/#{site_packages}
      -DLIBOMP_INSTALL_ALIASES=OFF
      -DCLANG_PYTHON_BINDINGS_VERSIONS=#{py_ver}
      -DPACKAGE_VENDOR=#{tap.user}
      -DBUG_REPORT_URL=#{tap.issues_url}
    ]

    if MacOS.version >= :catalina
      args << "-DFFI_INCLUDE_DIR=#{MacOS.sdk_path}/usr/include/ffi"
      args << "-DFFI_LIBRARY_DIR=#{MacOS.sdk_path}/usr/lib"
    else
      args << "-DFFI_INCLUDE_DIR=#{Formula["libffi"].opt_include}"
      args << "-DFFI_LIBRARY_DIR=#{Formula["libffi"].opt_lib}"
    end

    sdk = MacOS.sdk_path_if_needed
    on_macos do
      args << "-DLLVM_ENABLE_LTO=ON"
      args << "-DLLVM_BUILD_LLVM_C_DYLIB=ON"
      args << "-DLLVM_ENABLE_LIBCXX=ON"
      args << "-DLLVM_CREATE_XCODE_TOOLCHAIN=#{MacOS::Xcode.installed? ? "ON" : "OFF"}"
      args << "-DRUNTIMES_CMAKE_ARGS=-DCMAKE_INSTALL_RPATH=#{rpath}"
      args << "-DDEFAULT_SYSROOT=#{sdk}" if sdk
    end

    on_linux do
      args << "-DLLVM_ENABLE_LIBCXX=OFF"
      args << "-DLLVM_CREATE_XCODE_TOOLCHAIN=OFF"
      args << "-DCLANG_DEFAULT_CXX_STDLIB=libstdc++"
      # Enable llvm gold plugin for LTO
      args << "-DLLVM_BINUTILS_INCDIR=#{Formula["binutils"].opt_include}"
    end

    llvmpath = buildpath/"llvm"
    # We build LLVM a few times first for optimisations. See
    # https://github.com/Homebrew/homebrew-core/issues/77975

    # PGO build adapted from:
    # https://llvm.org/docs/HowToBuildWithPGO.html#building-clang-with-pgo
    # https://github.com/llvm/llvm-project/blob/33ba8bd2/llvm/utils/collect_and_build_with_pgo.py
    # https://github.com/facebookincubator/BOLT/blob/01f471e7/docs/OptimizingClang.md
    if build.stable?
      extra_args = ["-DLLVM_TARGETS_TO_BUILD=#{Hardware::CPU.intel? ? "X86" : "AArch64"}"]
      on_macos do
        extra_args << "-DLLVM_ENABLE_LIBCXX=ON"
        extra_args << "-DCMAKE_C_FLAGS=-rtlib=compiler-rt"
        extra_args << "-DCMAKE_CXX_FLAGS=-rtlib=compiler-rt"

        if sdk
          extra_args << "-DDEFAULT_SYSROOT=#{sdk}"
          extra_args << "-DOSX_SYSROOT=#{sdk}"
          extra_args << "-DCMAKE_SYSROOT=#{sdk}"
        end
      end

      # First, build a stage1 compiler. It might be possible to skip this step on macOS
      # and use system Clang instead, but this stage does not take too long, and we want
      # to avoid incompatibilities from generating profile data with a newer Clang than
      # the one we consume the data with.
      mkdir llvmpath/"stage1" do
        system "cmake", "-G", "Unix Makefiles", "..",
                        "-DLLVM_ENABLE_PROJECTS=clang;compiler-rt;lld",
                        *extra_args, *std_cmake_args
        system "cmake", "--build", ".", "--target", "clang", "llvm-profdata", "profile"
        on_macos { system "cmake", "--build", ".", "--target", "LTO", "llvm-libtool-darwin" }
      end

      # Next, build an instrumented stage2 compiler
      mkdir llvmpath/"stage2" do
        system "cmake", "-G", "Unix Makefiles", "..",
                        "-DCMAKE_C_COMPILER=#{llvmpath}/stage1/bin/clang",
                        "-DCMAKE_CXX_COMPILER=#{llvmpath}/stage1/bin/clang++",
                        "-DLLVM_ENABLE_PROJECTS=clang;compiler-rt;lld",
                        "-DLLVM_BUILD_INSTRUMENTED=IR",
                        "-DLLVM_BUILD_RUNTIME=NO",
                        *extra_args, *std_cmake_args
        system "cmake", "--build", ".", "--target", "clang", "lld"

        # We run some `check-*` targets to increase profiling
        # coverage. These do not need to succeed.
        begin
          system "cmake", "--build", ".", "--target", "check-clang", "check-llvm", "--", "--keep-going"
        rescue RuntimeError
          nil
        end
      end

      # Then, generate the profile data
      mkdir llvmpath/"stage2-profdata" do
        system "cmake", "-G", "Unix Makefiles", "..",
                        "-DCMAKE_C_COMPILER=#{llvmpath}/stage2/bin/clang",
                        "-DCMAKE_CXX_COMPILER=#{llvmpath}/stage2/bin/clang++",
                        "-DLLVM_ENABLE_PROJECTS=#{projects.join(";")};#{runtimes.join(";")}",
                        *extra_args, *std_cmake_args

        # This build is for profiling, so it is safe to ignore errors.
        # We pass `--keep-going` to `make` to ignore the error that requires
        # deparallelisation on ARM. (See below.)
        begin
          system "cmake", "--build", ".", "--", "--keep-going"
        rescue RuntimeError
          nil
        end
      end

      # Merge the generated profile data
      profpath = llvmpath/"stage2/profiles"
      system llvmpath/"stage1/bin/llvm-profdata",
             "merge",
             "-output=#{profpath}/pgo_profile.prof",
             *Dir[profpath/"*.profraw"]

      # Make sure to build with our profiled compiler and use the profile data
      args << "-DCMAKE_C_COMPILER=#{llvmpath}/stage1/bin/clang"
      args << "-DCMAKE_CXX_COMPILER=#{llvmpath}/stage1/bin/clang++"
      args << "-DLLVM_PROFDATA_FILE=#{profpath}/pgo_profile.prof"
      args << "-DCMAKE_C_FLAGS=-Wno-backend-plugin -rtlib=compiler-rt"
      args << "-DCMAKE_CXX_FLAGS=-Wno-backend-plugin -rtlib=compiler-rt"
      on_macos { args << "-DCMAKE_LIBTOOL=#{llvmpath}/stage1/bin/llvm-libtool-darwin" }
    end

    # Now, we can build.
    mkdir llvmpath/"build" do
      system "cmake", "-G", "Unix Makefiles", "..", *(std_cmake_args + args)
      # Workaround for CMake Error: failed to create symbolic link
      ENV.deparallelize if Hardware::CPU.arm?
      system "cmake", "--build", "."
      system "cmake", "--build", ".", "--target", "install"
      system "cmake", "--build", ".", "--target", "install-xcode-toolchain" if MacOS::Xcode.installed?
    end

    on_macos do
      # Install versioned symlink, or else `llvm-config` doesn't work properly
      lib.install_symlink "libLLVM.dylib" => "libLLVM-#{version.major}.dylib" unless build.head?
    end

    # Install LLVM Python bindings
    # Clang Python bindings are installed by CMake
    (lib/site_packages).install llvmpath/"bindings/python/llvm"

    # Install Emacs modes
    elisp.install Dir[llvmpath/"utils/emacs/*.el"] + Dir[share/"clang/*.el"]
  end

  def caveats
    <<~EOS
      To use the bundled libc++ please add the following LDFLAGS:
        LDFLAGS="-L#{opt_lib} -Wl,-rpath,#{opt_lib}"
    EOS
  end

  test do
    assert_equal prefix.to_s, shell_output("#{bin}/llvm-config --prefix").chomp
    assert_equal "-lLLVM-#{version.major}", shell_output("#{bin}/llvm-config --libs").chomp
    assert_equal (lib/shared_library("libLLVM-#{version.major}")).to_s,
                 shell_output("#{bin}/llvm-config --libfiles").chomp

    (testpath/"omptest.c").write <<~EOS
      #include <stdlib.h>
      #include <stdio.h>
      #include <omp.h>
      int main() {
          #pragma omp parallel num_threads(4)
          {
            printf("Hello from thread %d, nthreads %d\\n", omp_get_thread_num(), omp_get_num_threads());
          }
          return EXIT_SUCCESS;
      }
    EOS

    clean_version = version.to_s[/(\d+\.?)+/]

    system "#{bin}/clang", "-L#{lib}", "-fopenmp", "-nobuiltininc",
                           "-I#{lib}/clang/#{clean_version}/include",
                           "omptest.c", "-o", "omptest"
    testresult = shell_output("./omptest")

    sorted_testresult = testresult.split("\n").sort.join("\n")
    expected_result = <<~EOS
      Hello from thread 0, nthreads 4
      Hello from thread 1, nthreads 4
      Hello from thread 2, nthreads 4
      Hello from thread 3, nthreads 4
    EOS
    assert_equal expected_result.strip, sorted_testresult.strip

    (testpath/"test.c").write <<~EOS
      #include <stdio.h>
      int main()
      {
        printf("Hello World!\\n");
        return 0;
      }
    EOS

    (testpath/"test.cpp").write <<~EOS
      #include <iostream>
      int main()
      {
        std::cout << "Hello World!" << std::endl;
        return 0;
      }
    EOS

    # Testing default toolchain and SDK location.
    system "#{bin}/clang++", "-v",
           "-std=c++11", "test.cpp", "-o", "test++"
    on_macos { assert_includes MachO::Tools.dylibs("test++"), "/usr/lib/libc++.1.dylib" }
    assert_equal "Hello World!", shell_output("./test++").chomp
    system "#{bin}/clang", "-v", "test.c", "-o", "test"
    assert_equal "Hello World!", shell_output("./test").chomp

    # Testing Command Line Tools
    if MacOS::CLT.installed?
      toolchain_path = "/Library/Developer/CommandLineTools"
      system "#{bin}/clang++", "-v",
             "-isysroot", MacOS::CLT.sdk_path,
             "-isystem", "#{toolchain_path}/usr/include/c++/v1",
             "-isystem", "#{toolchain_path}/usr/include",
             "-isystem", "#{MacOS::CLT.sdk_path}/usr/include",
             "-std=c++11", "test.cpp", "-o", "testCLT++"
      assert_includes MachO::Tools.dylibs("testCLT++"), "/usr/lib/libc++.1.dylib"
      assert_equal "Hello World!", shell_output("./testCLT++").chomp
      system "#{bin}/clang", "-v", "test.c", "-o", "testCLT"
      assert_equal "Hello World!", shell_output("./testCLT").chomp
    end

    # Testing Xcode
    if MacOS::Xcode.installed?
      system "#{bin}/clang++", "-v",
             "-isysroot", MacOS::Xcode.sdk_path,
             "-isystem", "#{MacOS::Xcode.toolchain_path}/usr/include/c++/v1",
             "-isystem", "#{MacOS::Xcode.toolchain_path}/usr/include",
             "-isystem", "#{MacOS::Xcode.sdk_path}/usr/include",
             "-std=c++11", "test.cpp", "-o", "testXC++"
      assert_includes MachO::Tools.dylibs("testXC++"), "/usr/lib/libc++.1.dylib"
      assert_equal "Hello World!", shell_output("./testXC++").chomp
      system "#{bin}/clang", "-v",
             "-isysroot", MacOS.sdk_path,
             "test.c", "-o", "testXC"
      assert_equal "Hello World!", shell_output("./testXC").chomp
    end

    # link against installed libc++
    # related to https://github.com/Homebrew/legacy-homebrew/issues/47149
    system "#{bin}/clang++", "-v",
           "-isystem", "#{opt_include}/c++/v1",
           "-std=c++11", "-stdlib=libc++", "test.cpp", "-o", "testlibc++",
           "-L#{opt_lib}", "-Wl,-rpath,#{opt_lib}"
    on_macos { assert_includes MachO::Tools.dylibs("testlibc++"), "#{opt_lib}/libc++.1.dylib" }
    assert_equal "Hello World!", shell_output("./testlibc++").chomp

    # Testing mlir
    (testpath/"test.mlir").write <<~EOS
      func @bad_branch() {
        br ^missing  // expected-error {{reference to an undefined block}}
      }
    EOS
    system "#{bin}/mlir-opt", "--verify-diagnostics", "test.mlir"

    (testpath/"scanbuildtest.cpp").write <<~EOS
      #include <iostream>
      int main() {
        int *i = new int;
        *i = 1;
        delete i;
        std::cout << *i << std::endl;
        return 0;
      }
    EOS
    assert_includes shell_output("#{bin}/scan-build clang++ scanbuildtest.cpp 2>&1"),
      "warning: Use of memory after it is freed"

    (testpath/"clangformattest.c").write <<~EOS
      int    main() {
          printf("Hello world!"); }
    EOS
    assert_equal "int main() { printf(\"Hello world!\"); }\n",
      shell_output("#{bin}/clang-format -style=google clangformattest.c")

    # Ensure LLVM did not regress output of `llvm-config --system-libs` which for a time
    # was known to output incorrect linker flags; e.g., `-llibxml2.tbd` instead of `-lxml2`.
    # On the other hand, note that a fully qualified path to `dylib` or `tbd` is OK, e.g.,
    # `/usr/local/lib/libxml2.tbd` or `/usr/local/lib/libxml2.dylib`.
    shell_output("#{bin}/llvm-config --system-libs").chomp.strip.split.each do |lib|
      if lib.start_with?("-l")
        assert !lib.end_with?(".tbd"), "expected abs path when lib reported as .tbd"
        assert !lib.end_with?(".dylib"), "expected abs path when lib reported as .dylib"
      else
        p = Pathname.new(lib)
        if p.extname == ".tbd" || p.extname == ".dylib"
          assert p.absolute?, "expected abs path when lib reported as .tbd or .dylib"
        end
      end
    end
  end
end
