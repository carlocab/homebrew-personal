class LessAT563 < Formula
  desc "Pager program similar to more"
  homepage "http://www.greenwoodsoftware.com/less/index.html"
  url "http://www.greenwoodsoftware.com/less/less-563.tar.gz"
  sha256 "ce5b6d2b9fc4442d7a07c93ab128d2dff2ce09a1d4f2d055b95cf28dd0dc9a9a"
  license "GPL-3.0-or-later"

  livecheck do
    url :homepage
    regex(/less[._-]v?(\d+).+?released.+?general use/i)
  end

  depends_on "llvm" => :build
  depends_on "ncurses"
  depends_on "pcre2"

  conflicts_with "less", because: "less@563 and less both install less binaries"

  def install
    ENV["CC"] = Formula["llvm"].opt_bin/"clang"
    ENV.append "LDFLAGS", "-L#{Formula["ncurses"].opt_lib}"
    ENV.append "LDFLAGS", "-L#{Formula["llvm"].opt_lib}"
    ENV.append "CPPFLAGS", "-I#{Formula["pcre2"].opt_include}"
    system "./configure", "--prefix=#{prefix}", "--with-regex=pcre2", "--mandir=#{man}"
    system "make", "install"
  end

  test do
    system "#{bin}/lesskey", "-V"
  end
end
