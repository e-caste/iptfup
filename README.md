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

Simply use `iptables <new firewall rule>`. The iptables fuck-up prevention will come in handy if you ever make a mistake that would be irreparable without it.  
Also supported:  
`iptables -L` to list all the currently active rules  
`iptables -F` to remove all the current rules  
`iptables-restore < /path/to/iptables.rules` to restore a ruleset from a file1
