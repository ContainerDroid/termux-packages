TERMUX_PKG_HOMEPAGE=https://www.docker.com/
TERMUX_PKG_DESCRIPTION="An open and reliable container runtime"
TERMUX_PKG_VERSION=0.2.x
TERMUX_PKG_SHA256=b03cb2376c121b47b81c38033ef603ed398c4a3ec0e3502bb95ae2b638566fc5
TERMUX_PKG_SRCURL=https://github.com/LineageOSPlus/containerd/archive/v0.2.x.zip
TERMUX_PKG_FOLDERNAME=containerd-0.2.x

termux_step_make(){
	termux_setup_golang

	# make folder tree look as in expected by go
	mkdir -p go/src/github.com/containerd/containerd
	cp -rf $TERMUX_PKG_SRCDIR/* go/src/github.com/containerd/containerd/

	# set gopath
	export GOPATH=$(pwd)/go

	# issue the build command
	cd go/src/github.com/containerd/containerd
	export BUILDTAGS=no_btrfs
	make
}


termux_step_make_install() {
	cp go/src/github.com/containerd/containerd/bin/containerd-shim $TERMUX_PREFIX/bin/docker-containerd-shim
	cp go/src/github.com/containerd/containerd/bin/containerd $TERMUX_PREFIX/bin/docker-containerd
}
