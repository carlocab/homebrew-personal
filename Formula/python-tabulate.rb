class PythonTabulate < Formula
  include Language::Python::Virtualenv

  desc "Pretty-print tabular data in Python"
  homepage "https://pypi.org/project/tabulate/"
  url "https://files.pythonhosted.org/packages/ae/3d/9d7576d94007eaf3bb685acbaaec66ff4cdeb0b18f1bf1f17edbeebffb0a/tabulate-0.8.9.tar.gz"
  sha256 "eb1d13f25760052e8931f2ef80aaf6045a6cceb47514db8beab24cded16f13a7"
  license "MIT"

  bottle do
    root_url "https://github.com/carlocab/homebrew-personal/releases/download/python-tabulate-0.8.9"
    sha256 cellar: :any_skip_relocation, big_sur:      "726ce572d40b5bea689a8a4ac83194208bf09c63cb61bf9f0757d0c7836dea12"
    sha256 cellar: :any_skip_relocation, catalina:     "8175b2b1297ec026e580c30b13e77d32a57c0f875c8bbc1888086d9662a01338"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "74eafe9fb9ca57a9b25b86148b1d64325322075a12e9ef641a3b045a7174119d"
  end

  depends_on "python@3.9"

  def install
    virtualenv_install_with_resources

    xy = Language::Python.major_minor_version Formula["python@3.9"].opt_bin/"python3"
    site_packages = "lib/python#{xy}/site-packages"
    pth_contents = "import site; site.addsitedir('#{libexec/site_packages}')\n"
    (prefix/site_packages/"homebrew-py-tabulate.pth").write pth_contents
  end

  test do
    (testpath/"in.txt").write <<~EOS
      name qty
      eggs 451
      spam 42
    EOS

    (testpath/"out.txt").write <<~EOS
      +------+-----+
      | name | qty |
      +------+-----+
      | eggs | 451 |
      +------+-----+
      | spam | 42  |
      +------+-----+
    EOS

    assert_equal (testpath/"out.txt").read, shell_output("#{bin}/tabulate -f grid #{testpath}/in.txt")
    system Formula["python@3.9"].opt_bin/"python3", "-c", "from tabulate import tabulate"
  end
end
