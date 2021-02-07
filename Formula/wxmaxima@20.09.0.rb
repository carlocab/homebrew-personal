class WxmaximaAT20090 < Formula
  desc "Cross platform GUI for Maxima"
  homepage "https://wxmaxima-developers.github.io/wxmaxima/"
  url "https://github.com/wxMaxima-developers/wxmaxima/archive/Version-20.09.0.tar.gz"
  sha256 "a2ba6797642c7efa96c5dbb6249134a0ace246ebd390e42f7c227fa94609ef27"
  license "GPL-2.0-or-later"
  head "https://github.com/wxMaxima-developers/wxmaxima.git"

  bottle do
    root_url "https://github.com/carlocab/homebrew-personal/releases/download/wxmaxima@20.09.0-20.09.0"
    sha256 big_sur:  "74b3d908ce177f98a790ab5b3564fa65bc267dd0ffddf984d58fae2460d60ca4"
    sha256 catalina: "fbb4dfa279313f95e196c10e6d9c82895d4d3b52d6c6030c00d6d3ff26922b23"
  end

  keg_only :versioned_formula

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
      system "ninja"
      system "ninja", "install"
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
