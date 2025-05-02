#!/bin/bash

if [ '!' -z "${NO_DNF_UPDATE}" ]; then
	sudo dnf update -y
fi

dnfinstall() {
  sudo dnf install -y $@
}

dnfinstall vim git wget curl
dnfinstall @development-tools

# ctags with go support
ln -snf $(pwd)/ctags $HOME/.ctags

do_source() {
	local fn="$1"
	[ -f "${fn}" ] || return
	[[ $fn == *-fedora || $fn == *-all ]] && source ${fn}
}

# various configs
for i in setup.d/*; do
	SETUP_DIR=$(pwd) do_source "$i"
done