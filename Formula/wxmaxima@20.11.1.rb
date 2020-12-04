class WxmaximaAT20111 < Formula
  desc "Cross platform GUI for Maxima"
  homepage "https://wxmaxima-developers.github.io/wxmaxima/"
  url "https://github.com/wxMaxima-developers/wxmaxima/archive/Version-20.11.1.tar.gz"
  sha256 "b1c480d2658ef8483c495ba0d5f29cb14c11654fe49ef44d01508e2d94217a2b"
  license "GPL-2.0-or-later"
  head "https://github.com/wxMaxima-developers/wxmaxima.git"

  bottle do
    root_url "https://github.com/carlocab/homebrew-personal/releases/download/wxmaxima@20.11.1-20.11.1"
    sha256 "1af31860ece6571fcac1bd7debf30a7b3d5bac8baf6f980758a8e07f14acacd4" => :big_sur
    sha256 "097facb5aa79bc31862675dd1e29a92e49f2a0bf1e3723caf89db90abb6b93f2" => :catalina
  end

  depends_on "cmake" => :build
  depends_on "gettext" => :build
  depends_on "ninja" => :build
  depends_on "maxima"
  depends_on "wxmac"

  def install
    # en_US.UTF8 is not a valid locale for macOS
    # https://github.com/wxMaxima-developers/wxmaxima/issues/1402
    inreplace "src/StreamUtils.cpp", "en_US.UTF8", "en_US.UTF-8"

    mkdir "build-wxm" do
      system "cmake", "..", "-GNinja", *std_cmake_args
      system "cmake", "--build", "."
      system "cmake", "--build", ".", "--target", "install"
      prefix.install "src/wxMaxima.app"
    end

    bash_completion.install "data/wxmaxima"
    bin.write_exec_script "#{prefix}/wxMaxima.app/Contents/MacOS/wxmaxima"
  end

  def caveats
    <<~EOS
      When you start wxMaxima the first time, set the path to Maxima
      (e.g. #{HOMEBREW_PREFIX}/bin/maxima) in the Preferences.

      Enable gnuplot functionality by setting the following variables
      in ~/.maxima/maxima-init.mac:
        gnuplot_command:"#{HOMEBREW_PREFIX}/bin/gnuplot"$
        draw_command:"#{HOMEBREW_PREFIX}/bin/gnuplot"$
    EOS
  end

  test do
    assert_match "algebra", shell_output("#{bin}/wxmaxima --help 2>&1")
  end
end
