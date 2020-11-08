class LessNcurses < Formula
  desc "Pager program similar to more"
  homepage "http://www.greenwoodsoftware.com/less/index.html"
  url "http://www.greenwoodsoftware.com/less/less-563.tar.gz"
  sha256 "ce5b6d2b9fc4442d7a07c93ab128d2dff2ce09a1d4f2d055b95cf28dd0dc9a9a"
  license "GPL-3.0-or-later"

  livecheck do
    url :homepage
    regex(/less[._-]v?(\d+).+?released.+?general use/i)
  end

  depends_on "ncurses"
  depends_on "pcre2"

  conflicts_with "less", because: "less@563 and less both install less binaries"

  if MacOS.version >= :catalina
    depends_on "gcc" => :build
    fails_with :clang do
      build 1200
      cause "Cannot find terminal libraries - configure failed"
    end
  end

  def install
    system "./configure", "--prefix=#{prefix}", "--with-regex=pcre2", "--mandir=#{man}"
    system "make", "install"
  end

  test do
    system "#{bin}/lesskey", "-V"
  end
end
