TERMUX_PKG_HOMEPAGE=https://www.docker.com/
TERMUX_PKG_DESCRIPTION="Docker client"
TERMUX_PKG_VERSION=master
TERMUX_PKG_SHA256=0042a747f1a2021e132dabb2058fe055ac7e1a66a87e0141f4542d1ebc734f0c
TERMUX_PKG_SRCURL=https://github.com/LineageOSPlus/cli/archive/master.zip
TERMUX_PKG_FOLDERNAME=cli-master

termux_step_make(){
	termux_setup_golang


	# make folder tree look as in expected by go
	mkdir -p go/src/github.com/docker/cli
	cp -rf $TERMUX_PKG_SRCDIR/* go/src/github.com/docker/cli/

	# set gopath
	export GOPATH=$(pwd)/go

	# issue the build command
	cd go/src/github.com/docker/cli
	export DISABLE_WARN_OUTSIDE_CONTAINER=1
	make
}


termux_step_make_install() {
	cp go/src/github.com/docker/cli/build/docker-android-arm64 $TERMUX_PREFIX/bin/docker
}
