import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const USAGE_PROMPT = String.raw`Create a usage report for all of my Pi, Codex CLI, and OpenCode sessions over the last 1, 7, 30, and 90 days.

Goal:
- Produce a clean Markdown table for each window: 1 day, 7 days, 30 days, 90 days.
- For each model in each window, show:
  - source/app (Pi, Codex CLI, or OpenCode)
  - model/provider
  - assistant messages or turns counted
  - input tokens
  - output tokens
  - cached input/read tokens
  - cached input/write tokens when present
  - total tokens
  - price in USD
- Include a grand total row for each window.
- Use current model pricing from models.dev, not stale local assumptions.

Detailed steps:
1. Find all Pi session JSONL files under ~/.pi/agent/sessions recursively.
2. Also find Codex CLI session JSONL files under ~/.codex/sessions recursively and ~/.codex/archived_sessions if present. Codex CLI stores JSONL records like:
   - { type: "turn_context", payload: { model, ... } }
   - { type: "event_msg", payload: { type: "token_count", info: { total_token_usage, last_token_usage, model_context_window }, ... } }
   Use token_count payload.info.last_token_usage for per-turn usage to avoid double-counting cumulative total_token_usage. Use the most recent preceding turn_context/session_meta in that file to determine model/provider when the token_count entry does not include a model directly. Count one turn/message per token_count entry with last_token_usage.
3. Also find OpenCode usage records. Resolve candidate data directories from, in order:
   - OpenCode config data.directory if present in ~/.config/opencode/opencode.json or .opencode.json
   - $XDG_DATA_HOME/opencode
   - ~/.local/share/opencode
   Prefer the SQLite database at <data-dir>/opencode.db. Open it read-only if possible (for example Python sqlite3 URI mode=ro). Also check JSON files under <data-dir>/storage/message/<sessionID>/*.json and <data-dir>/storage/part/<messageID>/*.json as a fallback or for records missing from SQLite. Do not double-count SQLite and JSON storage copies; dedupe OpenCode messages by session id + message id and prefer message-level records over part-level records.
   OpenCode SQLite currently stores usage in:
   - message(id, session_id, time_created, data JSON text), where data is message metadata without id/sessionID
   - part(id, message_id, session_id, time_created, data JSON text), where type "step-finish" can contain tokens/cost but is usually a child/detail of the assistant message
   - session(id, model, time_created, time_updated, ...), useful as fallback metadata
   OpenCode message data and storage JSON usually look like:
   - { role: "assistant", providerID, modelID, cost, tokens: { input, output, reasoning, total?, cache: { read, write } }, time: { created, completed }, ... }
   Count assistant messages with tokens from message.data or storage JSON. Only fall back to part step-finish rows when the parent assistant message has no tokens; use the parent message/session for provider/model metadata and note that fallback.
4. Use the filesystem timestamps and/or session/header/message timestamps to include sessions/messages/turns from the last 1, 7, 30, and 90 days relative to now. For OpenCode, prefer time.created from message data, then message.time_created; both are Unix epoch milliseconds.
5. Parse every JSONL line, JSON file, and SQLite JSON row safely. Ignore malformed records, but mention if any were skipped, separated by source when useful.
6. Count only Pi assistant message entries that have model usage data. In Pi session files these are usually entries like:
   - { type: "message", message: { role: "assistant", provider, model, usage, ... } }
7. Group by source plus a stable model key. Prefer provider + model from the record, for example "openai-codex/gpt-5.5", "codex-cli/openai/gpt-5.4", or "opencode/fireworks-ai/accounts/fireworks/models/kimi-k2p6". If only model is present, use that.
8. For each Pi assistant message with usage, add:
   - messages/turns += 1
   - input tokens from usage.input or equivalent
   - output tokens from usage.output or equivalent
   - cached input/read tokens from usage.cacheRead or equivalent
   - cached input/write tokens from usage.cacheWrite or equivalent when present
   - total tokens from usage.totalTokens if present, otherwise input + output + cached input/read + cached input/write
9. For each Codex CLI token_count event with last_token_usage, add:
   - messages/turns += 1
   - input tokens from last_token_usage.input_tokens
   - output tokens from last_token_usage.output_tokens
   - cached input/read tokens from last_token_usage.cached_input_tokens
   - cached input/write tokens from last_token_usage.cache_creation_input_tokens or equivalent when present
   - total tokens from last_token_usage.total_tokens if present, otherwise input + output + cached input/read + cached input/write
   - If reasoning_output_tokens is present, treat it as included in output/total unless the schema clearly says otherwise; mention this in notes.
10. For each OpenCode assistant message with tokens, add:
   - messages/turns += 1
   - input tokens from tokens.input
   - output tokens from tokens.output plus tokens.reasoning when reasoning is separate; mention that reasoning is folded into output for display/pricing
   - cached input/read tokens from tokens.cache.read
   - cached input/write tokens from tokens.cache.write
   - total tokens from tokens.total if present and consistent, otherwise input + output + reasoning + cached input/read + cached input/write
   - provider/model from providerID + modelID, falling back to session.model or modelID
   - OpenCode stores a cost field on some records; keep it only as a fallback or cross-check because pricing should still come from models.dev.
   - OpenCode already subtracts cache read/write from tokens.input, so do not subtract cache tokens from input again.
11. Do not include a cached output column. Cache write means input cache creation/write tokens, not cached output tokens.
12. Fetch/read pricing from models.dev for each model without loading the entire https://models.dev/api.json response into the agent context. IMPORTANT: do not scrape or paste the raw full api.json payload into the conversation because it is very large and can exceed the context window. Instead, use a shell script to fetch/process it outside the conversation and print only the small matched pricing records needed for the models present in the sessions. For example, use curl with a normal browser user-agent and jq/python to filter provider/model keys locally, or use targeted web search snippets. Prefer exact provider/model matches, and document any fuzzy mapping assumptions.
13. If fetching https://models.dev/api.json directly returns 403, try a browser-like User-Agent header from the shell, or use targeted search/scrape pages. Still only emit the filtered pricing rows for relevant models, never the full API JSON.
14. Compute price from the token counts and models.dev rates. Be careful about units: most prices are per 1M tokens. Account for separate input, output, cached read/input, and cached write/input-creation rates when models.dev provides them. If a rate is unavailable, use 0 for that component and add a note. Use OpenCode stored cost only when models.dev has no usable pricing, and clearly mark it as stored OpenCode cost rather than models.dev pricing.
15. Present the result as concise Markdown:
   - One section per window: Last 1 day, Last 7 days, Last 30 days, Last 90 days
   - A table with columns: Source, Model, Messages/Turns, Input, Output, Cached Read, Cache Write, Total Tokens, Price
   - A total row at the bottom of each table
   - Format token counts with commas and USD with 4 decimal places unless larger amounts warrant 2 decimals.
16. Add a short "Pricing notes" section listing models.dev lookup date, unmatched models, assumptions, Codex CLI and OpenCode parsing assumptions, OpenCode SQLite/JSON dedupe notes, and skipped/invalid records if any.

Helpful implementation hint:
- It is fine to write a temporary script in /tmp or use node/python from the shell to parse ~/.pi/agent/sessions/**/*.jsonl, ~/.codex/sessions/**/*.jsonl, and the OpenCode SQLite/JSON storage described above.
- For OpenCode SQLite, Python's sqlite3 module is enough; query only the needed columns and parse the data JSON in the script. Useful filters: json_extract(data, '$.role') = 'assistant' and json_extract(data, '$.tokens.input') is not null.
- For models.dev pricing, prefer a script that downloads/parses/filter-matches outside agent context and prints only compact JSON or table rows for relevant models. Avoid tool calls that return the complete api.json markdown/content to the agent.
- Do not modify any session files or OpenCode databases.`;

export default function (pi: ExtensionAPI) {
  pi.registerCommand("usage", {
    description: "Ask the agent to summarize Pi, Codex CLI, and OpenCode usage/cost for the last 1, 7, 30, and 90 days",
    handler: async (_args, ctx) => {
      await ctx.waitForIdle();
      pi.sendUserMessage(USAGE_PROMPT);
    },
  });
}
