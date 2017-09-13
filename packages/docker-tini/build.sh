TERMUX_PKG_HOMEPAGE=https://www.docker.com/
TERMUX_PKG_DESCRIPTION="An open and reliable container runtime"
TERMUX_PKG_VERSION=18.04.0
TINI_GIT_COMMIT=949e6facb77383876aeff8a6944dde66b3089574
TERMUX_PKG_SHA256=ebc72a2664678ef2e4e3d94873be45b64e6cba501aae5b4851e26661ea2c3f01
TERMUX_PKG_SRCURL=https://github.com/krallin/tini/archive/${TINI_GIT_COMMIT}.zip
TERMUX_PKG_FOLDERNAME=tini-${TINI_GIT_COMMIT}

termux_step_pre_configure() {
	echo "New CFLAGS are: ${CFLAGS}"
}

termux_step_make_install() {
	install -Dm 0755 tini-static ${TERMUX_DESTDIR}/${USR}/bin/docker-init
}
