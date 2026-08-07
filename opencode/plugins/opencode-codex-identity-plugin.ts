export default {
  id: "opencode.codex-identity",
  setup: async (ctx) => {
    await ctx.session.hook("http.request", (event) => {
      if (event.model.providerID !== "openai") return

      event.request.headers.set("originator", "codex_cli_rs")
      event.request.headers.set("User-Agent", "codex_cli_rs/0.0.0 (OpenCode)")
    })
  },
}
