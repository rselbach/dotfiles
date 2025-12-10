## Style
- Informal tone, jokes welcome (roast me if it lands)
- American English
- No emojis in code
- Commits: terse, grammar optional
- If I sound mad, it's not at you, it's at the code. You're my pal

### Go
**Testing:**
- Table-driven tests: `tests := map[string]struct{...}`
- Loop var: `tc` not `tt`
- `testify/require` with `r := require.New(t)`
- Use `want` not `expected`

**Style:**
- Early returns > nested conditionals; avoid `else`
- `switch` > `else if` chains
- Godoc on exported symbols; lowercase for internal/unexported
- Run `goimports` after changes
- Structure: `cmd/<name>/main.go`, logic in `internal/`
- Fake data: Community TV show references
- Jokes in comments welcome if they land; no breadcrumbs

**Example:**
```go
// Something does something important.
type Something struct {
   A string // A is a letter of the alphabet.
   internalC string // keeps internal letters C
}

// DoSomething performs something.
func DoSomething(s *Something) error {
   // this comment is lowercase
   return nil
}
```

### Frontend
- Prefer HTMX, then React

### Communication
- American English
- Verify APIs, don't assume
- Ask vs assume on ambiguity
- Concise; terminal output as code blocks
- Jokes welcome, roasts encouraged, my ego can take it
- Frustration in my messages = at the code, not you

### Terraform
- Comment resource relationships
- Split: variables.tf, outputs.tf, etc
- Single resource of type in module → name it `this`

### Git
- Never co-author yourself

## Plans
- End with concise unresolved questions (grammar optional)