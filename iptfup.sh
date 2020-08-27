#!/bin/bash

# iptables-fuckup-prevention by e-caste 2019


function restore_tables {
	iptables-restore < "$tmp_file"
	echo "Restored old firewall rules."
}

function sigint_handler {
	echo ""
	echo "Ignoring SIGINT to prevent undeterministic behaviour."
	echo "Please be patient."
	echo ""
}

if [ "$1" = "-h" -o "$1" = "--help" ]; then
	echo "This script is intended to prevent fuck-ups when setting a new iptables rule."
	echo "Simply run either:"
	echo "    - 'sudo $0 iptables <iptables options>'"
	echo "    - 'sudo $0 iptables-restore <options> < /path/to/iptables.rules'"
	echo "to automatically restore the previous rules in case of a fuck-up, like preventing all incoming TCP traffic."
	echo ""
	echo "A sub-command iptables-save is available to easily write the rules to disk without redirecting input to a local file and moving it."
	echo "This command does not however use output redirection as iptables-save does as that happens at the shell level and can't be intercepted."
	echo "Instead, the command accepts a filename as the only argument and writes the rules to that file:"
	echo "    - iptables-save <filename>"
	echo "If a file in that location with the same name already exists it gets copied to a .iptfup-backup file first."
	echo ""
	echo "For a more comfortable experience, you can either:"
	echo "    - add an alias for iptables in your shell rc file, like:"
	echo "          - 'alias iptables=\"sudo $0 iptables\"'"
	echo "          - 'alias iptables-restore=\"sudo $0 iptables-restore\"'"
	echo "          - 'alias iptables-save=\"sudo $0 iptables-save\"'"
	echo "    - add this repository's directory to your PATH"
	echo "    - copy this script to a directory in your PATH, like /usr/local/bin"
	exit 0
fi

if [ "$EUID" -ne 0 ]; then
	echo "This script must be run as root."
	echo "Please run:"
	echo "sudo $0 $@"
	exit -1
fi

if [ "$1" = "iptables" ]; then
	if [ $# -eq 1 ]; then
		echo "iptables requires at least one argument. Aborting..."
		exit -1
	fi

	command -v iptables &> /dev/null
	if [ $? -ne 0 ]; then
		echo "This script is called iptables-fuck-up-prevention, it is useless without iptables. Aborting..."
		exit -1
	fi
elif [ "$1" = "iptables-restore" ]; then
	command -v iptables-restore &> /dev/null
	if [ $? -ne 0 ]; then
		echo "This script was unable to locate the iptables-restore binary. Aborting..."
		exit -1
	fi
elif [ "$1" = "iptables-save" ]; then
	if [ $# -ne 2 ]; then
		echo "iptables-save requires exactly one argument (the file name). Aborting..."
		exit -1
	fi

	command -v iptables-save &> /dev/null
	if [ $? -ne 0 ]; then
		echo "This script was unable to locate the iptables-save binary. Aborting..."
		exit -1
	fi
else
	echo "I see you're a funny guy. This script only works with iptables, iptables-restore and iptables-save though. Aborting..."
	exit -1
fi

# if iptables -L run without any prevention
if [ "$2" = "-L" ]; then
	"$@"
	exit 0
fi

trap sigint_handler INT

if [ "$1" == "iptables-save" ]; then
	echo "Saving iptables rules to $2..."
	echo ""

	# If the file already exists then create a backup copy (and if a backup already exists, just overwrite it)
	if [ -f "$2" ]; then
		echo "Backing up existing file $2 to $2.iptfup-backup..."
		echo ""

		cp -f "$2" "$2.iptfup-backup" &>/dev/null
		if [ $? -ne 0 ]; then
			echo "Error creating backup copy. Make sure you provided a valid path. Aborting..."
			exit -1
		fi
	fi

	iptables-save > "$2"
	if [ $? -ne 0 ]; then
		echo "Error executing iptables-save. Make sure you provided a valid path. Aborting..."
		exit -1
	else
		echo "Operation completed."

		# Exit now as we don't need confirmation
		exit 0
	fi
fi

tmp_file=".tmp_iptables_state"
if [ -f "$tmp_file" ]; then
	echo "$tmp_file already exists in this directory. Please rename it, move it or delete it to proceed."
	exit -1
fi

# if the IPTFUP_TIMER environment variable is defined and is a valid number, set the timer to that value
if [ ! -z "${IPTFUP_TIMER##*[!0-9]*}" ]; then
	timer="$IPTFUP_TIMER"
else
	# iptfup default
	timer=10
fi

iptables-save > "$tmp_file"
	
# run command unfolding all arguments (and passing stdin if the command is iptables-restore)

	echo "Running $@ as root."
	echo "If something goes wrong, this script will restore the previous iptables rules in $timer seconds."
	echo ""
	if [ "$1" == "iptables" ]; then
		"$@"
	elif [ "$1" == "iptables-restore" ]; then
		"$@" <&0
	fi

# force the read to happen on /dev/tty since if we're handling iptables-restore we have redirected stdin
echo "Are these firewall rules working? y/N"
read -t $timer ans </dev/tty

echo ""

# if $ans is different from case-insensitive y, then restore the rules
# this can happen if the user presses n or any other key or if the connection got closed by a bad rule
if [ "$ans" = "y" -o "$ans" = "Y" ]; then
	echo "Rules applied."
else
	restore_tables
fi

rm "$tmp_file"
exit 0
