#! /bin/sh

{
	set -eu
	
	if [ "${1:-nada}" = "--help" ]
	then
		echo "  --install"
		echo "    Copy AppImage binary to home dir and create GUI menu entries."
		echo "  --uninstall"
		echo "    Remove GUI menu entries and delete AppImage binary."
		echo "  --add-menu-item (default on --install)"
		echo "    Create a single GUI menu entry with multiple launch options."
		echo "  --add-settings-menu-item"
		echo "    Create a dedicated 'force settings' GUI menu item."
		echo "  --remove-menu-items"
		echo "    Remove GUI menu entries."
		return
	fi
	
	# quick return if no recognized argument is present
	if [ "${1:-}" != "--install" ] \
		&& [ "${1:-}" != "--uninstall" ] \
		&& [ "${1:-}" != "--add-menu-item" ] \
		&& [ "${1:-}" != "--add-settings-menu-item" ] \
		&& [ "${1:-}" != "--remove-menu-items" ]
	then
		return
	fi
	
	SELF=$(readlink -f "$0")
	HERE=${SELF%/*}
	APPDIR=${SELF%/*}
	METAPREFIX="com.github.korkman.macemu"
	if [ -e "$HERE/BasiliskII.desktop" ]
	then
		PRODUCT="BasiliskII"
	elif [ -e "$HERE/SheepShaver.desktop" ]
	then
		PRODUCT="SheepShaver"
	else
		echo "Internal failure: .desktop file not present"
		exit 1
	fi

	
	if command -v systemd-path > /dev/null
	then
		binDir="$(env --ignore-environment systemd-path user-binaries)"
		iconsDir="$(env --ignore-environment systemd-path user-shared)/icons"
		appsDir="$(env --ignore-environment systemd-path user-shared)/applications"
	else
		echo "WARNING: systemd-path not found, falling back to hardcoded defaults"
		trueHome=$(getent passwd "$(id -u -n)" | cut -d ":" -f 6)
		binDir="$trueHome/.local/bin"
		iconsDir="$trueHome/.local/share/icons"
		appsDir=~"$trueHome/.local/share/applications"
	fi
	
	if [ "${1:-}" = "--install" ]
	then
		appBasename=$(basename "$APPIMAGE")
		destFile="$binDir/${PRODUCT}.AppImage"
		if [ "$destFile" != "$APPIMAGE" ]
		then
			printf "Installing to $destFile ..."
			mkdir -p "$binDir"
			if [ -e "$destFile" ]
			then
				echo
				echo "File already exists: $destFile"
				echo "Overwrite? (Y/n)"
				read -r REPLY
				if [ "$REPLY" != "Y" ] && [ "$REPLY" != "y" ] && [ "$REPLY" != "" ]
				then
					echo "Aborted."
					exit 2
				fi
				printf "Overwriting ..."
			fi
			
			cp "$APPIMAGE" "$destFile"
			echo " done."
		else
			echo "Already placed at destination $destFile"
		fi
		# remove previously default separate menu items to install a single item
		"$destFile" --remove-menu-items
		"$destFile" --add-menu-item
		
		if [ "$destFile" != "$APPIMAGE" ]
		then
			echo "Delete installer? (Y/n)"
			read -r REPLY
			if [ "$REPLY" != "Y" ] && [ "$REPLY" != "y" ] && [ "$REPLY" != "" ]
			then
				echo "Installer file kept."
			else
				# NOTE: attempts to decouple rm so it works under all circumstances failed
				rm -f "$APPIMAGE" || echo -e "Could not delete self, please execute:\nrm \"$APPIMAGE\""
			fi
		fi
		
		exit
	fi
	
	if [ "${1:-}" = "--uninstall" ]
	then
		printf "Uninstall $APPIMAGE ? (y/N)"
		read -r REPLY
		if [ "$REPLY" != "Y" ] && [ "$REPLY" != "y" ]
		then
			echo "Aborted."
			exit 2
		fi
		
		"$APPIMAGE" --remove-menu-items
		
		printf "Deleting myself ..."
		rm -f "$APPIMAGE"
		echo " done."
		
		exit
	fi
	
	if [ "${1:-}" = "--add-settings-menu-item" ]
	then
		printf "Adding settings GUI menu item ..."
		mkdir -p "$iconsDir"
		mkdir -p "$appsDir"
		
		# install icon
		cat "$HERE/usr/share/icons/${PRODUCT}GUI.png" > "$iconsDir/${METAPREFIX}.${PRODUCT}.gui.png"
		
		# install desktop file, patch execution path
		
		cat "$HERE/${PRODUCT}GUI.desktop.in" | sed "
			s|%EXEC_NAME%|$APPIMAGE|;
			s|%APP_NAME%|${PRODUCT}|;
			s|%ICON_NAME%|${METAPREFIX}.${PRODUCT}|
		" > $appsDir/${METAPREFIX}.${PRODUCT}.gui.desktop
		
		echo " done."
		exit
	fi
	
	if [ "${1:-}" = "--add-menu-item" ]
	then
		printf "Adding menu item ..."
		mkdir -p "$iconsDir"
		mkdir -p "$appsDir"
		
		# install icon
		cat "$HERE/${PRODUCT}.png" > "$iconsDir/${METAPREFIX}.${PRODUCT}.png"
		
		# install desktop file, patch execution path
		
		cat "$HERE/${PRODUCT}.desktop.in" | sed "
			s|%EXEC_NAME%|$APPIMAGE|;
			s|%APP_NAME%|${PRODUCT}|;
			s|%ICON_NAME%|${METAPREFIX}.${PRODUCT}|
		" > $appsDir/${METAPREFIX}.${PRODUCT}.desktop
		
		echo " done."
		exit
	fi
	
	if [ "${1:-}" = "--remove-menu-items" ]
	then
		printf "Removing menu items ..."
		rm -f "$appsDir/${METAPREFIX}.${PRODUCT}.desktop" || echo "Desktop file did not exist"
		rm -f "$appsDir/${METAPREFIX}.${PRODUCT}.gui.desktop" || echo "Desktop file did not exist (GUI)"
		rm -f "$iconsDir/${METAPREFIX}.${PRODUCT}.png" || echo "Icon did not exist"
		rm -f "$iconsDir/${METAPREFIX}.${PRODUCT}.gui.png" || echo "Icon did not exist (GUI)"
		echo " done."
		exit
	fi
}
