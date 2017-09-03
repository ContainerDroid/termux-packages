TERMUX_PKG_HOMEPAGE=https://www.openssh.com/
TERMUX_PKG_DESCRIPTION="Secure shell for logging into a remote machine"
TERMUX_PKG_VERSION=7.5p1
TERMUX_PKG_REVISION=4
TERMUX_PKG_SRCURL=http://mirrors.evowise.com/pub/OpenBSD/OpenSSH/portable/openssh-${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=9846e3c5fab9f0547400b4d2c017992f914222b3fd1f8eee6c7dc6bc5e59f9f0
TERMUX_PKG_DEPENDS="libandroid-support, ldns, openssl, libedit, libutil"
# --disable-strip to prevent host "install" command to use "-s", which won't work for target binaries:
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--disable-etc-default-login
--disable-lastlog
--disable-libutil
--disable-pututline
--disable-pututxline
--disable-strip
--disable-utmp
--disable-utmpx
--disable-wtmp
--disable-wtmpx
--sysconfdir=/etc/ssh
--with-cflags=-Dfd_mask=int
--with-ldns
--with-libedit
--without-ssh1
--without-stackprotect
--with-pid-dir=/var/run
--with-privsep-path=/var/empty
ac_cv_func_endgrent=yes
ac_cv_func_fmt_scaled=no
ac_cv_func_getlastlogxbyname=no
ac_cv_func_readpassphrase=no
ac_cv_func_strnvis=no
ac_cv_header_sys_un_h=yes
ac_cv_search_getrrsetbyname=no
"
TERMUX_PKG_MAKE_INSTALL_TARGET="install-nokeys"
TERMUX_PKG_RM_AFTER_INSTALL="usr/bin/slogin usr/share/man/man1/slogin.1"

termux_step_pre_configure() {
	autoreconf

	CPPFLAGS+=" -DHAVE_ATTRIBUTE__SENTINEL__=1"
	LD=$CC # Needed to link the binaries
	LDFLAGS+=" -llog" # liblog for android logging in syslog hack

	# Fixup for the Termux mashup between PREFIX and DESTDIR
	# We set DESTDIR in Makefile.in
	PREFIX="/usr"
	prefix="/usr"
	exec_prefix="/usr"
}

termux_step_post_configure() {
	# We need to remove this file before installing, since otherwise the
	# install leaves it alone which means no updated timestamps.
	rm -Rf $TERMUX_DESTDIR/etc/moduli
}

termux_step_post_make_install () {
	# OpenSSH 7.0 disabled ssh-dss by default, keep it for a while in Termux:
	cat << 'EOF' > "$TERMUX_DESTDIR/etc/ssh/sshd_config"
PasswordAuthentication no
PubkeyAcceptedKeyTypes +ssh-dss
Subsystem sftp /usr/libexec/sftp-server
EOF

	echo "PubkeyAcceptedKeyTypes +ssh-dss" > $TERMUX_DESTDIR/etc/ssh/ssh_config
	#cp $TERMUX_PKG_BUILDER_DIR/source-ssh-agent.sh $TERMUX_DESTDIR/usr/bin/source-ssh-agent
	#cp $TERMUX_PKG_BUILDER_DIR/ssh-with-agent.sh $TERMUX_DESTDIR/usr/bin/ssha

	# Install ssh-copy-id:
	cp $TERMUX_PKG_SRCDIR/contrib/ssh-copy-id.1 $TERMUX_DESTDIR/usr/share/man/man1/
	cp $TERMUX_PKG_SRCDIR/contrib/ssh-copy-id $TERMUX_DESTDIR/usr/bin/
	chmod +x $TERMUX_DESTDIR/usr/bin/ssh-copy-id

	mkdir -p $TERMUX_DESTDIR/var/run
	echo "OpenSSH needs this folder to put sshd.pid in" >> $TERMUX_DESTDIR/var/run/README.openssh

	mkdir -p $TERMUX_DESTDIR/etc/ssh/
	cp $TERMUX_PKG_SRCDIR/moduli $TERMUX_DESTDIR/etc/ssh/moduli
}

termux_step_create_debscripts () {
	cat << 'EOF' > postinst
#!/bin/sh
mkdir -p $HOME/.ssh
touch $HOME/.ssh/authorized_keys
chmod 700 $HOME/.ssh
chmod 600 $HOME/.ssh/authorized_keys

for a in rsa dsa ecdsa ed25519; do
    KEYFILE=/etc/ssh/ssh_host_${a}_key
    test ! -f $KEYFILE && ssh-keygen -N '' -t $a -f $KEYFILE
done
exit 0
EOF
        chmod 0755 postinst
}
