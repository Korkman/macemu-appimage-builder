#! /bin/sh
{
	# clear the clipboard on startup so it does not interfere with BII/SheepShaver
	
	set -eu
	
	SELF=$(readlink -f "$0")
	HERE=${SELF%/*}
	APPDIR=${SELF%/*}

	_no_clear_clip=no
	_only_clear_clip=no
	_count=$#
	while [ "$_count" -gt 0 ]
	do
		_arg="$1"
		shift
		_count=$((_count - 1))
		case "$_arg" in
			--help)
				echo "  --no-clear-clip"
				echo "    Disable X11 primary selection clear on launch."
				echo "  --only-clear-clip"
				echo "    Clear X11 primary selection and exit."
				set -- "$@" "$_arg"
				return
				;;
			--no-clear-clip)
				_no_clear_clip=yes
				;;
			--only-clear-clip)
				_only_clear_clip=yes
				;;
			*)
				set -- "$@" "$_arg"
				;;
		esac
	done

	if [ "$_no_clear_clip" = "yes" ]
	then
		return
	fi
	
	printf "" | "$HERE/usr/bin/xsel" -f &
	
	if [ "$_only_clear_clip" = "yes" ]
	then
		exit 0
	fi

}
