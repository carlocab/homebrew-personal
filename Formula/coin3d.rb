class Coin3d < Formula
  desc "Open Inventor 2.1 API implementation (Coin) with Python bindings (Pivy)"
  homepage "https://coin3d.github.io/"
  license all_of: ["BSD-3-Clause", "ISC"]

  stable do
    url "https://github.com/coin3d/coin/archive/Coin-4.0.0.tar.gz"
    sha256 "b00d2a8e9d962397cf9bf0d9baa81bcecfbd16eef675a98c792f5cf49eb6e805"

    resource "pivy" do
      url "https://github.com/coin3d/pivy/archive/0.6.6.a0.tar.gz"
      sha256 "f9ea3cf9549d71c68cbc0f2df6c23616c2f1a9132151545db5506c0bd7348c9a"
    end
  end

  livecheck do
    url :stable
    regex(/^Coin-(\d+\.\d+\.\d+)$/i)
  end

  head do
    url "https://github.com/coin3d/coin.git"

    resource "pivy" do
      url "https://github.com/coin3d/pivy.git"
    end
  end

  depends_on "cmake" => :build
  depends_on "doxygen" => :build
  depends_on "ninja" => :build
  depends_on "swig" => :build
  depends_on "boost"
  depends_on "pyside"
  depends_on "python@3.9"

  def install
    # Create an empty directory for cpack to make the build system
    # happy. This is a workaround for a build issue on upstream that
    # was fixed by commit be8e3d57aeb5b4df6abb52c5fa88666d48e7d7a0 but
    # hasn't made it to a release yet.
    mkdir "cpack.d" do
      touch "CMakeLists.txt"
    end

    mkdir "cmakebuild" do
      args = std_cmake_args + %w[
        -GNinja
        -DCOIN_BUILD_MAC_FRAMEWORK=OFF
        -DCOIN_BUILD_DOCUMENTATION=ON
        -DCOIN_BUILD_TESTS=OFF
      ]

      system "cmake", "..", *args
      system "ninja", "install"
    end

    resource("pivy").stage do
      args = std_cmake_args + %W[
        -GNinja
        -DCMAKE_PREFIX_PATH=#{prefix}
        -DPython_EXECUTABLE=#{Formula["python@3.9"].opt_bin}/python3
      ]
      mkdir "build" do
        system "cmake", "..", *args
        system "ninja", "install"
      end
    end
  end

  test do
    (testpath/"test.cpp").write <<~EOS
      #include <Inventor/SoDB.h>
      int main() {
        SoDB::init();
        SoDB::cleanup();
        return 0;
      }
    EOS
    system ENV.cc, "test.cpp", "-L#{lib}", "-lCoin", "-Wl,-framework,OpenGL", \
           "-o", "test"
    system "./test"

    system Formula["python@3.9"].opt_bin/"python3", "-c", <<~EOS
      from pivy.sogui import SoGui
      assert SoGui.init("test") is not None
    EOS
  end
end
