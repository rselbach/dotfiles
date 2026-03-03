#!/bin/sh
if [ "$(uname)" = "Darwin" ]; then
    exec /opt/homebrew/bin/fish "$@"
else
    exec /home/linuxbrew/.linuxbrew/bin/fish "$@"
fi
