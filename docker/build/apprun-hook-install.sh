#! /bin/sh

{
	set -eu
	
	# quick return if no recognized argument is present
	if [ "${1:-}" != "--install" ] && [ "${1:-}" != "--uninstall" ] && [ "${1:-}" != "--add-menu-items" ] && [ "${1:-}" != "--remove-menu-items" ]
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
		binDir="$(systemd-path user-binaries)"
		iconsDir="$(systemd-path user-shared)/icons"
		appsDir="$(systemd-path user-shared)/applications"
	else
		echo "WARNING: systemd-path not found, falling back to hardcoded defaults"
		binDir=~/.local/bin
		iconsDir=~/.local/share/icons
		appsDir=~/.local/share/applications
	fi
	
	if [ "${1:-}" = "--install" ]
	then
		appBasename=$(basename "$APPIMAGE")
		destFile="$binDir/${PRODUCT}.AppImage"
		if [ "$destFile" != "$APPIMAGE" ]
		then
			echo -n "Installing to $destFile ..."
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
				echo -n "Overwriting ..."
			fi
			
			cp "$APPIMAGE" "$destFile"
			echo " done."
		else
			echo "Already placed at destination $destFile"
		fi
		"$destFile" --add-menu-items
		
		if [ "$destFile" != "$APPIMAGE" ]
		then
			echo "Delete original file $APPIMAGE? (Y/n)"
			read -r REPLY
			if [ "$REPLY" != "Y" ] && [ "$REPLY" != "y" ] && [ "$REPLY" != "" ]
			then
				echo "Original file kept."
				exit
			fi
			rm -f "$APPIMAGE"
		fi
		
		exit
	fi
	
	if [ "${1:-}" = "--uninstall" ]
	then
		echo -n "Uninstall $APPIMAGE ? (y/N)"
		read -r REPLY
		if [ "$REPLY" != "Y" ] && [ "$REPLY" != "y" ]
		then
			echo "Aborted."
			exit 2
		fi
		
		"$APPIMAGE" --remove-menu-items
		
		echo -n "Deleting myself ..."
		rm -f "$APPIMAGE"
		echo " done."
		
		exit
	fi
	
	if [ "${1:-}" = "--add-menu-items" ]
	then
		echo -n "Adding menu items ..."
		mkdir -p "$iconsDir"
		mkdir -p "$appsDir"
		
		# TODO: should we support multiple parallel installations?
		
		# install icon
		cat "$HERE/${PRODUCT}.png" > "$iconsDir/${METAPREFIX}.${PRODUCT}.png"
		cat "$HERE/usr/share/icons/${PRODUCT}GUI.png" > "$iconsDir/${METAPREFIX}.${PRODUCT}.gui.png"
		
		# install desktop file, patch execution path
		grep -Ev '^(Name|Icon|Exec)=.*' "$HERE/${PRODUCT}.desktop" > "$appsDir/${METAPREFIX}.${PRODUCT}.desktop"
		{
			echo "Exec=$APPIMAGE --nogui true";
			echo "Icon=${METAPREFIX}.${PRODUCT}.png";
			echo "Name=${PRODUCT}";
		} >> "$appsDir/${METAPREFIX}.${PRODUCT}.desktop"
		
		grep -Ev '^(Name|Icon|Exec)=.*' "$HERE/${PRODUCT}.desktop" > "$appsDir/${METAPREFIX}.${PRODUCT}.gui.desktop"
		{
			echo "Exec=$APPIMAGE --nogui false"
			echo "Icon=${METAPREFIX}.${PRODUCT}.gui.png"
			echo "Name=${PRODUCT}GUI"
		} >> "$appsDir/${METAPREFIX}.${PRODUCT}.gui.desktop"
		
		echo " done."
		exit
	fi
	
	if [ "${1:-}" = "--remove-menu-items" ]
	then
		echo -n "Removing menu items ..."
		rm -f "$appsDir/${METAPREFIX}.${PRODUCT}.desktop" || echo "Desktop file did not exist"
		rm -f "$appsDir/${METAPREFIX}.${PRODUCT}.gui.desktop" || echo "Desktop file did not exist (GUI)"
		rm -f "$iconsDir/${METAPREFIX}.${PRODUCT}.png" || echo "Icon did not exist"
		echo " done."
		exit
	fi
}