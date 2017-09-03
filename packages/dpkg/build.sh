TERMUX_PKG_HOMEPAGE=https://packages.debian.org/dpkg
TERMUX_PKG_DESCRIPTION="Debian package management system"
TERMUX_PKG_VERSION=1.18.24
TERMUX_PKG_SRCURL=https://mirrors.kernel.org/debian/pool/main/d/dpkg/dpkg_${TERMUX_PKG_VERSION}.tar.xz
TERMUX_PKG_SHA256=d853081d3e06bfd46a227056e591f094e42e78fa8a5793b0093bad30b710d7b4
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
ac_cv_lib_selinux_setexecfilecon=no
--disable-dselect
--disable-largefile
--disable-shared
--disable-start-stop-daemon
--disable-update-alternatives
--with-admindir=/var/lib/dpkg
dpkg_cv_c99_snprintf=yes
HAVE_SETEXECFILECON_FALSE=#
--host=${TERMUX_ARCH}-linux
--without-libbz2
--without-selinux
"
TERMUX_PKG_RM_AFTER_INSTALL="
usr/bin/dpkg-architecture
usr/bin/dpkg-buildflags
usr/bin/dpkg-buildpackage
usr/bin/dpkg-checkbuilddeps
usr/bin/dpkg-distaddfile
usr/bin/dpkg-genchanges
usr/bin/dpkg-gencontrol
usr/bin/dpkg-gensymbols
usr/bin/dpkg-maintscript-helper
usr/bin/dpkg-mergechangelogs
usr/bin/dpkg-name
usr/bin/dpkg-parsechangelog
usr/bin/dpkg-scanpackages
usr/bin/dpkg-scansources
usr/bin/dpkg-shlibdeps
usr/bin/dpkg-source
usr/bin/dpkg-statoverride
usr/bin/dpkg-vendor
usr/lib/dpkg/parsechangelog
usr/lib/perl5
usr/share/dpkg
usr/share/man/man1/dpkg-architecture.1
usr/share/man/man1/dpkg-buildflags.1
usr/share/man/man1/dpkg-buildpackage.1
usr/share/man/man1/dpkg-checkbuilddeps.1
usr/share/man/man1/dpkg-distaddfile.1
usr/share/man/man1/dpkg-genchanges.1
usr/share/man/man1/dpkg-gencontrol.1
usr/share/man/man1/dpkg-gensymbols.1
usr/share/man/man1/dpkg-maintscript-helper.1
usr/share/man/man1/dpkg-mergechangelogs.1
usr/share/man/man1/dpkg-name.1
usr/share/man/man1/dpkg-parsechangelog.1
usr/share/man/man1/dpkg-scanpackages.1
usr/share/man/man1/dpkg-scansources.1
usr/share/man/man1/dpkg-shlibdeps.1
usr/share/man/man1/dpkg-source.1
usr/share/man/man1/dpkg-statoverride.1
usr/share/man/man1/dpkg-vendor.1
usr/share/man/man3
usr/share/man/man5
usr/share/perl5
"
# with the extract.c.patch we remove the -p and --warning=no-timestamp tar options so we can use busybox tar
TERMUX_PKG_DEPENDS="busybox, liblzma"
TERMUX_PKG_ESSENTIAL=yes

termux_step_pre_configure () {
	export PREFIX=/usr
	export prefix=/usr
	export DESTDIR="$TERMUX_DESTDIR"
	# To make sure dpkg tries to use "tar" instead of e.g. "gnutar" (which happens when building on OS X)
	export TAR=tar
	perl -p -i -e "s/TERMUX_ARCH/$TERMUX_ARCH/" $TERMUX_PKG_SRCDIR/configure
}
