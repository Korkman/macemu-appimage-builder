#! /bin/sh
{
	# fix SheepShaver startup: test for and change vm.mmap_min_addr if not set to 0,
	# give instructions for permanent solution. advise not to use it.
	
	set -eu
	
	me="$0"
	pauseAfterExecution="no"
	skipMmapChecks=${skipMmapChecks:-no}
	
	# wrapper to test if sudo is available
	sudo() {
		if ! command -v sudo > /dev/null
		then
			echo \
"sudo is unavailable. Please perform this step with root permissions:" \
			>&2
			echo "$@" >&2
			echo >&2
			return 1
		elif ! command sudo --validate > /dev/null 2>&1
		then
			echo \
"Your account is not permitted to use sudo (aka \"not in sudoers\").
Please perform this step with root permissions:" \
			>&2
			echo "$@" >&2
			echo >&2
			return 1
		else
			command sudo "$@"
		fi
	}
	
	# function to display a terminal in the likely event we were started via a GUI menu
	runVisible() {
		# try a few terminals
		absMe=$(realpath "$me")
		if command -v x-terminal-emulator > /dev/null; then exec x-terminal-emulator -e "$absMe" "$@";
		elif command -v konsole > /dev/null; then exec konsole -e "$absMe" "$@";
		elif command -v xfce4-terminal > /dev/null; then exec xfce4-terminal -x "$absMe" "$@";
		elif command -v gnome-terminal > /dev/null; then exec gnome-terminal -- "$absMe" "$@";
		elif command -v xterm > /dev/null; then exec xterm -e "$absMe" "$@";
		else
			# as last resort, we just hope the user is already running in a terminal
			exec "$absMe" "$@"
		fi
	}
	
	if [ "${1:-nada}" = "fix_mmap_selinux" ]
	then
		# SELinux handling
		shift
		echo \
"The SELinux policy mmap_low_allowed must be changed for SheepShaver
to run. Attempting to use sudo to change it temporarily.

For a permanent change (not recommended), run
'sudo setsebool -P mmap_low_allowed 1'

For information about the security impact, see
https://wiki.debian.org/mmap_min_addr
"
		if ! sudo setsebool mmap_low_allowed 1
		then
			pauseAfterExecution="yes"
			skipMmapChecks="yes"
			echo \
"Failed. SheepShaver will probably crash."
			echo "Press enter to continue ..."; read -r enter
		else
			echo \
"Success. The setting will revert after a host reboot."
			echo "Press enter to continue ..."; read -r enter
		fi
		
	elif [ "${1:-nada}" = "fix_mmap" ]
	then
		# sysctl handling
		shift
		echo \
"The sysctl value vm.mmap_min_addr must be 0 for SheepShaver to work.
Attempting to use sudo to change it temporarily.

For a permanent change (not recommended), run
'echo 'vm.mmap_min_addr=0' | sudo tee /etc/sysctl.d/10-mmap_min_addr-zero.conf'

For information about the security impact, see
https://wiki.debian.org/mmap_min_addr
"
		if ! sudo sysctl vm.mmap_min_addr=0 > /dev/null
		then
			pauseAfterExecution="yes"
			skipMmapChecks="yes"
			echo "Failed. SheepShaver will probably crash."
			echo "Press enter to continue ..."; read -r enter
		else
			echo \
"Success. The setting will revert after a host reboot."
			echo "Press enter to continue ..."; read -r enter
		fi
		
	fi
	
	if [ "$skipMmapChecks" != "yes" ]
	then
		# default case: detect low memory mmap status
		# SELinux
		if command -v selinuxenabled > /dev/null && selinuxenabled && sestatus -b | grep -E "mmap_low_allowed\\s+off" > /dev/null
		then
			# re-run self visible to show dialog
			runVisible "fix_mmap_selinux" "$@"
			exit 1
		fi
		# sysctl
		if [ "$(/usr/sbin/sysctl --values vm.mmap_min_addr)" != "0" ]
		then
			# re-run self visible to show dialog
			runVisible "fix_mmap" "$@"
			exit 1
		fi
	fi
	
	# run image
	
	return
}