class TmuxAT31c < Formula
  desc "Terminal multiplexer"
  homepage "https://tmux.github.io/"
  url "https://github.com/tmux/tmux/releases/download/3.1c/tmux-3.1c.tar.gz"
  sha256 "918f7220447bef33a1902d4faff05317afd9db4ae1c9971bef5c787ac6c88386"
  license "ISC"
  revision 1

  livecheck do
    url "https://github.com/tmux/tmux/releases/latest"
    regex(%r{href=.*?/tag/v?(\d+(?:\.\d+)+[a-z]?)["' >]}i)
  end

  head do
    url "https://github.com/tmux/tmux.git"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  keg_only :versioned_formula

  depends_on "autoconf" => :build # Needed for stable build while
  depends_on "automake" => :build # inline patch is in use
  depends_on "pkg-config" => :build
  depends_on "libevent"
  depends_on "ncurses"

  # Old versions of macOS libc disagree with utf8proc character widths.
  # https://github.com/tmux/tmux/issues/2223
  depends_on "utf8proc" if MacOS.version >= :high_sierra

  resource "completion" do
    url "https://raw.githubusercontent.com/imomaliev/tmux-bash-completion/f5d53239f7658f8e8fbaf02535cc369009c436d6/completions/tmux"
    sha256 "b5f7bbd78f9790026bbff16fc6e3fe4070d067f58f943e156bd1a8c3c99f6a6f"
  end

  # Patch from maintainer at
  # https://github.com/tmux/tmux/issues/2468#issuecomment-729049845
  patch :DATA unless build.head?

  def install
    system "sh", "autogen.sh" if build.head?

    # Needed for patch, remove in next version
    unless build.head?
      files_to_fix = %w[
        aclocal.m4
        configure
      ]

      automake_version = Formula["automake"].version
      major_version = automake_version.to_s[/\d\.\d\d/]
      files_to_fix.each do |file|
        inreplace file, "'1.15'", "'#{major_version}'"
      end

      inreplace "aclocal.m4", "[1.15.1]", "[#{automake_version}]"
    end

    args = %W[
      --disable-dependency-tracking
      --prefix=#{prefix}
      --sysconfdir=#{etc}
    ]

    args << "--enable-utf8proc" if MacOS.version >= :high_sierra

    ENV.append "LDFLAGS", "-lresolv"
    system "./configure", *args

    system "make", "install"

    pkgshare.install "example_tmux.conf"
    bash_completion.install resource("completion")
  end

  def caveats
    <<~EOS
      Example configuration has been installed to:
        #{opt_pkgshare}
    EOS
  end

  test do
    system "#{bin}/tmux", "-V"
  end
end
__END__
diff --git a/compat/closefrom.c b/compat/closefrom.c
index 7915cde4..28be3680 100644
--- a/compat/closefrom.c
+++ b/compat/closefrom.c
@@ -14,6 +14,8 @@
  * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
  */

+#include "compat.h"
+
 #ifndef HAVE_CLOSEFROM

 #include <sys/types.h>
@@ -44,8 +46,9 @@
 #  include <ndir.h>
 # endif
 #endif
-
-#include "compat.h"
+#if defined(HAVE_LIBPROC_H)
+# include <libproc.h>
+#endif

 #ifndef OPEN_MAX
 # define OPEN_MAX	256
@@ -55,21 +58,73 @@
 __unused static const char rcsid[] = "$Sudo: closefrom.c,v 1.11 2006/08/17 15:26:54 millert Exp $";
 #endif /* lint */

+#ifndef HAVE_FCNTL_CLOSEM
 /*
  * Close all file descriptors greater than or equal to lowfd.
  */
+static void
+closefrom_fallback(int lowfd)
+{
+	long fd, maxfd;
+
+	/*
+	 * Fall back on sysconf() or getdtablesize().  We avoid checking
+	 * resource limits since it is possible to open a file descriptor
+	 * and then drop the rlimit such that it is below the open fd.
+	 */
+#ifdef HAVE_SYSCONF
+	maxfd = sysconf(_SC_OPEN_MAX);
+#else
+	maxfd = getdtablesize();
+#endif /* HAVE_SYSCONF */
+	if (maxfd < 0)
+		maxfd = OPEN_MAX;
+
+	for (fd = lowfd; fd < maxfd; fd++)
+		(void) close((int) fd);
+}
+#endif /* HAVE_FCNTL_CLOSEM */
+
 #ifdef HAVE_FCNTL_CLOSEM
 void
 closefrom(int lowfd)
 {
     (void) fcntl(lowfd, F_CLOSEM, 0);
 }
-#else
+#elif defined(HAVE_LIBPROC_H) && defined(HAVE_PROC_PIDINFO)
 void
 closefrom(int lowfd)
 {
-    long fd, maxfd;
-#if defined(HAVE_DIRFD) && defined(HAVE_PROC_PID)
+	int i, r, sz;
+	pid_t pid = getpid();
+	struct proc_fdinfo *fdinfo_buf = NULL;
+
+	sz = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, NULL, 0);
+	if (sz == 0)
+		return; /* no fds, really? */
+	else if (sz == -1)
+		goto fallback;
+	if ((fdinfo_buf = malloc(sz)) == NULL)
+		goto fallback;
+	r = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, fdinfo_buf, sz);
+	if (r < 0 || r > sz)
+		goto fallback;
+	for (i = 0; i < r / (int)PROC_PIDLISTFD_SIZE; i++) {
+		if (fdinfo_buf[i].proc_fd >= lowfd)
+			close(fdinfo_buf[i].proc_fd);
+	}
+	free(fdinfo_buf);
+	return;
+ fallback:
+	free(fdinfo_buf);
+	closefrom_fallback(lowfd);
+	return;
+}
+#elif defined(HAVE_DIRFD) && defined(HAVE_PROC_PID)
+void
+closefrom(int lowfd)
+{
+    long fd;
     char fdpath[PATH_MAX], *endp;
     struct dirent *dent;
     DIR *dirp;
@@ -77,7 +132,7 @@ closefrom(int lowfd)

     /* Check for a /proc/$$/fd directory. */
     len = snprintf(fdpath, sizeof(fdpath), "/proc/%ld/fd", (long)getpid());
-    if (len > 0 && (size_t)len <= sizeof(fdpath) && (dirp = opendir(fdpath))) {
+    if (len > 0 && (size_t)len < sizeof(fdpath) && (dirp = opendir(fdpath))) {
 	while ((dent = readdir(dirp)) != NULL) {
 	    fd = strtol(dent->d_name, &endp, 10);
 	    if (dent->d_name != endp && *endp == '\0' &&
@@ -85,25 +140,16 @@ closefrom(int lowfd)
 		(void) close((int) fd);
 	}
 	(void) closedir(dirp);
-    } else
-#endif
-    {
-	/*
-	 * Fall back on sysconf() or getdtablesize().  We avoid checking
-	 * resource limits since it is possible to open a file descriptor
-	 * and then drop the rlimit such that it is below the open fd.
-	 */
-#ifdef HAVE_SYSCONF
-	maxfd = sysconf(_SC_OPEN_MAX);
-#else
-	maxfd = getdtablesize();
-#endif /* HAVE_SYSCONF */
-	if (maxfd < 0)
-	    maxfd = OPEN_MAX;
-
-	for (fd = lowfd; fd < maxfd; fd++)
-	    (void) close((int) fd);
+	return;
     }
+    /* /proc/$$/fd strategy failed, fall back to brute force closure */
+    closefrom_fallback(lowfd);
+}
+#else
+void
+closefrom(int lowfd)
+{
+	closefrom_fallback(lowfd);
 }
 #endif /* !HAVE_FCNTL_CLOSEM */
 #endif /* HAVE_CLOSEFROM */
diff --git a/configure.ac b/configure.ac
index 97010df4..8dd00d79 100644
--- a/configure.ac
+++ b/configure.ac
@@ -99,6 +99,7 @@ AC_CHECK_HEADERS([ \
 	dirent.h \
 	fcntl.h \
 	inttypes.h \
+	libproc.h \
 	libutil.h \
 	ndir.h \
 	paths.h \
@@ -124,7 +125,8 @@ AC_CHECK_FUNCS([ \
 	dirfd \
 	flock \
 	prctl \
-	sysconf \
+	proc_pidinfo \
+	sysconf
 ])

 # Check for functions with a compatibility implementation.
