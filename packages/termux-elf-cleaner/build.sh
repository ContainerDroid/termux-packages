TERMUX_PKG_HOMEPAGE=https://github.com/termux/termux-elf-cleaner
TERMUX_PKG_DESCRIPTION="Cleaner of ELF files for Android"
# NOTE: The termux-elf-cleaner.cpp file is used by build-package.sh
#       to create a native binary. Bumping this version will need
#       updating the checksum used there.
TERMUX_PKG_VERSION=1.1
TERMUX_PKG_REVISION=1
TERMUX_PKG_SRCURL=https://github.com/LineageOSPlus/termux-elf-cleaner/archive/v${TERMUX_PKG_VERSION}-lineageplus.tar.gz
TERMUX_PKG_SHA256=a30ac823f8a368682a162ce4eac3f99fd49535eeda42885b0fd3297192ef4b9e
TERMUX_PKG_FOLDERNAME=termux-elf-cleaner-${TERMUX_PKG_VERSION}-lineageplus
TERMUX_PKG_BUILD_IN_SRC=yes
