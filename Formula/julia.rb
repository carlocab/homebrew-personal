class Julia < Formula
  desc "Fast, Dynamic Programming Language"
  homepage "https://julialang.org/"
  license all_of: ["MIT", "BSD-3-Clause", "Apache-2.0", "BSL-1.0"]
  head "https://github.com/JuliaLang/julia.git"

  stable do
    url "https://github.com/JuliaLang/julia/releases/download/v1.6.1/julia-1.6.1-full.tar.gz"
    sha256 "71d8e40611361370654e8934c407b2dec04944cf3917c5ecb6482d6b85ed767f"

    # Allow flisp to be built against system utf8proc
    # https://github.com/JuliaLang/julia/pull/37723
    patch do
      url "https://github.com/JuliaLang/julia/commit/ba653ecb1c81f1465505c2cea38b4f8149dd20b3.patch?full_index=1"
      sha256 "e626ee968e2ce8207c816f39ef9967ab0b5f50cad08a46b1df15d7bf230093cb"
    end
  end

  depends_on "python@3.9" => :build
  depends_on "curl"
  depends_on "gcc" # for gfortran
  depends_on "gmp"
  depends_on "libgit2"
  depends_on "libssh2"
  depends_on "llvm"
  depends_on "mbedtls"
  depends_on "mpfr"
  depends_on "nghttp2"
  depends_on "openblas"
  depends_on "openlibm"
  depends_on "p7zip"
  depends_on "pcre2"
  depends_on "suite-sparse"
  depends_on "utf8proc"

  uses_from_macos "perl" => :build
  uses_from_macos "zlib"

  on_linux do
    depends_on "patchelf" => :build
    depends_on "libunwind"
  end

  # Fix compilation with `USE_SYSTEM_LLVM=1`.
  # https://github.com/JuliaLang/julia/pull/40680
  patch do
    url "https://github.com/JuliaLang/julia/commit/867564835af58cb0755b31c2851ce85638ac466a.patch?full_index=1"
    sha256 "4852df7a0c7962c2450a5423de3724a027acdd87968a0d86748d0d6c0291ae39"
  end

  def install
    # Build documentation available at
    # https://github.com/JuliaLang/julia/blob/v#{version}/doc/build/build.md
    args = %W[
      VERBOSE=1
      USE_BINARYBUILDER=0
      prefix=#{prefix}
      USE_SYSTEM_CSL=1
      USE_SYSTEM_LLVM=1
      USE_SYSTEM_PCRE=1
      USE_SYSTEM_OPENLIBM=1
      USE_SYSTEM_BLAS=1
      USE_SYSTEM_LAPACK=1
      USE_SYSTEM_GMP=1
      USE_SYSTEM_MPFR=1
      USE_SYSTEM_SUITESPARSE=1
      USE_SYSTEM_UTF8PROC=1
      USE_SYSTEM_MBEDTLS=1
      USE_SYSTEM_LIBSSH2=1
      USE_SYSTEM_NGHTTP2=1
      USE_SYSTEM_CURL=1
      USE_SYSTEM_LIBGIT2=1
      USE_SYSTEM_PATCHELF=1
      USE_SYSTEM_ZLIB=1
      USE_SYSTEM_P7ZIP=1
      LIBBLAS=-lopenblas
      LIBBLASNAME=libopenblas
      LIBLAPACK=-lopenblas
      LIBLAPACKNAME=libopenblas
      USE_BLAS64=0
      PYTHON=python3
      MACOSX_VERSION_MIN=#{MacOS.version}
    ]
    on_macos { args << "USE_SYSTEM_LIBUNWIND=1" if build.head? }
    on_linux { args << "USE_SYSTEM_LIBUNWIND=1" }
    args << "TAGGED_RELEASE_BANNER=Built by #{tap.user}"

    gcc = Formula["gcc"]
    gcc_ver = gcc.any_installed_version.major
    gcclibdir = gcc.opt_lib/"gcc/#{gcc.any_installed_version.major}"

    ldflags = deps.map(&:to_formula).select(&:keg_only?).map(&:opt_lib).map do |libdir|
      "-Wl,-rpath,#{libdir}"
    end
    ldflags += %W[
      -Wl,-rpath,#{gcclibdir}
      -Wl,-rpath,#{HOMEBREW_PREFIX}/lib
      -Wl,-rpath,/usr/lib
    ]
    ENV.append "LDFLAGS", ldflags.join(" ")

    ENV.append "LDFLAGS", "-Wl,-rpath,#{opt_lib}"
    ENV.append "LDFLAGS", "-Wl,-rpath,#{opt_lib}/julia"

    inreplace "Make.inc" do |s|
      s.change_make_var! "LOCALBASE", HOMEBREW_PREFIX
    end

    # Install `libwhich` build tool first to avoid carrying RPATHs into final build
    system "make", "-C", "deps", "install-libwhich"
    ENV.remove "LDFLAGS", ldflags.join(" ")

    # Remove library versions from MbedTLS_jll, nghttp2_jll, and libLLVM_jll
    # https://git.archlinux.org/svntogit/community.git/tree/trunk/julia-hardcoded-libs.patch?h=packages/julia
    %w[MbedTLS nghttp2].each do |dep|
      (buildpath/"stdlib").glob("**/#{dep}_jll.jl") do |jll|
        inreplace jll, %r{@rpath/lib(\w+)(\.\d+)*\.dylib}, "@rpath/lib\\1.dylib"
        inreplace jll, /lib(\w+)\.so(\.\d+)*/, "lib\\1.so"
      end
    end
    inreplace (buildpath/"stdlib").glob("**/libLLVM_jll.jl"), /libLLVM-\d+jl\.so/, "libLLVM.so"

    # Make Julia use OpenSSL's CA cert
    (buildpath/"usr/share/julia").install_symlink Formula["openssl@1.1"].pkgetc/"cert.pem"

    system "make", *args, "install"

    # Create copies of the necessary gcc libraries in `buildpath/"usr/lib"`
    system "make", "-C", "deps", "USE_SYSTEM_CSL=1", "install-csl"
    # Install gcc library symlinks where Julia expects them
    (gcc.opt_lib/"gcc/#{gcc_ver}").glob(shared_library("*")) do |so|
      next unless (buildpath/"usr/lib"/so.basename).exist?

      # Use `ln_sf` instead of `install_symlink` to avoid referencing
      # gcc's full version and revision number in the symlink path
      ln_sf gcclibdir.relative_path_from(lib/"julia"), lib/"julia"
    end

    # Julia looks for libopenblas as libopenblas64_
    (lib/"julia").install_symlink shared_library("libopenblas") => shared_library("libopenblas64_")

    # Julia looks for a CA Cert in pkgshare, so we provide one there
    pkgshare.install_symlink Formula["openssl@1.1"].pkgetc/"cert.pem"
  end

  test do
    assert_equal "4", shell_output("#{bin}/julia -E '2 + 2'").chomp
    system bin/"julia", "-e", 'Base.runtests("core")'
    system bin/"julia", "-e", 'Base.runtests("Zlib_jll")'
    system bin/"julia", "-e", 'Base.runtests("OpenBLAS_jll")'
    system bin/"julia", "-e", 'Base.runtests("libLLVM_jll")'
  end
end
