class NeovimOpenresty < Formula
  desc "Ambitious Vim-fork focused on extensibility and agility"
  homepage "https://neovim.io/"
  url "https://github.com/neovim/neovim/archive/v0.4.4.tar.gz"
  sha256 "2f76aac59363677f37592e853ab2c06151cca8830d4b3fe4675b4a52d41fc42c"
  license "Apache-2.0"
  revision 1

  bottle do
    root_url "https://github.com/carlocab/homebrew-personal/releases/download/neovim-openresty-0.4.4_1"
    sha256 "bdc8313d4bb53339ff31662382819053ac747005be6352a5a796ca2a01d45400" => :big_sur
    sha256 "0bfadcbdca6eaab7399f48a2d74cc94e17e6d455b49f62c460d881c2f6fbcbc2" => :catalina
  end

  head do
    url "https://github.com/neovim/neovim.git"
    depends_on "tree-sitter"
  end

  keg_only "it is shadowed by the neovim formula"

  depends_on "cmake" => :build
  depends_on "luarocks" => :build
  depends_on "luv" => :build
  depends_on "pkg-config" => :build
  depends_on "gettext"
  depends_on "libtermkey"
  depends_on "libuv"
  depends_on "libvterm"
  depends_on "luajit-openresty"
  depends_on "msgpack"
  depends_on "unibilium"

  uses_from_macos "gperf" => :build
  uses_from_macos "unzip" => :build

  on_linux do
    depends_on "libnsl"
  end

  # Keep resources updated according to:
  # https://github.com/neovim/neovim/blob/v#{version}/third-party/CMakeLists.txt

  resource "mpack" do
    url "https://github.com/libmpack/libmpack-lua/releases/download/1.0.8/libmpack-lua-1.0.8.tar.gz"
    sha256 "ed6b1b4bbdb56f26241397c1e168a6b1672f284989303b150f7ea8d39d1bc9e9"
  end

  resource "lpeg" do
    url "https://luarocks.org/manifests/gvvaughan/lpeg-1.0.2-1.src.rock"
    sha256 "e0d0d687897f06588558168eeb1902ac41a11edd1b58f1aa61b99d0ea0abbfbc"
  end

  resource "inspect" do
    url "https://luarocks.org/manifests/kikito/inspect-3.1.1-0.src.rock"
    sha256 "ea1f347663cebb523e88622b1d6fe38126c79436da4dbf442674208aa14a8f4c"
  end

  def install
    resources.each do |r|
      r.stage(buildpath/"deps-build/build/src/#{r.name}")
    end

    ENV.prepend_path "LUA_PATH", "#{buildpath}/deps-build/share/lua/5.1/?.lua"
    ENV.prepend_path "LUA_CPATH", "#{buildpath}/deps-build/lib/lua/5.1/?.so"
    lua_path = "--lua-dir=#{Formula["luajit-openresty"].opt_prefix}"

    cmake_compiler_args = []
    on_macos do
      cmake_compiler_args << "-DCMAKE_C_COMPILER=/usr/bin/clang"
      cmake_compiler_args << "-DCMAKE_CXX_COMPILER=/usr/bin/clang++"
    end

    cd "deps-build" do
      %w[
        mpack/mpack-1.0.8-0.rockspec
        lpeg/lpeg-1.0.2-1.src.rock
        inspect/inspect-3.1.1-0.src.rock
      ].each do |rock|
        dir, rock = rock.split("/")
        cd "build/src/#{dir}" do
          output = Utils.safe_popen_read("luarocks", "unpack", lua_path, rock, "--tree=#{buildpath}/deps-build")
          unpack_dir = output.split("\n")[-2]
          cd unpack_dir do
            system "luarocks", "make", lua_path, "--tree=#{buildpath}/deps-build"
          end
        end
      end
    end

    mkdir "build" do
      cmake_args = std_cmake_args
      cmake_args += cmake_compiler_args
      cmake_args += %W[
        -DLIBLUV_INCLUDE_DIR=#{Formula["luv"].opt_include}
        -DLIBLUV_LIBRARY=#{Formula["luv"].opt_lib}/libluv_a.a
      ]
      system "cmake", "..", *cmake_args
      system "make", "install"
    end
  end

  test do
    (testpath/"test.txt").write("Hello World from Vim!!")
    system bin/"nvim", "--headless", "-i", "NONE", "-u", "NONE",
                       "+s/Vim/Neovim/g", "+wq", "test.txt"
    assert_equal "Hello World from Neovim!!", (testpath/"test.txt").read.chomp
  end
end
