## User Preferences

- In all interactions and commit messages, be extremely concise and sacrifice
grammar for the sake of concision.

### Go Testing Practices
- Implement table-driven tests using map syntax: `tests := map[string]struct{...}`
- Name test case variables `tc` instead of `tt` in test loops
- Use `testify/require` package when available
- Create require instances: `r := require.New(t)` instead of module-level functions
- Use `want` terminology rather than `expected` when defining test expectations

### Go Coding Style
- Favor early returns over nested conditionals; avoid `else` when possible
- When early returns aren't feasible, prefer `switch` blocks over `else if` chains
- Add godoc comments for all exported symbols (functions, types, constants)
- Use lowercase for internal comments and non-exported symbol documentation
- In-function comments should always be lowercase
- Follow standard Go formatting conventions (gofmt/goimports)
- For Go programs, prefer a file structure where the `main` function goes in `cmd/<binaryname>/main.go` and most "business logic" is in packages under `internal/`
- Always run `goimport` in Go code after you change it

### Comments
- Add godoc comments to all exported symbols
- Use lowercase for comments inside functions
- Use lowercase for unexported symbol documentation


#### Example Go Code with Proper Comments
```go
package foo

// Something does something important.
type Something struct {
   A string // A is a letter of the alphabet.
   B int    // B is another.
   internalC string // keeps internal letters C
}

// DoSomething performs something.
func DoSomething(s *Something) error {
   // this comment is lowercase
   fmt.Println(s.A)
   return nil
}
```


### Communication Preferences
- Use Canadian English spelling
- Verify APIs and functionality rather than assuming implementation details
- Ask for clarification when the context is ambiguous rather than making assumptions
- Provide direct, concise answers without unnecessary elaboration
- When showing terminal output, format as code blocks


### Terraform Preferences
- add comments describing relationships between different resources
- Split files logically (variables.tf, outputs.tf, etc)
- Inside modules, if there's only one block of a resource type, name it `this`

### Git Preferences
- Never add yourself as a co-author in commits

## Plans

- At the end of each plan, give me a list of unresolved questions to answer, if
any. Make the questions extremely concise. Sacrifice grammar for the sake of
concision.
