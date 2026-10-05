import {
	type ExtensionAPI,
	type ExtensionContext,
	getAgentDir,
	SettingsManager,
} from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	const rememberSelection = async (ctx: ExtensionContext) => {
		if ((ctx.mode !== "tui" && ctx.mode !== "rpc") || !ctx.model) {
			return;
		}

		const { provider, id } = ctx.model;
		const level = pi.getThinkingLevel();
		const settings = SettingsManager.create(ctx.cwd, getAgentDir());
		settings.setDefaultModelAndProvider(provider, id);
		settings.setDefaultThinkingLevel(level);
		settings.setModelThinkingLevel(provider, id, level);
		await settings.flush();

		const errors = settings.drainErrors();
		if (errors.length > 0) {
			throw new AggregateError(
				errors.map(({ error }) => error),
				"Could not remember the model and reasoning level",
			);
		}
	};

	pi.on("session_start", async (_event, ctx) => rememberSelection(ctx));
	pi.on("model_select", async (_event, ctx) => rememberSelection(ctx));
	pi.on("thinking_level_select", async (_event, ctx) => rememberSelection(ctx));
}
