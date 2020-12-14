class Luabind < Formula
  desc "Library for bindings between C++ and Lua"
  homepage "https://github.com/luabind/luabind"
  url "https://downloads.sourceforge.net/project/luabind/luabind/0.9.1/luabind-0.9.1.tar.gz"
  sha256 "80de5e04918678dd8e6dac3b22a34b3247f74bf744c719bae21faaa49649aaae"
  license "MIT"

  livecheck do
    url :stable
  end

  depends_on "boost-build" => :build
  depends_on "boost"
  depends_on "lua@5.1"

  # boost 1.57 compatibility
  # https://github.com/Homebrew/homebrew/pull/33890#issuecomment-67723688
  # https://github.com/luabind/luabind/issues/27
  patch do
    url "https://gist.githubusercontent.com/tdsmith/e6d9d3559ec1d9284c0b/raw/4ac01936561ef9d7541cf8e78a230bebef1a8e10/luabind.diff"
    sha256 "f22a283752994e821922316a5ef3cbb16f7bbe15fc64d97c02325ed4aaa53985"
  end

  # patch Jamroot to perform lookup for shared objects with .dylib suffix
  patch do
    url "https://gist.githubusercontent.com/DennisOSRM/3728987/raw/052251fcdc23602770f6c543be9b3e12f0cac50a/Jamroot.diff"
    sha256 "bc06d76069d08af4dc55a102f963931a0247173a36ad0ae43e11d82b23f8d2b3"
  end

  # apply upstream commit to enable building with clang
  patch do
    url "https://github.com/luabind/luabind/commit/3044a9053ac50977684a75c4af42b2bddb853fad.patch?full_index=1"
    sha256 "0e213656165de17c2047e18ac451fa891355a7f58b2995b5b8e0d95c23acdb1c"
  end

  # include C header that is not pulled in automatically on OS X 10.9 anymore
  # submitted https://github.com/luabind/luabind/pull/20
  patch do
    url "https://gist.githubusercontent.com/DennisOSRM/a246514bf7d01631dda8/raw/0e83503dbf862ebfb6ac063338a6d7bca793f94d/object_rep.diff"
    sha256 "2fef524ac5e319d7092fbb28f6d4e3d3eccd6a570e7789a9b5b0c9a25e714523"
  end

  def install
    ENV["LUA_PATH"] = Formula["lua@5.1"].opt_prefix

    args = %w[release install]
    case ENV.compiler
    when :clang
      args << "--toolset=clang"
    when :gcc
      args << "--toolset=darwin"
    end
    args << "--prefix=#{prefix}"
    system "bjam", *args

    (lib/"pkgconfig/luabind.pc").write pc_file
  end

  def pc_file
    <<~EOS
      prefix=#{HOMEBREW_PREFIX}
      exec_prefix=${prefix}
      libdir=${exec_prefix}/lib
      includedir=${exec_prefix}/include

      Name: luabind
      Description: Library for bindings between C++ and Lua
      Version: 0.9.1
      Libs: -L${libdir} -lluabind
      Cflags: -I${includedir}
    EOS
  end

  test do
    (testpath/"hello.cpp").write <<~EOS
      extern "C" {
      #include <lua.h>
      }
      #include <iostream>
      #include <luabind/luabind.hpp>
      void greet() { std::cout << "hello world!\\n"; }
      extern "C" int init(lua_State* L)
      {
          using namespace luabind;
          open(L);
          module(L)
          [
              def("greet", &greet)
          ];
          return 0;
      }
    EOS
    system ENV.cxx, "-shared", "hello.cpp", "-o", "hello.dylib",
                    "-I#{Formula["lua@5.1"].include}/lua-5.1",
                    "-L#{lib}", "-lluabind",
                    "-L#{Formula["lua@5.1"].lib}", "-llua5.1"
    output = `lua5.1 -e "package.loadlib('#{testpath}/hello.dylib', 'init')(); greet()"`
    assert_match "hello world!", output
  end
end
