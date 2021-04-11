class ZeekLibcxx < Formula
  desc "Network security monitor"
  homepage "https://www.zeek.org"
  url "https://github.com/zeek/zeek.git",
      tag:      "v4.0.0",
      revision: "7b5263139e9909757c38dfca4c99abebf958df67"
  license "BSD-3-Clause"
  head "https://github.com/zeek/zeek.git"

  bottle do
    root_url "https://github.com/carlocab/homebrew-personal/releases/download/zeek-libcxx-4.0.0"
    sha256 big_sur:  "a5547a1e0e7fabef6164bd61bc79077668c9a6ea5b63b087aa1b544691e08bf0"
    sha256 catalina: "c6f9ce926457da02fe8de32d95a2a7b4f858fca32131e29c05b14de5e19684c2"
  end

  depends_on "bison" => :build
  depends_on "cmake" => :build
  depends_on "swig" => :build
  depends_on "caf"
  depends_on "geoip"
  depends_on "libmaxminddb"
  depends_on macos: :mojave
  depends_on "openssl@1.1"
  depends_on "python@3.9"

  uses_from_macos "flex"
  uses_from_macos "libpcap"
  uses_from_macos "zlib"

  resource "pcap-test" do
    url "https://raw.githubusercontent.com/zeek/zeek/59ed5c75f190d4401d30172b9297b3592dd72acf/testing/btest/Traces/http/get.trace"
    sha256 "48c8c3a3560a13ffb03d4eb0ed14143fb57350ced7d6874761a963a8091b1866"
  end

  def install
    ENV.libcxx
    mkdir "build" do
      system "cmake", "..", *std_cmake_args,
                      "-DBROKER_DISABLE_TESTS=on",
                      "-DBUILD_SHARED_LIBS=on",
                      "-DINSTALL_AUX_TOOLS=on",
                      "-DINSTALL_ZEEKCTL=on",
                      "-DUSE_GEOIP=on",
                      "-DCAF_ROOT=#{Formula["caf"].opt_prefix}",
                      "-DOPENSSL_ROOT_DIR=#{Formula["openssl@1.1"].opt_prefix}",
                      "-DZEEK_ETC_INSTALL_DIR=#{etc}",
                      "-DZEEK_LOCAL_STATE_DIR=#{var}"
      system "make", "install"
    end
  end

  test do
    assert_match "version #{version}", shell_output("#{bin}/zeek --version")
    assert_match "ARP packet analyzer", shell_output("#{bin}/zeek --print-plugins")
    resource("pcap-test").stage testpath
    assert shell_output("#{bin}/zeek -C -r get.trace && test -s conn.log && test -s http.log")
  end
end
