TERMUX_PKG_HOMEPAGE=https://www.gnupg.org/
TERMUX_PKG_DESCRIPTION="OpenPGP implementation for encrypting and signing data and communication"
TERMUX_PKG_VERSION=1.4.22
TERMUX_PKG_SHA256=9594a24bec63a21568424242e3f198b9d9828dea5ff0c335e47b06f835f930b4
TERMUX_PKG_SRCURL=ftp://ftp.gnupg.org/gcrypt/gnupg/gnupg-${TERMUX_PKG_VERSION}.tar.bz2
# disable readline since gnupg is used in bootstrap, so nice to avoid readline+ncurses dependencies.
# ac_cv_sys_symbol_underscore=no needed for i686 build to avoid "undefined reference to `mpihelp_sub_n'" errors
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="--disable-endian-check --without-readline ac_cv_sys_symbol_underscore=no"
# ac_cv_header_sys_shm_h is to avoid USE_SHM_COPROCESSING getting defined due to <sys/shm.h>,
#                        which it does on android-21 (but shmat(2) does not exist)
# am_cv_func_iconv=no is for disabling linking with libiconv (libandroid-support).
# This is to work around probable libtool bug, which links with absolute path of libiconv.so,
# despite configuring with --disable-rpath
TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" ac_cv_header_sys_shm_h=no am_cv_func_iconv=no"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" --disable-bzip2"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" --disable-gnupg-iconv"
# Assembly issues on at least arm:
TERMUX_PKG_CLANG=no

termux_step_pre_configure() {
	CFLAGS+=" -D__LITTLE_ENDIAN__"
	export prefix="$TERMUX_DESTDIR/usr"
	export exec_prefix="$TERMUX_DESTDIR"
}
