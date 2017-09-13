#!/bin/bash

set -e -u

rm -rf bootstrap-debs && mkdir -p bootstrap-debs

for deb in \
	libc++_15.2_aarch64.deb \
	libandroid-support_22_aarch64.deb \
	busybox_1.27.1-2_aarch64.deb \
	liblzma_5.2.3_aarch64.deb \
	ncurses_6.0.20170827_aarch64.deb \
	readline_7.0.3_aarch64.deb \
	bash_4.4.12_aarch64.deb \
	gpgv_1.4.22_aarch64.deb \
	gnupg_1.4.22_aarch64.deb \
	libutil_0.3_aarch64.deb \
	dpkg_1.18.24_aarch64.deb \
	command-not-found_1.25_aarch64.deb \
	ca-certificates_20170607_all.deb \
	openssl_1.0.2l-1_aarch64.deb \
	libnghttp2_1.25.0_aarch64.deb \
	libcurl_7.55.1_aarch64.deb \
	apt_1.4.7_aarch64.deb
do
	ln -sf ../debs/${deb} bootstrap-debs/${deb}
done
