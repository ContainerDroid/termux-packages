TERMUX_PKG_HOMEPAGE=https://www.docker.com/
TERMUX_PKG_DESCRIPTION="Docker daemon"
TERMUX_PKG_VERSION=master
TERMUX_PKG_SHA256=9fa91d67d2f43abdfcd8ef13a637ea28c50e7c0a764855a07674948098aba6dc
TERMUX_PKG_SRCURL=https://github.com/LineageOSPlus/moby/archive/master.zip
TERMUX_PKG_FOLDERNAME=moby-master
TERMUX_PKG_DEPENDS="docker-cli, docker-runc, docker-containerd"

termux_step_make(){
	termux_setup_golang

	mkdir -p go/src/github.com/docker/docker
	cp -rf $TERMUX_PKG_SRCDIR/* go/src/github.com/docker/docker/

	# set gopath
	export GOPATH=$(pwd)/go

	# issue the build command
	cd go/src/github.com/docker/docker
	unset LDFLAGS
	export DOCKER_GITCOMMIT=bcdca11
	export DOCKER_BUILDTAGS='exclude_graphdriver_btrfs exclude_graphdriver_devicemapper exclude_graphdriver_quota selinux exclude_graphdriver_aufs '
	./hack/make.sh dynbinary

}

termux_step_make_install() {
	cp go/src/github.com/docker/docker/bundles/17.06.0-dev/dynbinary-daemon/dockerd-17.06.0-dev  $TERMUX_DESTDIR/usr/bin/dockerd

	mkdir -p $TERMUX_DESTDIR/etc/docker/
	cat > $TERMUX_DESTDIR/etc/docker/docker.json << EOL
{
	"storage-driver": "overlay",
	"storage-opts": [
		"overlay.override_kernel_check=true"
	]
}
EOL

}
