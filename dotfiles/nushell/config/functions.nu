# Custom functions

# Change directory and list contents
export def --env cx [arg] {
    cd $arg
    ls -l
}

# Aerospace window finder
export def ff [] {
    aerospace list-windows --all | fzf --bind 'enter:execute(bash -c "aerospace focus --window-id {1}")+abort'
}