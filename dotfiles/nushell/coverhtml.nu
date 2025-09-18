def coverhtml [...args] {
  go test -coverprofile=/tmp/c.out ...$args
  go tool cover -html=/tmp/c.out -o /tmp/coverage.html
  
  # Use the appropriate command based on the OS
  if $nu.os-info.name == "macos" {
    ^open /tmp/coverage.html
  } else if $nu.os-info.name == "linux" {
    ^xdg-open /tmp/coverage.html
  } else {
    print $"Unsupported OS: ($nu.os-info.name)"
  }
}
