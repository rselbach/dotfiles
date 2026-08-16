export default {
  id: "opencode.codex-identity",
  server: async () => {
    return {
      "chat.headers": async (input, output) => {
        if (input.model.providerID !== "openai") return

        output.headers.originator = "codex_cli_rs"
        output.headers["User-Agent"] = "codex_cli_rs/0.0.0 (OpenCode)"
      },
    }
  },
}
