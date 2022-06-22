#! /bin/sh
{
    set -eu
    
	SELF=$(readlink -f "$0")
	HERE=${SELF%/*}
    
	if [ "${1:-nada}" = "--version" ]
	then
        if [ -e "$HERE/usr/local/bin/SheepShaver" ]; then
            printf "SheepShaver "
        fi
        if [ -e "$HERE/usr/local/bin/BasiliskII" ]; then
            printf "BasiliskII "
        fi
		echo "AppImage edition version $(cat "$HERE/usr/local/share/version-sum")"
        echo "  built at $(LC_ALL=C date -ur "$HERE") with"
        echo "  $(cat "$HERE/usr/local/share/version-os")"
		echo "  $(cat "$HERE/usr/local/share/version-macemu" | sed 's/ @ /\n    @ /')"
		echo "  $(cat "$HERE/usr/local/share/version-macemu-appimage-builder" | sed 's/ @ /\n    @ /')"
        if [ -e "$HERE/usr/local/share/version-xen" ]
        then
            echo "  $(cat "$HERE/usr/local/share/version-xen" | sed 's/ @ /\n    @ /')"
        fi
        if [ -e "$HERE/usr/local/share/version-linuxdeploy" ]
        then
            echo "  $(cat "$HERE/usr/local/share/version-linuxdeploy" | sed 's/, /,\n    /')"
        fi
		echo
        # SheepShaver does not support --version. Also, it is currently not meaningful at all.
        # Therefore, exit here
        exit
	fi
	if [ "${1:-nada}" = "--help" ]
	then
		echo "AppImage built-ins:"
		echo "  --appimage-mount"
		echo "    Mount bundled content to a temporary location and output location."
		echo "  --appimage-extract"
		echo "    Extract bundled content to 'squashfs-root'"
		echo "  see also https://docs.appimage.org/user-guide/run-appimages.html"
		echo 
		echo "AppImage custom arguments and environment variables:"
		echo "  --sdlrender software"
		echo "    Use '--sdlrender auto' to re-enable default behavior"
		echo "    (use opengl if available)."
		echo "  APP_GTK_THEME=yes (environment variable)"
		echo "    Set to 'no' to try and use native GTK theme instead of bundled."
		echo "    Or set to any bundled theme name: "
		echo "    $(ls -m "$HERE/usr/share/themes")"
		echo "  pauseAfterExecution=no (environment variable)"
		echo "    Set to 'yes' to pause after execution."
	fi

    return
}