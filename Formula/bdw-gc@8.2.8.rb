class BdwGcAT828 < Formula
  desc "Garbage collector for C and C++"
  homepage "https://www.hboehm.info/gc/"
  url "https://github.com/ivmai/bdwgc/releases/download/v8.2.8/gc-8.2.8.tar.gz"
  sha256 "7649020621cb26325e1fb5c8742590d92fb48ce5c259b502faf7d9fb5dabb160"
  license "MIT"

  depends_on "cmake" => :build

  def install
    args = %w[
      -Denable_cplusplus=ON
      -Denable_large_config=ON
      -Dwithout_libatomic_ops=OFF
      -Dwith_libatomic_ops=OFF
    ]

    system "cmake", "-S", ".", "-B", "build",
                    "-Dbuild_tests=ON",
                    "-DBUILD_SHARED_LIBS=ON",
                    "-DCMAKE_INSTALL_RPATH=#{rpath}",
                    *args, *std_cmake_args,
                    "-DBUILD_TESTING=ON" # Pass this *after* `std_cmake_args`
    system "cmake", "--build", "build"
    system "ctest", "--test-dir", "build",
                    "--parallel", ENV.make_jobs,
                    "--rerun-failed",
                    "--output-on-failure"
    system "cmake", "--install", "build"

    system "cmake", "-S", ".", "-B", "build-static", "-DBUILD_SHARED_LIBS=OFF", *args, *std_cmake_args
    system "cmake", "--build", "build-static"
    lib.install buildpath.glob("build-static/*.a")
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <assert.h>
      #include <stdio.h>
      #include "gc.h"

      int main(void)
      {
        int i;

        GC_INIT();
        for (i = 0; i < 10000000; ++i)
        {
          int **p = (int **) GC_MALLOC(sizeof(int *));
          int *q = (int *) GC_MALLOC_ATOMIC(sizeof(int));
          assert(*p == 0);
          *p = (int *) GC_REALLOC(q, 2 * sizeof(int));
        }
        return 0;
      }
    EOS

    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lgc", "-o", "test"
    system "./test"
  end
end
