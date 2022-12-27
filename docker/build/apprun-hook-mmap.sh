#! /bin/sh
{
	# fix SheepShaver startup: test for and change vm.mmap_min_addr if not set to 0,
	# give instructions for permanent solution. advise not to use it.
	
	set -eu
	
	me="$0"
	skipMmapChecks=${skipMmapChecks:-no}
	if [ "$skipMmapChecks" = "yes" ]
	then
		return
	fi
	
	mmapVisibleTerminal="unknown"
	
	if [ "${1:-nada}" = "--help" ]
	then
		echo "  --mmap-visible-terminal"
		echo "    (internally used only) Show mmap dialogs and exit."
		echo "  skipMmapChecks=no (environment variable)"
		echo "    Set to 'yes' to disable mmap checks."
		return
	fi
	
	# wrapper to test if sudo is available
	sudo() {
		# test if user is root (no sudo required)
		if [ "$(id -u)" -eq 0 ]
		then
			"$@"
			return
		fi
		
		# test if sudo is available
		if ! command -v sudo > /dev/null
		then
			echo \
"sudo is unavailable. Please perform this step with root permissions:" \
			>&2
			echo "$@" >&2
			echo >&2
			return 1
		# NOTE: "sudo -v" requires password entry on mx linux
		# NOTE 2: "sudo --non-interactive -l" requires password entry on fedora. "sudo -l" does not.
		# NOTE 3: "sudo -l" outputs only two lines on endeavour OS live iso
		# test if "sudo -l" outputs more than "User USER is not allowed to run sudo on HOST."
		elif LC_ALL=C command sudo -l | grep -q "is not allowed to run sudo"
		then
			echo \
"Your account is not permitted to use sudo (aka \"not in sudoers\").
Please perform this step with root permissions:" \
			>&2
			echo "$@" >&2
			echo >&2
			return 1
		# sudo is available and user is allowed to use it (still no guarantee sysctl / selinux is allowed)
		else
			command sudo "$@"
		fi
	}
	
	# function to display a terminal in the likely event we were started via a GUI menu
	runVisible() {
		# try a few terminals
		# NOTE: blocking behavior is not guaranteed. Therefore, we launch them non-blocking and wait with pgrep!
		absMe=$(realpath "$me")
		if command -v x-terminal-emulator > /dev/null; then
			x-terminal-emulator -e "$absMe" --mmap-visible-terminal &
		elif command -v konsole > /dev/null; then
			konsole -e "$absMe" --mmap-visible-terminal &
		elif command -v xfce4-terminal > /dev/null; then
			xfce4-terminal -x "$absMe" --mmap-visible-terminal &
		elif command -v gnome-terminal > /dev/null; then
			gnome-terminal -- "$absMe" --mmap-visible-terminal &
		elif command -v xterm > /dev/null; then
			xterm -e "$absMe" --mmap-visible-terminal &
		else
			# as last resort, we just hope the user is already running in a terminal
			"$absMe" --mmap-visible-terminal &
		fi
		while pgrep -f "$absMe --mmap-visible-terminal" > /dev/null
		do
			sleep 1
		done
	}
	
	if [ "${1:-nada}" = "--mmap-visible-terminal" ]
	then
		mmapVisibleTerminal="yes"
		shift
	fi
	
	# detect low memory mmap status
	# SELinux
	if command -v selinuxenabled > /dev/null && selinuxenabled && sestatus -b | grep -E "mmap_low_allowed\\s+off" > /dev/null
	then
		if [ "$mmapVisibleTerminal" != "yes" ]
		then
			# re-run self visible to show dialog
			runVisible "$@"
		else
			printf "\e]2;SheepShaver: Adjust SELinux policy\a"
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
				echo \
"Failed. SheepShaver will probably crash."
				echo "Press enter to continue ..."; read -r enter
			else
				echo \
"Success. The setting will revert after a host reboot."
				echo "Press enter to continue ..."; read -r enter
			fi
			exit 1
		fi
	fi
	
	# test if low mmap is allowed, take action if not
	if [ "$(cat /proc/sys/vm/mmap_min_addr)" != "0" ]
	then
		if [ "$mmapVisibleTerminal" != "yes" ]
		then
			# re-run self visible to show dialog
			runVisible "$@"
		else
			printf "\e]2;SheepShaver: Adjust sysctl policy\a"
			echo \
"The sysctl value vm.mmap_min_addr must be 0 for SheepShaver to work.
Attempting to use sudo to change it temporarily.

For a permanent change (not recommended), run
'echo \"vm.mmap_min_addr=0\" | sudo tee /etc/sysctl.d/10-mmap_min_addr-zero.conf'

For information about the security impact, see
https://wiki.debian.org/mmap_min_addr
"
			if ! sudo sh -c "echo 0 > /proc/sys/vm/mmap_min_addr"
			then
				echo "Failed. SheepShaver will probably crash."
				echo "Press enter to continue ..."; read -r enter
			else
				echo \
"Success. The setting will revert after a host reboot."
				echo "Press enter to continue ..."; read -r enter
			fi
			exit 1
		fi
	fi
	
	# run image
	
	return
}