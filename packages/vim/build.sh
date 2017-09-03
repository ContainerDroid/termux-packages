TERMUX_PKG_DESCRIPTION="Vi IMproved - enhanced vi editor"
TERMUX_PKG_HOMEPAGE=http://www.vim.org/
TERMUX_PKG_DEPENDS="ncurses, vim-runtime"

# Vim 8.0 patches described at ftp://ftp.vim.org/pub/vim/patches/8.0/README
TERMUX_PKG_VERSION=8.0.0979
TERMUX_PKG_SHA256=fd9bb5a1b6b653ab4950b41cb19b2ea46dbed5d4bb8367f9b5a484bf83fc2a2c
TERMUX_PKG_SRCURL="https://github.com/vim/vim/archive/v${TERMUX_PKG_VERSION}.tar.gz"
TERMUX_PKG_FOLDERNAME=vim-${TERMUX_PKG_VERSION}
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
vim_cv_getcwd_broken=no
vim_cv_memmove_handles_overlap=yes
vim_cv_stat_ignores_slash=no
vim_cv_terminfo=yes
vim_cv_tgent=zero
vim_cv_toupper_broken=no
vim_cv_tty_group=world
--enable-gui=no
--enable-multibyte
--with-features=huge
--without-x
--with-tlib=ncursesw
--enable-terminal
"
TERMUX_PKG_BUILD_IN_SRC="yes"
TERMUX_PKG_RM_AFTER_INSTALL="
usr/bin/rview
usr/bin/rvim
usr/bin/ex
usr/share/man/man1/evim.1
usr/share/icons
usr/share/vim/vim80/spell/en.ascii*
usr/share/vim/vim80/print
usr/share/vim/vim80/tools
"
TERMUX_PKG_CONFFILES="usr/share/vim/vimrc"

TERMUX_PKG_CONFLICTS="vim-python"

termux_step_pre_configure () {
	make distclean

	# Remove eventually existing symlinks from previous builds so that they get re-created
	for b in rview rvim ex view vimdiff; do rm -f $TERMUX_DESTDIR/usr/bin/$b; done
	rm -f $TERMUX_DESTDIR/usr/share/man/man1/view.1
}

termux_step_post_make_install () {
	cp $TERMUX_PKG_BUILDER_DIR/vimrc $TERMUX_DESTDIR/usr/share/vim/vimrc

	# Remove most tutor files:
	cp $TERMUX_DESTDIR/usr/share/vim/vim80/tutor/{tutor,tutor.vim,tutor.utf-8} $TERMUX_PKG_TMPDIR/
	rm -f $TERMUX_DESTDIR/usr/share/vim/vim80/tutor/*
	cp $TERMUX_PKG_TMPDIR/{tutor,tutor.vim,tutor.utf-8} $TERMUX_DESTDIR/usr/share/vim/vim80/tutor/

	cd $TERMUX_DESTDIR/usr/bin
	ln -f -s vim vi
}
