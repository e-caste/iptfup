# iptfup

This script tries to prevent fuck-ups when setting a new iptables firewall rule, such as one that blocks your very connection to the server you're adding it to.

## Installation

Clone this repo:  
`git clone https://github.com/e-caste/iptfup`  
Add these lines to your shell's rc file (e.g. ~/.zshrc or ~/.bashrc):  
```
# add repository to PATH
PATH=$PATH:/the/path/where/you/have/cloned/the/repo
# enable iptables fuck-up prevention
alias iptables="sudo iptfup iptables"
alias iptables-restore="sudo iptfup iptables-restore"
```
Done ✅

## Usage

Simply use `iptables <new firewall rule or policy>`. The iptables fuck-up prevention will come in handy if you ever make a mistake that would be irreparable without it. 

Also supported:  
- `iptables -L` to list all the currently active rules
- `iptables -F` to remove all the current rules
- `iptables-restore < /path/to/iptables.rules` to restore a ruleset from a file

The script also support saving rules directly to an arbitrary path without saving them to a temporary file first and then moving them to the desired location. The syntax is slightly different from the official `iptables-save`:

`iptables-save /path/to/iptables.rules`

If the file already exists a backup copy is created with the same name and the `.iptfup-backup` extension. If the backup file already exists it gets overwritten.

## Environment variables

- `IPTFUP_TIMER` accepts a numeric value that represents the countdown timer in seconds. The default is 10 seconds.

- `IPTFUP_RULES_PATH` is the file to which iptfup will automatically save the rules upon confirmation. If left empty the rules will not be saved automatically. In case the file already exists it will be backed up to the current directory with the name `iptfup-rules-backup`. Subsequent backups to the same file will overwrite each other.  
Examples: on Debian-based distros it should be set to `/etc/iptables/iptables.rules`, on RedHat distros (Fedora, CentOS) it should be set to `/etc/sysconfig/iptables`
