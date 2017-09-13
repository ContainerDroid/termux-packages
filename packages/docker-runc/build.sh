TERMUX_PKG_HOMEPAGE=https://www.opencontainers.org/
TERMUX_PKG_DESCRIPTION="runc container cli tools"
TERMUX_PKG_VERSION=18.04.0
RUNC_GIT_COMMIT="4fc53a81fb7c994640722ac585fa9ca548971871"
TERMUX_PKG_SHA256=ee8abb6a961159f7f0fd22f9ed4068e5ac85714e480c61a81e45a5d033ce1e99
TERMUX_PKG_SRCURL=https://github.com/opencontainers/runc/archive/${RUNC_GIT_COMMIT}.zip
TERMUX_PKG_FOLDERNAME=runc-${RUNC_GIT_COMMIT}

termux_step_make() {
	# Create ${GO_WORKSPACE} and add it to ${GOPATH}
	termux_setup_golang --mimic-go-get-workspace "src/github.com/opencontainers/runc"

	# issue the build command
	(cd ${GO_WORKSPACE}; make BUILDTAGS="selinux")
}

termux_step_make_install() {
	install -Dm 0755 ${GO_WORKSPACE}/runc ${TERMUX_DESTDIR}/${USR}/bin/docker-runc
}
