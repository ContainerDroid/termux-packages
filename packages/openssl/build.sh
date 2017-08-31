TERMUX_PKG_HOMEPAGE=https://www.openssl.org/
TERMUX_PKG_DESCRIPTION="Library implementing the SSL and TLS protocols as well as general purpose cryptography functions"
TERMUX_PKG_DEPENDS="ca-certificates"
TERMUX_PKG_VERSION=1.0.2l
TERMUX_PKG_REVISION=1
TERMUX_PKG_SRCURL=https://www.openssl.org/source/openssl-${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=ce07195b659e75f4e1db43552860070061f156a98bb37b672b101ba6e3ddf30c
TERMUX_PKG_RM_AFTER_INSTALL="bin/c_rehash etc/ssl/misc"
TERMUX_PKG_BUILD_IN_SRC=yes
# Avoid assembly errors, see
# https://github.com/android-ndk/ndk/issues/144
# https://github.com/openssl/openssl/issues/1498
# May be fixed in later openssl version.
TERMUX_PKG_CLANG=no

# Information about compilation and installation of openssl:
# http://wiki.openssl.org/index.php/Compilation_and_Installation

termux_step_configure () {
	perl -p -i -e "s@TERMUX_CFLAGS@$CFLAGS@g" Configure
	rm -Rf $TERMUX_DESTDIR/usr/lib/libcrypto.* $TERMUX_DESTDIR/usr/lib/libssl.*
	test $TERMUX_ARCH = "arm" && TERMUX_OPENSSL_PLATFORM="android-armv7"
	test $TERMUX_ARCH = "aarch64" && TERMUX_OPENSSL_PLATFORM="linux-aarch64"
	test $TERMUX_ARCH = "i686" && TERMUX_OPENSSL_PLATFORM="android-x86"
	test $TERMUX_ARCH = "x86_64" && TERMUX_OPENSSL_PLATFORM="linux-x86_64"
	# If enabling zlib-dynamic we need "zlib-dynamic" instead of "no-comp no-dso":
	./Configure $TERMUX_OPENSSL_PLATFORM \
		--prefix=$TERMUX_DESTDIR/usr \
		--openssldir=$TERMUX_DESTDIR/etc/tls \
		shared \
		no-comp \
		no-dso \
		no-ssl2 \
		no-hw \
		no-engines \
		no-srp
}

termux_step_make () {
	make depend
	make -j 1 all
}

termux_step_make_install () {
	# "install_sw" instead of "install" to not install man pages:
	make -j 1 install_sw MANDIR=$TERMUX_DESTDIR/usr/share/man MANSUFFIX=.ssl
}
