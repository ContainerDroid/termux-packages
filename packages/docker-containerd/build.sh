TERMUX_PKG_HOMEPAGE=https://www.docker.com/
TERMUX_PKG_DESCRIPTION="An open and reliable container runtime"
TERMUX_PKG_VERSION=18.04.0
CONTAINERD_GIT_COMMIT=773c489c9c1b21a6d78b5c538cd395416ec50f88
TERMUX_PKG_SHA256=a4a8ad8d4cf96d6d0a65065f449d3c6ba747e1f350a7fcc117c61aa0f14b3f86
TERMUX_PKG_SRCURL=https://github.com/containerd/containerd/archive/${CONTAINERD_GIT_COMMIT}.zip
TERMUX_PKG_FOLDERNAME=containerd-${CONTAINERD_GIT_COMMIT}

termux_step_make() {
	# Create ${GO_WORKSPACE} and add it to ${GOPATH}
	termux_setup_golang --mimic-go-get-workspace "src/github.com/containerd/containerd"

	# issue the build command
	export BUILDTAGS=no_btrfs
	(cd ${GO_WORKSPACE}; make)
}

termux_step_make_install() {
	install -Dm 0755 ${GO_WORKSPACE}/bin/containerd-shim \
	                 ${TERMUX_DESTDIR}/${USR}/bin/docker-containerd-shim
	install -Dm 0755 ${GO_WORKSPACE}/bin/containerd \
	                 ${TERMUX_DESTDIR}/${USR}/bin/docker-containerd
	install -Dm 0755 ${GO_WORKSPACE}/bin/ctr \
	                 ${TERMUX_DESTDIR}/${USR}/bin/docker-containerd-ctr
}
