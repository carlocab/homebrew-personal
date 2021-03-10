class Wllvm < Formula
  include Language::Python::Virtualenv

  desc "Toolkit for building whole-program LLVM bitcode files"
  homepage "https://pypi.org/project/wllvm/"
  url "https://files.pythonhosted.org/packages/63/cd/0cc7994c2a94983adb8b07f34a88e6a815f4d18a1e29eb68d094e5863f18/wllvm-1.3.0.tar.gz"
  sha256 "a98dd48350d8aae80fe03b92efb11c3e1b92f6aee482f4331f7c97265ca7a602"
  license "MIT"

  bottle do
    root_url "https://github.com/carlocab/homebrew-personal/releases/download/wllvm-1.3.0"
    sha256 cellar: :any_skip_relocation, big_sur:      "3c68cdb4bf1a0c9e5e0856b94448b269c7c79fdd6213780dee4a2cf357791c78"
    sha256 cellar: :any_skip_relocation, catalina:     "92f87f71ed8184bed9f344f0bab042da31088f12bcc971e8e4c948cfb2dea384"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "9ba7fb948e1bde159d6ceec28e5420e0cbbf38adf70c9790df60dbeb1af5f411"
  end

  depends_on "llvm"
  depends_on "python@3.9"

  def install
    virtualenv_install_with_resources
  end

  test do
    ENV.prepend_path "PATH", Formula["llvm"].opt_bin
    (testpath/"test.c").write "int main() { return 0; }"

    with_env(LLVM_COMPILER: "clang") do
      system bin/"wllvm", testpath/"test.c", "-o", testpath/"test"
    end
    assert_predicate testpath/".test.o", :exist?
    assert_predicate testpath/".test.o.bc", :exist?

    system bin/"extract-bc", testpath/"test"
    assert_predicate testpath/"test.bc", :exist?
  end
end
