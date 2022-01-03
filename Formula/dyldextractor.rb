class Dyldextractor < Formula
  desc "Extract dylibs from the dyld shared cache"
  homepage "https://github.com/unixzii/DyldExtractor"
  license "MIT"
  head "https://github.com/unixzii/DyldExtractor.git", branch: "master"

  def install
    system "make"
    bin.install "dyld_extractor"
  end

  test do
    assert_match "dyld shared cache extractor", shell_output("#{bin}/dyld_extractor", 1)
  end
end
