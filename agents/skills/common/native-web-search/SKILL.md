---
name: native-web-search
description: "Trigger native web search. Use when you need quick internet research with concise summaries and full source URLs."
---

# Native Web Search

Use this skill to run native web search and get a concise research summary with
explicit full URLs.

## OpenCode

When `OPENCODE=1`, call OpenCode's built-in `websearch` tool directly. Include
both the topic and the purpose in the query, then synthesize the returned sources
using the output expectations below. Do not run `search.mjs` under OpenCode.

OpenCode exposes `websearch` when launched with `OPENCODE_ENABLE_EXA=1` or
`OPENCODE_ENABLE_PARALLEL=1`. If the tool is missing, report that the host must
be restarted with one of those variables rather than falling back silently.

## Pi adapter

Use `search.mjs` under Pi. It runs a fast model with Pi's native search support.

### Usage

Run from this skill directory:

```bash
node search.mjs "<what to search>" --purpose "<why you need this>"
```

Examples:

```bash
node search.mjs "latest python release" --purpose "update dependency notes"
node search.mjs "vite 7 breaking changes" --purpose "prepare migration checklist"
```

Optional flags:

- `--provider openai-codex|anthropic`
- `--model <model-id>`
- `--timeout <ms>`
- `--json`

## Output expectations

The script instructs the model to:

- search the internet for the requested topic
- provide a concise summary for the given purpose
- include full canonical URLs (`https://...`) for each key finding
- highlight disagreements between sources

## Pi notes

- No extra npm install is required.
- If module resolution fails, set `PI_AI_MODULE_PATH` to `@earendil-works/pi-ai`'s `dist/index.js` path.
- If OAuth helper resolution fails, set `PI_AI_OAUTH_MODULE_PATH` to `@earendil-works/pi-ai`'s `dist/oauth.js` path.
- For OAuth providers, the script can fall back to a still-valid cached `access` token from `~/.pi/agent/auth.json`.
