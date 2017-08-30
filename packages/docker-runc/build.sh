TERMUX_PKG_HOMEPAGE=https://www.opencontainers.org/
TERMUX_PKG_DESCRIPTION="runc container cli tools"
TERMUX_PKG_VERSION=master
TERMUX_PKG_SHA256=146cbc43b113cb0e3b0036d6bef738f0cfe25238fd18c998473a122cc6628bc3
TERMUX_PKG_SRCURL=https://github.com/LineageOSPlus/runc/archive/master.zip
TERMUX_PKG_FOLDERNAME=runc-master

termux_step_make(){
	termux_setup_golang

	# make folder tree look as in expected by go
	mkdir -p go/src/github.com/opencontainers/runc
	cp -rf $TERMUX_PKG_SRCDIR/* go/src/github.com/opencontainers/runc/

	# set gopath
	export GOPATH=$(pwd)/go

	# issue the build command
	cd go/src/github.com/opencontainers/runc/
	unset LDFLAGS
	make  BUILDTAGS="selinux"
}


termux_step_make_install() {
	cp go/src/github.com/opencontainers/runc/runc $TERMUX_PREFIX/bin/docker-runc
}
