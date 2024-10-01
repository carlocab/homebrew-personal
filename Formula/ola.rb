class Ola < Formula
  include Language::Python::Shebang

  desc "Open Lighting Architecture for lighting control information"
  homepage "https://www.openlighting.org/ola/"
  url "https://github.com/OpenLightingProject/ola/releases/download/0.10.9/ola-0.10.9.tar.gz"
  sha256 "44073698c147fe641507398253c2e52ff8dc7eac8606cbf286c29f37939a4ebf"
  license all_of: ["GPL-2.0-or-later", "LGPL-2.1-or-later"]
  head "https://github.com/OpenLightingProject/ola.git", branch: "master"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkg-config" => :build
  depends_on "liblo"
  depends_on "libmicrohttpd"
  depends_on "libusb"
  depends_on "numpy"
  depends_on "protobuf"
  depends_on "python@3.11"

  uses_from_macos "bison" => :build
  uses_from_macos "flex" => :build

  def python3
    "python3.11"
  end

  def install
    # https://github.com/Homebrew/homebrew-core/pull/123791
    # remove when the above PR is merged
    ENV.append_to_cflags "-DNDEBUG"
    ENV.append "CXXFLAGS", "-std=gnu++17"

    args = %W[
      --disable-fatal-warnings
      --disable-silent-rules
      --disable-unittests
      --enable-python-libs
      --enable-rdm-tests
      --with-python_prefix=#{prefix}
      --with-python_exec_prefix=#{prefix}
    ]

    ENV["PYTHON"] = python3
    inreplace "configure", "gnu++11", "gnu++17"
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", *std_configure_args, *args
    system "make", "install"

    rewrite_shebang detected_python_shebang, *bin.children
  end

  test do
    system bin/"ola_plugin_state", "-h"
    system python3, "-c", "from ola.ClientWrapper import ClientWrapper"
  end
end
