TERMUX_PKG_HOMEPAGE=https://picolisp.com
TERMUX_PKG_DESCRIPTION="Lisp interpreter and application server framework"
TERMUX_PKG_DEPENDS="libcrypt, openssl"
_PICOLISP_YEAR=17
_PICOLISP_MONTH=8
_PICOLISP_DAY=7
TERMUX_PKG_VERSION=${_PICOLISP_YEAR}.${_PICOLISP_MONTH}.${_PICOLISP_DAY}
# We use our bintray mirror since old version snapshots are not kept on main site.
TERMUX_PKG_SRCURL=https://dl.bintray.com/termux/upstream/picolisp_${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=7db7f2ce7c06b07ac6e74f156462de4b6e5181fa3912a922da27447afa3197df
TERMUX_PKG_FOLDERNAME=picoLisp
TERMUX_PKG_BUILD_IN_SRC=true
# The assembly is not position-independent (would be a major rewrite):
TERMUX_PKG_BLACKLISTED_ARCHES="x86_64"
if [ $TERMUX_ARCH_BITS = 32 ]; then
	# "Variable length array in structure won't be supported"
	TERMUX_PKG_CLANG=no
fi

termux_step_pre_configure() {
	# Validate that we have the right version:
	grep -q "Version $_PICOLISP_YEAR $_PICOLISP_MONTH $_PICOLISP_DAY" src64/version.l || {
		termux_error_exit "Picolisp version needs to be bumped"
	}

	if [ $TERMUX_ARCH_BITS = 64 ]; then
		cd $TERMUX_PKG_SRCDIR
		if [ $TERMUX_ARCH = "aarch64" ]; then
			export TERMUX_PKG_EXTRA_MAKE_ARGS=arm64.linux
		elif [ $TERMUX_ARCH = "x86_64" ]; then
			export TERMUX_PKG_EXTRA_MAKE_ARGS=x86-64.linux
		else
			termux_error_exit "Unsupported arch: $TERMUX_ARCH"
		fi
		TERMUX_PKG_SRCDIR=$TERMUX_PKG_SRCDIR/src64
	else
		TERMUX_PKG_SRCDIR=$TERMUX_PKG_SRCDIR/src
	fi
	TERMUX_PKG_BUILDDIR=$TERMUX_PKG_SRCDIR
	ORIG_CFLAGS="$CFLAGS"
	CFLAGS+=" -c $LDFLAGS $CPPFLAGS"
}

termux_step_make_install () {
	cd $TERMUX_PKG_SRCDIR/

	if [ $TERMUX_ARCH_BITS = "64" ]; then
		$TERMUX_HOST_PLATFORM-as -o ${TERMUX_PKG_EXTRA_MAKE_ARGS}.base.o ${TERMUX_PKG_EXTRA_MAKE_ARGS}.base.s
		$TERMUX_HOST_PLATFORM-as -o ${TERMUX_PKG_EXTRA_MAKE_ARGS}.ext.o ${TERMUX_PKG_EXTRA_MAKE_ARGS}.ext.s
		$TERMUX_HOST_PLATFORM-as -o ${TERMUX_PKG_EXTRA_MAKE_ARGS}.ht.o ${TERMUX_PKG_EXTRA_MAKE_ARGS}.ht.s

		# Use -fuse-ld=bfd to avoid using the gold linker (which Termux
		# patches NDK to use by default) as it causes (tzo), the time
		# zone offset, to always be 0 (and probably other problems):
		$CC -o ../bin/picolisp ${TERMUX_PKG_EXTRA_MAKE_ARGS}.base.o \
			-Wl,--no-as-needed -rdynamic -lc -lm -ldl -pie -fuse-ld=bfd
		chmod +x ../bin/picolisp
		$CC -o ../lib/ext -shared -rdynamic -fuse-ld=bfd ${TERMUX_PKG_EXTRA_MAKE_ARGS}.ext.o
		$CC -o ../lib/ht -shared -rdynamic -fuse-ld=bfd ${TERMUX_PKG_EXTRA_MAKE_ARGS}.ht.o
	fi

	mkdir -p $TERMUX_DESTDIR/usr/share/man/man1
	cp $TERMUX_PKG_SRCDIR/../man/man1/{pil,picolisp}.1 $TERMUX_DESTDIR/usr/share/man/man1/

	rm -Rf $TERMUX_DESTDIR/usr/lib/picolisp
	mkdir -p $TERMUX_DESTDIR/usr/lib/picolisp

	cp -Rf $TERMUX_PKG_SRCDIR/../* $TERMUX_DESTDIR/usr/lib/picolisp/
	rm -Rf $TERMUX_DESTDIR/usr/lib/picolisp/{src,man,java,ersatz}

	# Replace first line "#!/usr/bin/picolisp /usr/lib/picolisp/lib.l":
	sed -i "1 s|^.*$|#!$TERMUX_DESTDIR/usr/bin/picolisp $TERMUX_DESTDIR/usr/lib/picolisp/lib.l|g" $TERMUX_DESTDIR/usr/lib/picolisp/bin/pil

	( cd $TERMUX_DESTDIR/usr/bin && ln -f -s ../lib/picolisp/bin/picolisp picolisp && ln -f -s ../lib/picolisp/bin/pil pil )

	# Bundled tools:
	$CC $ORIG_CFLAGS $CPPFLAGS $LDFLAGS -o $TERMUX_DESTDIR/usr/lib/picolisp/bin/ssl ../src/ssl.c -lssl -lcrypto
	$CC $ORIG_CFLAGS $CPPFLAGS $LDFLAGS -o $TERMUX_DESTDIR/usr/lib/picolisp/bin/httpGate ../src/httpGate.c -lssl -lcrypto

	# Man pages:
	cp $TERMUX_PKG_SRCDIR/../man/man1/{pil,picolisp}.1 $TERMUX_DESTDIR/usr/share/man/man1/
}
