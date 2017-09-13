TERMUX_PKG_HOMEPAGE=https://github.com/termux/libandroid-support
TERMUX_PKG_DESCRIPTION="Library extending the Android C library (Bionic) for additional multibyte, locale and math support"
TERMUX_PKG_VERSION=22
TERMUX_PKG_SHA256=667f20d0821a6305c50c667363486d546b293e846f31d02f559947d50121f51e
TERMUX_PKG_SRCURL=https://github.com/termux/libandroid-support/archive/v${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_BUILD_IN_SRC=yes
TERMUX_PKG_ESSENTIAL=yes

termux_step_make_install () {
	_C_FILES="src/musl-*/*.c"
	$CC $CFLAGS -std=c99 -DNULL=0 $CPPFLAGS $LDFLAGS \
		-Iinclude \
		$_C_FILES \
		-shared -fpic \
		-o libandroid-support.so

	cp libandroid-support.so ${TERMUX_DESTDIR}/${USR}/lib/

	(cd ${TERMUX_DESTDIR}/${USR}/lib; ln -f -s libandroid-support.so libiconv.so; )

	rm -Rf ${TERMUX_DESTDIR}/${USR}/include/libandroid-support
	mkdir -p ${TERMUX_DESTDIR}/${USR}/include/libandroid-support
	cp -Rf include/* ${TERMUX_DESTDIR}/${USR}/include/libandroid-support/

	(cd ${TERMUX_DESTDIR}/${USR}/include; ln -f -s libandroid-support/iconv.h iconv.h)
}
