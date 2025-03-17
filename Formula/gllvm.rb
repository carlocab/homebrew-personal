class Gllvm < Formula
  desc "Whole Program LLVM: wllvm ported to go"
  homepage "https://github.com/SRI-CSL/gllvm/"
  url "https://github.com/SRI-CSL/gllvm/archive/refs/tags/v1.3.0.tar.gz"
  sha256 "e8bcb9b93bc2d24283fe45f16891ec5d70116b5fc49144a9c98832ed074f8782"
  license "BSD-3-Clause"

  bottle do
    root_url "https://github.com/carlocab/homebrew-personal/releases/download/gllvm-1.3.0"
    sha256 cellar: :any_skip_relocation, big_sur:      "b5e321bef35dde914ae7cf847cba8339192e9df2468c76e59acb718b5d4b0c5a"
    sha256 cellar: :any_skip_relocation, catalina:     "92444d800a22709396bcf80c8c6e883f539f2bd9ea629170cdbb777f383b0d56"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "d045c6275487fbfe9275f3f8a38fb8f1f51da6ee64f5adc020781e9af6ada9d3"
  end

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
    assert_path_exists testpath/"hello.bc"
  end
end
