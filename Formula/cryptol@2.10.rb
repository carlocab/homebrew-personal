class CryptolAT210 < Formula
  desc "Domain-specific language for specifying cryptographic algorithms"
  homepage "https://www.cryptol.net/"
  url "https://hackage.haskell.org/package/cryptol-2.10.0/cryptol-2.10.0.tar.gz"
  sha256 "0bfa21d4766b9ad21ba16ee43b83854f25a84e7ca2b68a14cbe0006b4173ef63"
  license "BSD-3-Clause"
  head "https://github.com/GaloisInc/cryptol.git"

  depends_on "cabal-install" => :build
  depends_on "ghc" => :build
  depends_on "z3"

  uses_from_macos "ncurses"
  uses_from_macos "zlib"

  def install
    system "cabal", "v2-update"
    system "cabal", "v2-install", *std_cabal_v2_args
  end

  test do
    (testpath/"helloworld.icry").write <<~EOS
      :prove \\(x : [8]) -> x == x
      :prove \\(x : [32]) -> x + zero == x
    EOS
    expected = /Q\.E\.D\..*Q\.E\.D/m
    assert_match expected, shell_output("#{bin}/cryptol -b helloworld.icry")
  end
end
