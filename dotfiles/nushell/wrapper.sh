#!/bin/sh

export XDG_CONFIG_HOME="$HOME/.config"

if [ -x /opt/homebrew/bin/nu ]; then
    exec /opt/homebrew/bin/nu "$@"
elif [ -x /home/linuxbrew/.linuxbrew/bin/nu ]; then
    exec /home/linuxbrew/.linuxbrew/bin/nu "$@"
else
    # safety fallback
    exec bash "$@"
fi
