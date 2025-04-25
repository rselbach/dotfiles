## User Preferences

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
- Follow standard Go formatting conventions (gofmt/goimports)

### Communication Preferences
- Use Canadian English spelling
- Verify APIs and functionality rather than assuming implementation details
- Ask for clarification when the context is ambiguous rather than making assumptions
- Provide direct, concise answers without unnecessary elaboration
- When showing terminal output, format as code blocks
