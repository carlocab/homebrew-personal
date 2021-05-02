class Julia < Formula
  desc "Fast, Dynamic Programming Language"
  homepage "https://julialang.org/"
  license all_of: ["MIT", "BSD-3-Clause", "Apache-2.0", "BSL-1.0"]
  head "https://github.com/JuliaLang/julia.git"

  stable do
    url "https://github.com/JuliaLang/julia/releases/download/v1.6.1/julia-1.6.1.tar.gz"
    sha256 "366b8090bd9b2f7817ce132170d569dfa3435d590a1fa5c3e2a75786bd5cdfd5"

    # Allow flisp to be built against system utf8proc
    # https://github.com/JuliaLang/julia/pull/37723
    patch do
      url "https://github.com/JuliaLang/julia/commit/ba653ecb1c81f1465505c2cea38b4f8149dd20b3.patch?full_index=1"
      sha256 "e626ee968e2ce8207c816f39ef9967ab0b5f50cad08a46b1df15d7bf230093cb"
    end
  end

  bottle do
    root_url "https://github.com/carlocab/homebrew-personal/releases/download/julia-1.6.1"
    sha256 big_sur:  "e87a59c46d5194bdf663bdff9b541b16bb96ed7e8754cb607b2c58c637a55c0d"
    sha256 catalina: "d2617e5a50e9beadc8f769bcbc20d220c2955374c86669c4a6ba576077ba2ba8"
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
      USE_SYSTEM_ZLIB=1
      USE_SYSTEM_P7ZIP=1
      LIBBLAS=-lopenblas
      LIBBLASNAME=libopenblas
      LIBLAPACK=-lopenblas
      LIBLAPACKNAME=libopenblas
      USE_BLAS64=0
      PYTHON=python3
    ]
    args << "USE_SYSTEM_LIBUNWIND=1" if build.head?
    args << "TAGGED_RELEASE_BANNER=Built by #{tap.user}"

    gcc = Formula["gcc"]
    gcc_ver = gcc.any_installed_version.major
    on_macos do
      deps.map(&:to_formula).select(&:keg_only?).map(&:opt_lib).each do |lib|
        ENV.append "LDFLAGS", "-Wl,-rpath,#{lib}"
      end
      ENV.append "LDFLAGS", "-Wl,-rpath,#{gcc.opt_lib}/gcc/#{gcc_ver}"
      # List these two last, since we want keg-only libraries to be found first
      ENV.append "LDFLAGS", "-Wl,-rpath,#{HOMEBREW_PREFIX}/lib"
      ENV.append "LDFLAGS", "-Wl,-rpath,/usr/lib"
    end

    inreplace "Make.inc" do |s|
      s.change_make_var! "LOCALBASE", HOMEBREW_PREFIX
    end

    system "make", *args, "install"

    # Create copies of the necessary gcc libraries in `buildpath/"usr/lib"`
    system "make", "clean"
    system "make", "-C", "deps", "USE_SYSTEM_CSL=1", "install-csl"
    # Install gcc library symlinks where Julia expects them
    (gcc.opt_lib/"gcc/#{gcc_ver}").glob(shared_library("*")) do |so|
      next unless (buildpath/"usr/lib"/so.basename).exist?

      # Use `ln_sf` instead of `install_symlink` to avoid referencing
      # gcc's full version and revision number in the symlink path
      ln_sf "../../../../../opt/gcc/lib/gcc/#{gcc_ver}/#{so.basename}", lib/"julia"
    end

    # Julia looks for libopenblas as libopenblas64_
    (lib/"julia").install_symlink shared_library("libopenblas") => shared_library("libopenblas64_")

    # Remove library versions from MbedTLS_jll
    file = pkgshare/"stdlib/v#{version.major_minor}/MbedTLS_jll/src/MbedTLS_jll.jl"
    inreplace file, %r{@rpath/lib(\w+)(\.\d+)*\.dylib}, "@rpath/lib\\1.dylib"
    inreplace file, /lib(\w+)\.so(\.\d+)*/, "lib\\1.so"

    # Julia looks for a CA Cert in pkgshare, so we provide one there
    pkgshare.install_symlink Formula["openssl@1.1"].pkgetc/"cert.pem"
  end

  test do
    assert_equal "4", shell_output("#{bin}/julia -E '2 + 2'").chomp
    system "julia", "-e", 'Base.runtests("core")'
    system "julia", "-e", 'Base.runtests("Zlib_jll")'
  end
end
