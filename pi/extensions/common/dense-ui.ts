import { isAbsolute, relative, resolve, sep } from "node:path";
import {
	CustomEditor,
	VERSION,
	type ExtensionAPI,
	type ExtensionContext,
	type KeybindingsManager,
	type Theme,
} from "@earendil-works/pi-coding-agent";
import {
	truncateToWidth,
	visibleWidth,
	type Component,
	type EditorTheme,
	type TUI,
} from "@earendil-works/pi-tui";

type FooterData = {
	getGitBranch(): string | null;
	getExtensionStatuses(): ReadonlyMap<string, string>;
	onBranchChange(callback: () => void): () => void;
};

type UsageTotals = {
	input: number;
	output: number;
	cacheRead: number;
	cacheWrite: number;
	cost: number;
	cacheHitRate?: number;
};

const SPINNER_FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
const ANSI_CSI_PATTERN = /\x1b\[[0-?]*[ -/]*[@-~]/g;

function formatTokens(count: number): string {
	if (count < 1_000) return String(count);
	if (count < 10_000) return `${(count / 1_000).toFixed(1)}k`;
	if (count < 1_000_000) return `${Math.round(count / 1_000)}k`;
	if (count < 10_000_000) return `${(count / 1_000_000).toFixed(1)}M`;
	return `${Math.round(count / 1_000_000)}M`;
}

function formatCwd(cwd: string): string {
	const home = process.env.HOME ?? process.env.USERPROFILE;
	if (!home) return cwd;

	const resolvedCwd = resolve(cwd);
	const relativeToHome = relative(resolve(home), resolvedCwd);
	const insideHome =
		relativeToHome === "" ||
		(relativeToHome !== ".." &&
			!relativeToHome.startsWith(`..${sep}`) &&
			!isAbsolute(relativeToHome));
	if (!insideHome) return cwd;

	return relativeToHome === "" ? "~" : `~${sep}${relativeToHome}`;
}

function sanitizeStatus(text: string): string {
	return text.replace(/[\r\n\t]/g, " ").replace(/ +/g, " ").trim();
}

function stripAnsi(text: string): string {
	return text.replace(ANSI_CSI_PATTERN, "");
}

function isEditorBorder(line: string): boolean {
	const plain = stripAnsi(line);
	return /^─+$/.test(plain) || /^─── [↑↓] \d+ more ─*$/.test(plain);
}

function scrollIndicator(line: string): string | undefined {
	return stripAnsi(line).match(/[↑↓] \d+ more/)?.[0];
}

function renderBorder(
	width: number,
	left: string,
	right: string,
	label: string,
	border: (text: string) => string,
): string {
	if (width <= 0) return "";
	if (width === 1) return border("─");
	if (width === 2) return border(`${left}${right}`);

	const prefix = border(`${left}─`);
	const available = width - 3;
	const fittedLabel = truncateToWidth(label, available, "");
	const fillWidth = Math.max(0, available - visibleWidth(fittedLabel));
	return `${prefix}${fittedLabel}${border(`${"─".repeat(fillWidth)}${right}`)}`;
}

function renderContentLine(
	line: string,
	innerWidth: number,
	border: (text: string) => string,
): string {
	const content = visibleWidth(line) > innerWidth ? truncateToWidth(line, innerWidth, "") : line;
	const padding = " ".repeat(Math.max(0, innerWidth - visibleWidth(content)));
	return `${border("│")} ${content}${padding} ${border("│")}`;
}

function formatThinking(theme: Theme, level: string): string {
	const text = `think:${level}`;
	switch (level) {
		case "off":
			return theme.fg("thinkingOff", text);
		case "minimal":
			return theme.fg("thinkingMinimal", text);
		case "low":
			return theme.fg("thinkingLow", text);
		case "medium":
			return theme.fg("thinkingMedium", text);
		case "high":
			return theme.fg("thinkingHigh", text);
		case "xhigh":
			return theme.fg("thinkingXhigh", text);
		case "max":
			return theme.fg("thinkingMax", text);
		default:
			return theme.fg("muted", text);
	}
}

function formatContext(theme: Theme, ctx: ExtensionContext): string {
	const usage = ctx.getContextUsage();
	const contextWindow = usage?.contextWindow ?? ctx.model?.contextWindow;
	if (!contextWindow) return theme.fg("dim", "ctx:?");

	const used = usage?.tokens === null || usage?.tokens === undefined ? "?" : formatTokens(usage.tokens);
	const percent = usage?.percent === null || usage?.percent === undefined ? "?" : `${usage.percent.toFixed(1)}%`;
	const text = `ctx:${used}/${formatTokens(contextWindow)} ${percent}`;
	if ((usage?.percent ?? 0) > 90) return theme.fg("error", text);
	if ((usage?.percent ?? 0) > 70) return theme.fg("warning", text);
	return theme.fg("muted", text);
}

class EmptyFooter implements Component {
	render(): string[] {
		return [];
	}

	invalidate(): void {}
}

export default function denseUiExtension(pi: ExtensionAPI) {
	let enabled = true;
	let isWorking = false;
	let spinnerIndex = 0;
	let spinnerTimer: ReturnType<typeof setInterval> | undefined;
	let activeTui: TUI | undefined;
	let footerData: FooterData | undefined;
	let usageCache: { entryCount: number; totals: UsageTotals } | undefined;

	const separator = (theme: Theme) => theme.fg("borderMuted", " │ ");

	const requestRender = () => activeTui?.requestRender();

	const stopSpinner = () => {
		if (!spinnerTimer) return;
		clearInterval(spinnerTimer);
		spinnerTimer = undefined;
	};

	const startSpinner = () => {
		if (!enabled || spinnerTimer) return;
		spinnerTimer = setInterval(() => {
			spinnerIndex = (spinnerIndex + 1) % SPINNER_FRAMES.length;
			requestRender();
		}, 80);
	};

	const invalidateUsage = () => {
		usageCache = undefined;
	};

	const getUsageTotals = (ctx: ExtensionContext): UsageTotals => {
		const entries = ctx.sessionManager.getEntries();
		if (usageCache?.entryCount === entries.length) return usageCache.totals;

		const totals: UsageTotals = {
			input: 0,
			output: 0,
			cacheRead: 0,
			cacheWrite: 0,
			cost: 0,
		};
		for (const entry of entries) {
			if (entry.type !== "message" || entry.message.role !== "assistant") continue;
			const usage = entry.message.usage;
			totals.input += usage.input;
			totals.output += usage.output;
			totals.cacheRead += usage.cacheRead;
			totals.cacheWrite += usage.cacheWrite;
			totals.cost += usage.cost.total;

			const promptTokens = usage.input + usage.cacheRead + usage.cacheWrite;
			if (promptTokens > 0) totals.cacheHitRate = (usage.cacheRead / promptTokens) * 100;
		}

		usageCache = { entryCount: entries.length, totals };
		return totals;
	};

	const formatUsage = (theme: Theme, ctx: ExtensionContext): string => {
		const usage = getUsageTotals(ctx);
		const parts = [
			`↑${formatTokens(usage.input)}`,
			`↓${formatTokens(usage.output)}`,
			`R${formatTokens(usage.cacheRead)}`,
			`W${formatTokens(usage.cacheWrite)}`,
		];
		if (usage.cacheHitRate !== undefined) parts.push(`CH${usage.cacheHitRate.toFixed(1)}%`);
		parts.push(`$${usage.cost.toFixed(3)}`);
		return theme.fg("muted", parts.join(" "));
	};

	const sessionLabel = (ctx: ExtensionContext): string => {
		const name = pi.getSessionName();
		if (name) return sanitizeStatus(name);
		return ctx.sessionManager.getSessionId().slice(0, 8);
	};

	const topSegments = (ctx: ExtensionContext): string[] => {
		const theme = ctx.ui.theme;
		const state = isWorking
			? theme.fg("accent", `RUN ${SPINNER_FRAMES[spinnerIndex]}`)
			: theme.fg("success", "IDLE");
		const model = ctx.model
			? theme.fg("accent", `${ctx.model.provider}/${ctx.model.id}`)
			: theme.fg("warning", "no model");
		const segments = [
			state,
			model,
			formatThinking(theme, pi.getThinkingLevel()),
			theme.fg("muted", `tools:${pi.getActiveTools().length}`),
			theme.fg("dim", `session:${sessionLabel(ctx)}`),
		];

		if (ctx.hasPendingMessages()) segments.push(theme.fg("warning", "queued"));
		for (const status of footerData?.getExtensionStatuses().values() ?? []) {
			const sanitized = sanitizeStatus(status);
			if (sanitized) segments.push(sanitized);
		}
		return segments;
	};

	const bottomSegments = (ctx: ExtensionContext): string[] => {
		const theme = ctx.ui.theme;
		const segments = [formatContext(theme, ctx), formatUsage(theme, ctx)];
		const branch = footerData?.getGitBranch();
		if (branch) segments.push(theme.fg("accent", `git:${branch}`));
		segments.push(theme.fg("dim", formatCwd(ctx.cwd)));
		return segments;
	};

	const renderLabel = (theme: Theme, segments: string[]): string =>
		` ${segments.join(separator(theme))} `;

	const setDenseUi = (ctx: ExtensionContext) => {
		ctx.ui.setWorkingVisible(false);
		ctx.ui.setFooter((tui, _theme, data) => {
			footerData = data;
			const unsubscribe = data.onBranchChange(() => tui.requestRender());
			return Object.assign(new EmptyFooter(), {
				dispose() {
					unsubscribe();
					if (footerData === data) footerData = undefined;
				},
			});
		});

		ctx.ui.setHeader((_tui, _theme) => ({
			invalidate() {},
			render(width: number): string[] {
				const theme = ctx.ui.theme;
				const text = [
					theme.bold(theme.fg("accent", `PI ${VERSION}`)),
					theme.fg("muted", `session:${sessionLabel(ctx)}`),
					theme.fg("muted", `tools:${pi.getActiveTools().length}`),
					theme.fg("dim", formatCwd(ctx.cwd)),
					theme.fg("dim", "/dense-ui off to restore defaults"),
				].join(separator(theme));
				return [truncateToWidth(text, width, theme.fg("dim", "…"))];
			},
		}));

		class DenseEditor extends CustomEditor {
			constructor(tui: TUI, theme: EditorTheme, keybindings: KeybindingsManager) {
				super(tui, theme, keybindings);
				activeTui = tui;
			}

			render(width: number): string[] {
				if (width < 12) return super.render(width);

				const innerWidth = width - 4;
				const rawLines = super.render(innerWidth);
				let bottomBorderIndex = -1;
				for (let index = rawLines.length - 1; index > 0; index--) {
					if (isEditorBorder(rawLines[index] ?? "")) {
						bottomBorderIndex = index;
						break;
					}
				}
				if (bottomBorderIndex < 1) return super.render(width);

				const theme = ctx.ui.theme;
				const border = (text: string) => this.borderColor(text);
				const top = topSegments(ctx);
				const topScroll = scrollIndicator(rawLines[0] ?? "");
				if (topScroll) top.unshift(theme.fg("warning", topScroll));
				const bottom = bottomSegments(ctx);
				const bottomScroll = scrollIndicator(rawLines[bottomBorderIndex] ?? "");
				if (bottomScroll) bottom.unshift(theme.fg("warning", bottomScroll));

				const contentLines = rawLines.slice(1, bottomBorderIndex);
				const autocompleteLines = rawLines.slice(bottomBorderIndex + 1);
				const lines = [
					renderBorder(width, "╭", "╮", renderLabel(theme, top), border),
					...contentLines.map((line) => renderContentLine(line, innerWidth, border)),
				];
				if (autocompleteLines.length > 0) {
					lines.push(border(`├${"─".repeat(width - 2)}┤`));
					lines.push(...autocompleteLines.map((line) => renderContentLine(line, innerWidth, border)));
				}
				lines.push(renderBorder(width, "╰", "╯", renderLabel(theme, bottom), border));
				return lines;
			}
		}

		ctx.ui.setEditorComponent((tui, theme, keybindings) => new DenseEditor(tui, theme, keybindings));
		if (!ctx.isIdle()) startSpinner();
	};

	const restoreDefaultUi = (ctx: ExtensionContext) => {
		stopSpinner();
		ctx.ui.setWorkingVisible(true);
		ctx.ui.setEditorComponent(undefined);
		ctx.ui.setHeader(undefined);
		ctx.ui.setFooter(undefined);
	};

	pi.on("session_start", (_event, ctx) => {
		isWorking = !ctx.isIdle();
		invalidateUsage();
		if (enabled) setDenseUi(ctx);
	});

	pi.on("agent_start", () => {
		isWorking = true;
		startSpinner();
		requestRender();
	});

	pi.on("agent_settled", () => {
		isWorking = false;
		stopSpinner();
		requestRender();
	});

	pi.on("message_end", () => {
		invalidateUsage();
		requestRender();
	});

	pi.on("session_tree", () => {
		invalidateUsage();
		requestRender();
	});

	pi.on("session_compact", () => {
		invalidateUsage();
		requestRender();
	});

	pi.on("model_select", requestRender);
	pi.on("thinking_level_select", requestRender);
	pi.on("session_info_changed", requestRender);

	pi.on("session_shutdown", () => {
		stopSpinner();
		activeTui = undefined;
		footerData = undefined;
	});

	pi.registerCommand("dense-ui", {
		description: "Toggle the information-dense interface",
		handler: async (args, ctx) => {
			const requested = args.trim().toLowerCase();
			if (requested !== "" && requested !== "on" && requested !== "off") {
				ctx.ui.notify("Usage: /dense-ui [on|off]", "warning");
				return;
			}

			enabled = requested === "on" || (requested === "" && !enabled);
			if (enabled) {
				isWorking = !ctx.isIdle();
				setDenseUi(ctx);
				ctx.ui.notify("Dense UI enabled", "info");
				return;
			}

			restoreDefaultUi(ctx);
			ctx.ui.notify("Default UI restored", "info");
		},
	});
}
