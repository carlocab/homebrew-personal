class LessAT563 < Formula
  desc "Pager program similar to more"
  homepage "http://www.greenwoodsoftware.com/less/index.html"
  url "http://www.greenwoodsoftware.com/less/less-563.tar.gz"
  sha256 "ff165275859381a63f19135a8f1f6c5a194d53ec3187f94121ecd8ef0795fe3d"
  license "GPL-3.0-or-later"

  livecheck do
    url :homepage
    regex(/less[._-]v?(\d+).+?released.+?general use/i)
  end

  depends_on "pcre"
  depends_on "ncurses"
  depends_on "llvm" => :build

  conflicts_with "less", because: "because less@563 and less both install less binaries"

  def install
    ENV["CC"] = Formula["llvm"].opt_bin/"clang"
    ENV.append "LDFLAGS", "-L#{Formula["ncurses"].opt_lib}"
    ENV.append "LDFLAGS", "-L#{Formula["llvm"].opt_lib}"
    system "./configure", "--prefix=#{prefix}", "--with-regex=pcre", "--mandir=#{man}"
    system "make", "install"
  end

  test do
    system "#{bin}/lesskey", "-V"
  end
end
