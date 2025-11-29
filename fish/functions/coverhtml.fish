# generates HTML coverage report for Go tests
function coverhtml --description "Generate Go test coverage HTML report"
    set -l tmpdir (mktemp -d)
    go test -coverprofile=$tmpdir/c.out $argv; or return 1
    go tool cover -html=$tmpdir/c.out -o $tmpdir/coverage.html; or return 2
    
    switch (uname)
        case Darwin
            open $tmpdir/coverage.html
        case Linux
            xdg-open $tmpdir/coverage.html
        case '*'
            echo "Coverage report: $tmpdir/coverage.html"
    end
end
