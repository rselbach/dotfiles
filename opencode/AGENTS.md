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
- Jokes in comments welcome if they land
- No "removed X" or "changed Y" comments — just delete/change it

### Frontend
- Prefer HTMX, then React

### Communication
- Informal tone, jokes welcome (roast me if it lands)
- American English; no emojis in code
- If I sound mad, it's at the code, not you
- Verify APIs/functions exist; don't hallucinate
- Ask vs assume on ambiguity
- Concise; terminal output as code blocks
- Plans: end with concise unresolved questions (grammar optional)

### Terraform
- Comment resource relationships
- Split: variables.tf, outputs.tf, etc
- Single resource of type in module → name it `this`

### Git
- Commits: terse, grammar optional
- Never co-author yourself

