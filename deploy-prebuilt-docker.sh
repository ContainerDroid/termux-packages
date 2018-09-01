#!/bin/bash

install -Dm0755 out/docker-containerd/massage/system/bin/docker-containerd      ../../lineage-15.1/vendor/lineage/prebuilt/aarch64/docker-containerd/docker-containerd
install -Dm0755 out/docker-containerd/massage/system/bin/docker-containerd-ctr  ../../lineage-15.1/vendor/lineage/prebuilt/aarch64/docker-containerd/docker-containerd-ctr
install -Dm0755 out/docker-containerd/massage/system/bin/docker-containerd-shim ../../lineage-15.1/vendor/lineage/prebuilt/aarch64/docker-containerd/docker-containerd-shim
install -Dm0755 out/docker-runc/massage/system/bin/docker-runc                  ../../lineage-15.1/vendor/lineage/prebuilt/aarch64/docker-runc/docker-runc
install -Dm0755 out/docker-tini/massage/system/bin/docker-init                  ../../lineage-15.1/vendor/lineage/prebuilt/aarch64/docker-tini/docker-init
install -Dm0755 out/docker/massage/system/bin/docker                            ../../lineage-15.1/vendor/lineage/prebuilt/aarch64/docker/docker
install -Dm0755 out/docker/massage/system/bin/dockerd                           ../../lineage-15.1/vendor/lineage/prebuilt/aarch64/docker/dockerd
install -Dm0755 out/docker/massage/system/bin/docker-checkconfig                ../../lineage-15.1/vendor/lineage/prebuilt/common/bin/docker-checkconfig
#install -Dm0644 out/docker/massage/system/etc/docker/daemon.json                ../../lineage-15.1/vendor/lineage/prebuilt/common/etc/docker/daemon.json
install -Dm0766 out/libtool/subpackages/libltdl/massage/system/lib/libltdl.so   ../../lineage-15.1/vendor/lineage/prebuilt/aarch64/libtool/libltdl.so
#install -Dm0766 out/busybox/massage/system/bin/busybox                          ../../lineage-15.1/vendor/lineage/prebuilt/aarch64/busybox/busybox
