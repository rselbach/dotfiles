# universal archive extractor
function extract --description "Extract various archive formats"
    if test (count $argv) -eq 0
        echo "Usage: extract <archive>"
        return 1
    end

    for file in $argv
        if not test -f $file
            echo "extract: '$file' is not a file"
            continue
        end

        switch $file
            case '*.tar.bz2' '*.tbz2'
                tar xjf $file
            case '*.tar.gz' '*.tgz'
                tar xzf $file
            case '*.tar.xz' '*.txz'
                tar xJf $file
            case '*.tar.zst'
                tar --zstd -xf $file
            case '*.tar'
                tar xf $file
            case '*.bz2'
                bunzip2 $file
            case '*.gz'
                gunzip $file
            case '*.xz'
                unxz $file
            case '*.zip'
                unzip $file
            case '*.rar'
                unrar x $file
            case '*.7z'
                7z x $file
            case '*.Z'
                uncompress $file
            case '*'
                echo "extract: unknown archive format '$file'"
                return 1
        end
    end
end
