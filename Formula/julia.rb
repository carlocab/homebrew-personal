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
    sha256 big_sur:  "89e1d35cc940061b7816a9613a86ed9b637489878eebe6c706c48ecc166a8d20"
    sha256 catalina: "acfa03e1d2089a3d269c3b68b8d9b7214061b26caae4a90de0f599ceb561b2b6"
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

  on_macos { patch :DATA }

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

    gcc = Formula["gcc"]
    gcc_ver = gcc.any_installed_version.major
    on_macos do
      ENV.append "LDFLAGS", "-Wl,-rpath,#{HOMEBREW_PREFIX}/lib"
      ENV.append "LDFLAGS", "-Wl,-rpath,#{gcc.opt_lib}/gcc/#{gcc_ver}"
      deps.map(&:to_formula).select(&:keg_only?).map(&:opt_lib).each do |lib|
        ENV.append "LDFLAGS", "-Wl,-rpath,#{lib}"
      end
    end

    inreplace "Make.inc" do |s|
      s.change_make_var! "LOCALBASE", HOMEBREW_PREFIX
    end

    # The Makefile tries to create this symlink but the way it does so is broken.
    (buildpath/"usr/lib/julia").install_symlink Formula["llvm"].opt_lib/shared_library("libLLVM")

    ENV.deparallelize
    system "make", *args, "install"

    system "make", "clean"
    system "make", "-C", "deps", "USE_SYSTEM_CSL=1", "install-csl"
    # Install gcc library symlinks where Julia expects them
    (gcc.opt_lib/"gcc/#{gcc_ver}").glob(shared_library("*")) do |so|
      next unless (buildpath/"usr/lib"/so.basename).exist?

      (lib/"julia").install_symlink so
    end

    # Julia looks for a CA Cert in pkgshare, so we provide one there
    pkgshare.install_symlink Formula["openssl@1.1"].pkgetc/"cert.pem"
  end

  test do
    assert_equal "4", shell_output("#{bin}/julia -E '2 + 2'").chomp
    system "julia", "-e", 'Base.runtests("core")'
  end
end

__END__
diff --git a/src/Makefile b/src/Makefile
index 0de23588bc..37838088c5 100644
--- a/src/Makefile
+++ b/src/Makefile
@@ -100,7 +100,7 @@ LLVM_CXXFLAGS := $(shell $(LLVM_CONFIG_HOST) --cxxflags)

 ifeq ($(JULIACODEGEN),LLVM)
 ifneq ($(USE_SYSTEM_LLVM),0)
-LLVMLINK += $(LLVM_LDFLAGS) $(shell $(LLVM_CONFIG_HOST) --libs --system-libs)
+LLVMLINK += $(LLVM_LDFLAGS) -lLLVM $(shell $(LLVM_CONFIG_HOST) --system-libs)
 # HACK: llvm-config doesn't correctly point to shared libs on all platforms
 #       https://github.com/JuliaLang/julia/issues/29981
 else
