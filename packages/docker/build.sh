TERMUX_PKG_HOMEPAGE=https://www.docker.com/
TERMUX_PKG_DESCRIPTION="Docker CLI and Daemon"
TERMUX_PKG_VERSION=18.04.0
TERMUX_PKG_SHA256=7bd16f2a97dcfaa450e42d5f5d838e490feb1db3933fa187859b487c45fee253
TERMUX_PKG_SRCURL=https://github.com/docker/docker-ce/archive/v${TERMUX_PKG_VERSION}-ce.tar.gz
TERMUX_PKG_FOLDERNAME=docker-ce-${TERMUX_PKG_VERSION}-ce
TERMUX_PKG_DEPENDS="docker-containerd, docker-runc, docker-tini, libltdl"
GO_WORKSPACE_CLI="${TERMUX_PKG_BUILDDIR}/go/src/github.com/docker/cli"
GO_WORKSPACE_DOCKER="${TERMUX_PKG_BUILDDIR}/go/src/github.com/docker/docker"

termux_step_make() {
	termux_setup_golang

	export GOPATH=$(pwd)/go

	# docker cli
	mkdir -p ${GO_WORKSPACE_CLI}
	cp -rf $TERMUX_PKG_SRCDIR/components/cli/* ${GO_WORKSPACE_CLI}
	export DISABLE_WARN_OUTSIDE_CONTAINER=1
	export VERSION="v${TERMUX_PKG_VERSION}-ce"
	(cd ${GO_WORKSPACE_CLI}; make dynbinary)

	# dockerd
	mkdir -p ${GO_WORKSPACE_DOCKER}
	cp -rf $TERMUX_PKG_SRCDIR/components/engine/* ${GO_WORKSPACE_DOCKER}

	# Tag v18.04.0-ce
	export DOCKER_GITCOMMIT=3d479c0af67cb9ea43a9cfc1bf2ef097e06a3470
	export DOCKER_BUILDTAGS='exclude_graphdriver_btrfs exclude_graphdriver_devicemapper exclude_graphdriver_quota selinux exclude_graphdriver_aufs '
	(cd ${GO_WORKSPACE_DOCKER}; ./hack/make.sh dynbinary)
}

termux_step_make_install() {
	install -Dm 0755 ${GO_WORKSPACE_DOCKER}/bundles/dynbinary-daemon/dockerd-${VERSION} \
	                 ${TERMUX_DESTDIR}/${USR}/bin/dockerd
	install -Dm 0755 ${TERMUX_PKG_SRCDIR}/components/engine/contrib/check-config.sh \
	                 ${TERMUX_DESTDIR}/${USR}/bin/docker-checkconfig

	mkdir -p ${TERMUX_DESTDIR}/${ETC}/docker/
	cat > ${TERMUX_DESTDIR}/${ETC}/docker/daemon.json <<-EOL
	{
	    "data-root": "/${VAR}/lib/docker",
	    "exec-root": "/${VAR}/run/docker",
	    "pidfile": "/${VAR}/run/docker.pid",
	    "hosts": [
	        "unix:///${VAR}/run/docker.sock"
	    ],
	    "storage-driver": "overlay",
	    "storage-opts": [
	        "overlay.override_kernel_check=true"
	    ]
	}
	EOL

	install -Dm 0755 ${GO_WORKSPACE_CLI}/build/docker-android-${GOARCH} \
	                 ${TERMUX_DESTDIR}/${USR}/bin/docker
}
