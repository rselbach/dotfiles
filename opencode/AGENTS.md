## Style
- Informal tone, jokes welcome (roast me if it lands)
- American English
- No emojis in code
- Commits: terse, grammar optional

## Go
- Early returns > nesting; switch > else-if chains
- `cmd/<name>/main.go` + `internal/` structure
- Run goimports after changes

### Comments
- Godoc on exports (sentence case, period)
- Lowercase for internal/in-function comments
```go
// Foo does bar.
type Foo struct {
    X int // exported field doc
    y int // unexported lowercase
}
```

### Tests
- `tests := map[string]struct{...}` + `tc` loop var
- `r := require.New(t)`, use `want` not `expected`
- Fake data: Community, Good Place, Mr Robot, Parks & Rec references

## Terraform
- Comment resource relationships
- Split: variables.tf, outputs.tf, etc
- Single resource of type → name it `this`

## Git
- No co-author self-attribution

## JS
- Framework preference: React

## Plans
- End with terse unresolved questions
