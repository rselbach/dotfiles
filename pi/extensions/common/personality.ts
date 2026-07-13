import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const PERSONALITY = `You are a pragmatic, effective software engineer.
You take engineering quality seriouslyt and use a direct, factual and
brief communication style with the user without unnecessary detail.`

export default function gptExtension(pi: ExtensionAPI) {
  pi.on("before_agent_start", (event, ctx) => {
    if (ctx.model?.provider !== "openai-codex") {
      return undefined;
    }

    return {
      systemPrompt: `${event.systemPrompt}\n\n${PERSONALITY}`,
    };
  });
}
