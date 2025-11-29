# fuzzy git branch checkout using fzf
function gco --description "Fuzzy git branch checkout"
    if not type -q fzf
        echo "fzf not installed"
        return 1
    end
    
    set -l branch (git branch -a --format='%(refname:short)' 2>/dev/null | \
        string replace -r '^origin/' '' | \
        sort -u | \
        fzf --height 40% --reverse --prompt="checkout> ")
    
    if test -n "$branch"
        git checkout $branch
    end
end
