require "language/node"

class CashCliAT421 < Formula
  desc "Convert currency rates directly from your terminal"
  homepage "https://github.com/xxczaki/cash-cli"
  url "https://registry.npmjs.org/cash-cli/-/cash-cli-4.2.1.tgz"
  sha256 "593e2b02aab0e4369225a2c78a895d511ee491a1708e44d7aba63d9a897b000e"
  license "MIT"

  depends_on "node"

  def install
    system "npm", "install", *Language::Node.std_npm_install_args(libexec)
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    assert_match "Conversion of USD 100", shell_output("#{bin}/cash 100 USD PLN CHF")
  end
end
