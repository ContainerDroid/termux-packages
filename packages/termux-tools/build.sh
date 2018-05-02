TERMUX_PKG_HOMEPAGE=https://termux.com/
TERMUX_PKG_DESCRIPTION="Basic system tools for Termux"
TERMUX_PKG_VERSION=0.56
TERMUX_PKG_PLATFORM_INDEPENDENT=yes
TERMUX_PKG_ESSENTIAL=yes
TERMUX_PKG_DEPENDS="termux-am"
TERMUX_PKG_CONFFILES="${ETC}/motd"

termux_step_make_install () {
	mkdir -p ${TERMUX_DESTDIR}/${USR}/bin/applets
	# Remove LD_LIBRARY_PATH from environment to avoid conflicting
	# with system libraries that system binaries may link against:
	for tool in df getprop logcat ping ping6 ip pm settings; do
		WRAPPER_FILE=${TERMUX_DESTDIR}/${USR}/bin/$tool
		echo '#!/bin/sh' > $WRAPPER_FILE
		echo 'unset LD_LIBRARY_PATH LD_PRELOAD' >> $WRAPPER_FILE
		# Some tools require having /system/bin/app_process in the PATH,
		# at least am&pm on a Nexus 6p running Android 6.0:
		echo -n 'PATH=$PATH:/system/bin ' >> $WRAPPER_FILE
		echo "exec /system/bin/$tool \"\$@\"" >> $WRAPPER_FILE
		chmod +x $WRAPPER_FILE
	done

	cp -p $TERMUX_PKG_BUILDER_DIR/{dalvikvm,su,termux-fix-shebang,termux-reload-settings,termux-setup-storage,chsh,termux-open-url,termux-wake-lock,termux-wake-unlock,login,pkg,termux-open,termux-info} ${TERMUX_DESTDIR}/${USR}/bin/
	termux_fixup_target_paths ${TERMUX_DESTDIR}/${USR}/bin/dalvikvm

	cp $TERMUX_PKG_BUILDER_DIR/motd ${TERMUX_DESTDIR}/${ETC}/motd
	(cd ${TERMUX_DESTDIR}/${USR}/bin; ln -s -f termux-open xdg-open)
}
