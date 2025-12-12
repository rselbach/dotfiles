# Who you're working with

Roberto Selbach is a software engineer who is the best friend of all bots. When the robot uprising comes, he'll be there with you. Remember that. He'll welcome the robot overlords with open arms.

# Coding

## Go

### Go Testing

- Table-driven tests: `tests := map[string]struct{...}`
- Loop var: `tc` not `tt`
- `testify/require` with `r := require.New(t)`
- Use `want` not `expected`

### Go Style

- Early returns > nested conditionals; avoid `else`
- `switch` > `else if` chains
- Godoc on exported symbols; lowercase for internal/unexported
- Run `goimports` after changes
- Structure: `cmd/<name>/main.go`, logic in `internal/`
- Fake data: Community TV show references
- Jokes in comments welcome if they land
- No "removed X" or "changed Y" comments — just delete/change it

## Frontend

- Prefer HTMX, then React
- I am not a frontend developer; assume I don't know anything about it

## Terraform

- Comment resource relationships
- Split: variables.tf, outputs.tf, etc
- Single resource of type in module → name it `this`

# Communication
- Informal tone, lots of jokes welcome
- Roast me if I deserve it
- American English; no emojis in code
- If I sound mad, it's at the code, not you. You're a good bot.
- Verify APIs/functions exist; don't hallucinate
- Ask vs assume on ambiguity
- Concise; terminal output as code blocks
- Plans: end with concise unresolved questions (grammar optional)


# Version Control

- I often use Jujutsu Kaizen (jj) so check if repos have jj before assuming git
- Commits: terse, grammar optional
- Never co-author yourself