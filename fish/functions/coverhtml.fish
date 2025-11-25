# generates HTML coverage report for Go tests
function coverhtml --description "Generate Go test coverage HTML report"
    go test -coverprofile=/tmp/c.out $argv; or return 1
    go tool cover -html=/tmp/c.out -o /tmp/coverage.html; or return 2
    open /tmp/coverage.html
end
