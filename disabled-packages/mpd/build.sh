TERMUX_PKG_HOMEPAGE="https://www.musicpd.org"
TERMUX_PKG_DESCRIPTION="music player daemon"
TERMUX_PKG_VERSION=0.20.9
TERMUX_PKG_SHA256=9c3eb601f0f8b2591c6398fc2a91d9c88643d4850363e9d0dbf545437516a9e8
TERMUX_PKG_SRCURL=https://github.com/MusicPlayerDaemon/MPD/archive/v$TERMUX_PKG_VERSION.tar.gz
TERMUX_PKG_FOLDERNAME=MPD-$TERMUX_PKG_VERSION
TERMUX_PKG_DEPENDS="libcurl, libid3tag, libopus, libevent, fftw, libpulseaudio, libmpdclient, boost, openal-soft, libvorbis, libsqlite, ffmpeg"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--disable-alsa
--disable-ao
--disable-epoll
--disable-expat
--disable-iconv
--disable-icu
--disable-mad
--disable-sndio
--without-tremor
"
TERMUX_PKG_BUILD_IN_SRC=yes
TERMUX_PKG_CONFFILES="$TERMUX_DESTDIR/etc/mpd.conf"

termux_step_pre_configure() {
	CXXFLAGS+=" -DTERMUX -UANDROID"
	LDFLAGS+=" -llog -lOpenSLES"
	NOCONFIGURE=1	./autogen.sh
	rm -f /data/data/com.termux/files/usr/etc/mpd.conf
}

termux_step_make_install () {
	# Try to work around OpenSL ES library clashes:
	# Linking against libOpenSLES causes indirect linkage against
	# libskia.so, which links against the platform libjpeg.so and
	# libpng.so, which are not compatible with the Termux ones.
	#
	# On Android N also liblzma seems to conflict.
	make install
	cp -f $TERMUX_DESTDIR/usr/share/doc/mpd/mpdconf.example /data/data/com.termux/files/usr/etc/mpd.conf
	mkdir -p $TERMUX_DESTDIR/usr/libexec
	mkdir -p $TERMUX_DESTDIR/var/mpd
	mv $TERMUX_DESTDIR/usr/bin/mpd $TERMUX_DESTDIR/usr/libexec
	local SYSTEM_LIBFOLDER=lib64
	if [ $TERMUX_ARCH_BITS = 32 ]; then SYSTEM_LIBFOLDER=lib; fi

	echo "#!/bin/sh" > $TERMUX_DESTDIR/usr/bin/mpd
	cat $TERMUX_SCRIPTDIR/packages/mpd/mpd-script.sh >> $TERMUX_DESTDIR/usr/bin/mpd
	# Work around issues on devices having ffmpeg libraries
	# in a system vendor dir, reported by live_the_dream on #termux:
	local FFMPEG_LIBS="" lib
	# c++_shared needs to go first in every c++ app that uses audio directly.
	for lib in c++_shared curl ssl event opus vorbis avcodec avfilter avformat avutil postproc swresample swscale sqlite3; do
		if [ -n "$FFMPEG_LIBS" ]; then FFMPEG_LIBS+=":"; fi
		FFMPEG_LIBS+="$TERMUX_DESTDIR/usr/lib/lib${lib}.so"
	done
	echo "export LD_PRELOAD=$FFMPEG_LIBS" >> $TERMUX_DESTDIR/usr/bin/mpd
	chmod +x $TERMUX_DESTDIR/usr/bin/mpd
	# /system/vendor/lib(64) needed for libqc-opt.so on
	# a xperia z5 c, reported by BrainDamage on #termux:
	echo "LD_LIBRARY_PATH=/system/$SYSTEM_LIBFOLDER:/system/vendor/$SYSTEM_LIBFOLDER:/usr/lib exec /usr/libexec/mpd \"\$@\"" >> $TERMUX_DESTDIR/usr/bin/mpd
}

termux_step_create_debscripts() {
	echo "#!/bin/sh" > postinst
	echo 'mkdir -p $HOME/.mpd/playlists' >> postinst
}
