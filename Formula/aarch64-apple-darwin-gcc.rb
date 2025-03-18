class Aarch64AppleDarwinGcc < Formula
  desc "GNU compiler collection for aarch64-apple-darwin"
  homepage "https://gcc.gnu.org"
  license "GPL-3.0-or-later" => { with: "GCC-exception-3.1" }

  stable do
    url "https://ftp.gnu.org/gnu/gcc/gcc-12.2.0/gcc-12.2.0.tar.xz"
    mirror "https://ftpmirror.gnu.org/gcc/gcc-12.2.0/gcc-12.2.0.tar.xz"
    sha256 "e549cf9cf3594a00e27b6589d4322d70e0720cdd213f39beb4181e06926230ff"

    # Branch from the Darwin maintainer of GCC, with a few generic fixes and
    # Apple Silicon support, located at https://github.com/iains/gcc-12-branch
    patch do
      url "https://raw.githubusercontent.com/Homebrew/formula-patches/1d184289/gcc/gcc-12.2.0-arm.diff"
      sha256 "a7843b5c6bf1401e40c20c72af69c8f6fc9754ae980bb4a5f0540220b3dcb62d"
    end
  end

  livecheck do
    formula "gcc"
  end

  depends_on "gmp"
  depends_on "isl"
  depends_on "libmpc"
  depends_on :macos
  depends_on "mpfr"
  depends_on "zstd"

  def target
    "aarch64-apple-darwin"
  end

  def install
    ["as", "ld"].each do |tool|
      script = "#{target}-#{tool}"
      (buildpath/script).write <<~SH
        #!/usr/bin/env sh
        exec /usr/bin/#{tool} -arch arm64 "$@"
      SH
      chmod "+x", script
      bin.install script
    end

    mkdir "#{target}-gcc-build" do
      system "../configure", "--target=#{target}",
                             "--prefix=#{prefix}",
                             "--infodir=#{info}/#{target}",
                             "--with-gmp=#{Formula["gmp"].opt_prefix}",
                             "--with-mpfr=#{Formula["mpfr"].opt_prefix}",
                             "--with-mpc=#{Formula["libmpc"].opt_prefix}",
                             "--with-isl=#{Formula["isl"].opt_prefix}",
                             "--with-zstd=#{Formula["zstd"].opt_prefix}",
                             "--with-as=#{bin/target}-as",
                             "--with-ld=#{bin/target}-ld",
                             "--with-sysroot=#{MacOS.sdk_path_if_needed}",
                             "--disable-nls",
                             "--enable-languages=c,c++"

      system "make", "all-gcc"
      system "make", "install-gcc"
      system "make", "all-target-libgcc"
      system "make", "install-target-libgcc"

      # FSF-related man pages may conflict with native gcc
      (share/"man/man7").rmtree
    end
  end

  test do
    (testpath/"test-c.c").write <<~EOS
      int main(void)
      {
        int i=0;
        while(i<10) i++;
        return i;
      }
    EOS
    system "#{bin}/#{target}-gcc", "-c", "-o", "test-c.o", "test-c.c"
    assert_match "arm64", shell_output("file test-c.o")
  end
end
