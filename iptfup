#!/bin/bash

# iptables-fuckup-prevention by e-caste 2019


function restore_tables {
	iptables-restore < $tmp_file
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
	echo "Simply run 'sudo $0 iptables <iptables options>' to automatically restore the previous rules in case of a fuck-up, like preventing all incoming TCP traffic."
	echo "For a more comfortable experience, you can either:"
	echo "- add an alias for iptables in your shell rc file like 'alias iptables=\"sudo $0 iptables\"'"
	echo "- add this repository's directory to your PATH"
	echo "- copy this script to a directory in your PATH, like /usr/local/bin"
	exit 0
fi

# if iptables -L run without any prevention
if [ "$2" = "-L" ]; then
	"$@"
	exit 0
fi

if [ "$EUID" -ne 0 ]; then
	echo "This script must be run as root."
	echo "Please run:"
	echo "sudo $0 $@"
	exit -1
fi

command -v iptables &> /dev/null
if [ $? -ne 0 ]; then
	echo "This script is called iptables-fuck-up-prevention, it is useless without iptables. Aborting..."
	exit -1
fi

if [ "$1" != "iptables" -a "$1" != "iptables-restore" ]; then
	echo "I see you're a funny guy. This script only works with iptables and iptables-restore though. Aborting..."
	exit -1
fi

if [ "$1" == "iptables" -a $# -eq 1 ]; then
	echo "iptables requires a rule as argument. Aborting..."
	exit -1
fi

trap sigint_handler INT

tmp_file=".tmp_iptables_state"
if [ -f $tmp_file ]; then
	echo "$tmp_file already exists in this directory. Please rename it, move it or delete it to proceed."
	exit -1
fi
iptables-save > $tmp_file

	echo "Running $@ as root."
	echo "If something goes wrong, this script will restore the previous iptables rules in 10 seconds."
	echo "" 
	if [ "$1" == "iptables" ]; then
		# run iptables command unfolding all arguments
		"$@"
	elif [ "$1" == "iptables-restore" ]; then
		# run iptables-restore command passing stdin
		"$@" <&0
	fi

# force the read to happen on /dev/tty since if we're handling iptables-restore we have redirected stdin
echo "Are these firewall rules working? y/N"
read -t 10 </dev/tty

echo ""

# if $ans is no or there is no ans since the connection has been closed
if [ -z $ans ]; then
	restore_tables
elif [ $ans = "n" -o $ans = "N" ]; then
	restore_tables
# if $ans confirms the rules
elif [ $ans = "y" -o $ans = "Y" ]; then
	echo "Rules applied."
fi

rm $tmp_file
exit 0
