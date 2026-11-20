---
name: go-style
description: "Apply when writing, editing, or reviewing Go code and Go tests. Covers idioms, control flow, table tests, comments, and testify/require usage."
---

# Go Style

- Prefer `any` to `interface{}`.
- Prefer early returns and `switch` to `if`/`else`; avoid `else` where practical.
- Use map-based table tests, `tc` for loop cases, and `want` rather than `expected`.
- Add Godoc to exported symbols; use lowercase comments for internal symbols.
- When using `testify/require`, prefer `r := require.New(t)` over package-level functions (good: `r.Equal(...)`, bad: `require.Equal(...)`).
