TERMUX_PKG_HOMEPAGE=http://michael.dipperstein.com/crypt/
TERMUX_PKG_DESCRIPTION="A crypt(3) implementation"
TERMUX_PKG_VERSION=0.2
TERMUX_PKG_DEPENDS="openssl"

termux_step_make_install () {
	$CC $CFLAGS $CPPFLAGS $LDFLAGS -Wall -Wextra -fPIC -shared $TERMUX_PKG_BUILDER_DIR/crypt3.c -lcrypto -o $TERMUX_DESTDIR/usr/lib/libcrypt.so
	mkdir -p $TERMUX_DESTDIR/usr/include/
	cp $TERMUX_PKG_BUILDER_DIR/crypt.h $TERMUX_DESTDIR/usr/include/
}
