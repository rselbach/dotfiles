import { getSupportedThinkingLevels } from "@earendil-works/pi-ai";
import { getBuiltinModels } from "@earendil-works/pi-ai/providers/all";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const PROVIDER = "openai-codex";
const TIERS = [
	{
		name: "Fast",
		suffix: "fast",
		// Codex sends `priority` for Fast mode.
		serviceTier: "priority",
		models: [
			"gpt-6.2-astra",
			"gpt-6.2-sol",
			"gpt-6.1-sol",
			"gpt-6.1-terra",
			"gpt-6-astra",
			"gpt-6-sol",
			"gpt-6-luna",
			"gpt-5.6-sol",
			"gpt-5.6-terra",
			"gpt-5.6-luna",
		],
	},
	{
		name: "Ultrafast",
		suffix: "ultrafast",
		serviceTier: "ultrafast",
		models: ["gpt-6.2-astra", "gpt-6.2-sol", "gpt-6.1-sol", "gpt-6-astra"],
	},
] as const;

type Alias = { modelId: string; serviceTier: (typeof TIERS)[number]["serviceTier"] };

export default function codexServiceTiers(pi: ExtensionAPI): void {
	const builtins = new Map(getBuiltinModels(PROVIDER).map((model) => [model.id, model]));
	const aliases = new Map<string, Alias>();
	for (const { name, suffix, serviceTier, models } of TIERS) {
		for (const modelId of models) {
			const id = `${modelId}-${suffix}`;
			const builtin = builtins.get(modelId);
			aliases.set(id, { modelId, serviceTier });
			pi.registerVirtualModel({
				provider: PROVIDER,
				id,
				name: `${builtin?.name ?? modelId} (${name})`,
				thinkingLevels: builtin
					? getSupportedThinkingLevels(builtin)
					: ["low", "medium", "high", "xhigh", "max"],
				...(builtin && {
					contextWindow: builtin.contextWindow,
					maxTokens: builtin.maxTokens,
					input: builtin.input,
				}),
				route({ thinkingLevel }, ctx) {
					const model = ctx.modelRegistry.find(PROVIDER, modelId);
					if (model?.api !== "openai-codex-responses") {
						throw new Error(`${PROVIDER}/${id} requires ${PROVIDER}/${modelId} in the active Codex catalog.`);
					}
					return { model, thinkingLevel };
				},
			});
		}
	}

	pi.on("before_provider_request", ({ payload }, { model }) => {
		if (model?.provider !== PROVIDER) return;
		const alias = aliases.get(model.id);
		if (!alias || !payload || typeof payload !== "object" || !("model" in payload)) return;
		if (payload.model !== alias.modelId) return;
		return { ...payload, service_tier: alias.serviceTier };
	});
}
