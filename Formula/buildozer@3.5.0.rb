class BuildozerAT350 < Formula
  desc "Rewrite bazel BUILD files using standard commands"
  homepage "https://github.com/bazelbuild/buildtools"
  url "https://github.com/bazelbuild/buildtools.git",
      tag:      "3.5.0",
      revision: "10384511ce98d864faf064a8ed54cdf31b98ac04"
  license "Apache-2.0"
  head "https://github.com/bazelbuild/buildtools.git"

  depends_on "bazelisk" => :build

  def install
    system "bazelisk", "build", "--config=release", "buildozer:buildozer"
    bin.install "bazel-bin/buildozer/darwin_amd64_stripped/buildozer"
  end

  test do
    build_file = testpath/"BUILD"

    touch build_file
    system "#{bin}/buildozer", "new java_library brewed", "//:__pkg__"

    assert_equal "java_library(name = \"brewed\")\n", build_file.read
  end
end
