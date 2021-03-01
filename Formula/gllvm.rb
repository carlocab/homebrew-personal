class Gllvm < Formula
  desc "Whole Program LLVM: wllvm ported to go"
  homepage "https://github.com/SRI-CSL/gllvm/"
  url "https://github.com/SRI-CSL/gllvm/archive/v1.3.0.tar.gz"
  sha256 "e8bcb9b93bc2d24283fe45f16891ec5d70116b5fc49144a9c98832ed074f8782"
  license "BSD-3-Clause"

  depends_on "go" => :build
  depends_on "llvm"

  def install
    ENV["GOPATH"] = buildpath
    ENV["GOBIN"] = bin
    ENV["GO111MODULE"] = "auto"
    src_dir = buildpath/"src/github.com/SRI-CSL/gllvm"
    src_dir.install buildpath.children
    bins = %w[gclang++ gclang get-bc gparse gsanity-check]
    bins.each do |exe|
      system "go", "build", *std_go_args, "-o", bin/exe, "#{src_dir}/cmd/#{exe}"
    end
  end

  test do
    (testpath/"hello.c").write <<~EOS
      #include <stdio.h>
      int main() {
        printf("hello, world!\\n");
        return 0;
      }
    EOS
    ENV["LLVM_COMPILER_PATH"] = Formula["llvm"].opt_bin
    system bin/"gclang", "hello.c", "-o", "hello"
    system bin/"get-bc", "hello"
    assert_predicate testpath/"hello.bc", :exist?
  end
end
