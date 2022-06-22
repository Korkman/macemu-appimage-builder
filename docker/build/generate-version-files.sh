#! /bin/bash
{
	set -eu
	
	. /etc/lsb-release
	
	echo "$DISTRIB_DESCRIPTION" > version-os
	
	(cd /usr/local/src/macemu && echo "$(git config --get remote.origin.url) @ $(git log -1 --format="%ad") ($(git rev-parse --short HEAD))") > version-macemu
	
	if [ -e /usr/local/src/xen ]
	then
		(cd /usr/local/src/xen && echo "$(git config --get remote.origin.url) @ $(git log -1 --format="%ad") ($(git rev-parse --short HEAD))") > version-xen
	fi
	
	if command -v linuxdeploy > /dev/null
	then
		linuxdeploy --version > version-linuxdeploy 2>&1
	fi
	
	cat version-* | md5sum | cut -c 1-7 > version-sum
	
	exit
}
