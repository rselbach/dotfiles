# suggest corrections for mistyped commands
function fish_command_not_found
    set -l cmd $argv[1]
    
    # check for common typos
    switch $cmd
        case 'cx'
            echo "fish: Unknown command '$cmd'. Did you mean 'cd'?"
        case 'gti' 'got'
            echo "fish: Unknown command '$cmd'. Did you mean 'git'?"
        case 'sl'
            echo "fish: Unknown command '$cmd'. Did you mean 'ls'?"
        case 'cta' 'tac'
            echo "fish: Unknown command '$cmd'. Did you mean 'cat'?"
        case 'suod'
            echo "fish: Unknown command '$cmd'. Did you mean 'sudo'?"
        case 'grpe' 'gerp'
            echo "fish: Unknown command '$cmd'. Did you mean 'grep'?"
        case 'mkae' 'maek'
            echo "fish: Unknown command '$cmd'. Did you mean 'make'?"
        case 'dokcer'
            echo "fish: Unknown command '$cmd'. Did you mean 'docker'?"
        case '*'
            __fish_default_command_not_found_handler $cmd
    end
end
