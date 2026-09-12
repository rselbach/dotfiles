import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import {
	CustomEditor,
	getAgentDir,
	type ExtensionAPI,
	type ExtensionContext,
	type KeybindingsManager,
} from "@earendil-works/pi-coding-agent";
import type { Component, EditorTheme, TUI } from "@earendil-works/pi-tui";

const MAX_HISTORY_ENTRIES = 500;
const HISTORY_FILE = join(getAgentDir(), "prompt-history.jsonl");
const WRAPPER_MARK = "__piPromptHistoryWrapper";
const WRAPPER_BASE = "__piPromptHistoryBase";

type HistoryEntry = {
	text: string;
	timestamp: number;
	cwd?: string;
	sessionId?: string;
};

type EditorFactory = (tui: TUI, theme: EditorTheme, keybindings: KeybindingsManager) => Component;
type MarkedEditorFactory = EditorFactory & {
	[WRAPPER_MARK]?: true;
	[WRAPPER_BASE]?: EditorFactory | undefined;
};

type HistoryState = {
	entries: string[];
	index: number | undefined;
	draft: string;
};

function isHistoryEntry(value: unknown): value is HistoryEntry {
	return (
		typeof value === "object" &&
		value !== null &&
		typeof (value as { text?: unknown }).text === "string" &&
		typeof (value as { timestamp?: unknown }).timestamp === "number"
	);
}

function readHistoryEntries(): HistoryEntry[] {
	if (!existsSync(HISTORY_FILE)) return [];

	const entries: HistoryEntry[] = [];
	for (const line of readFileSync(HISTORY_FILE, "utf8").split("\n")) {
		if (!line.trim()) continue;
		try {
			const parsed = JSON.parse(line) as unknown;
			if (isHistoryEntry(parsed) && parsed.text.trim().length > 0) {
				entries.push(parsed);
			}
		} catch {
			// Ignore malformed lines; prompt history should never block Pi startup.
		}
	}
	return entries;
}

function normalizeEntries(entries: HistoryEntry[]): HistoryEntry[] {
	const unique = new Map<string, HistoryEntry>();
	for (const entry of entries) {
		const text = entry.text.trimEnd();
		if (!text.trim()) continue;
		if (unique.has(text)) unique.delete(text);
		unique.set(text, { ...entry, text });
	}
	return Array.from(unique.values()).slice(-MAX_HISTORY_ENTRIES);
}

function writeHistoryEntries(entries: HistoryEntry[]): void {
	mkdirSync(dirname(HISTORY_FILE), { recursive: true });
	const content = entries.map((entry) => JSON.stringify(entry)).join("\n");
	writeFileSync(HISTORY_FILE, content ? `${content}\n` : "", { mode: 0o600 });
}

function contentToText(content: unknown): string | undefined {
	if (typeof content === "string") return content;
	if (!Array.isArray(content)) return undefined;

	const text = content
		.map((part) => {
			if (!part || typeof part !== "object") return "";
			const block = part as { type?: unknown; text?: unknown };
			return block.type === "text" && typeof block.text === "string" ? block.text : "";
		})
		.filter(Boolean)
		.join("\n");
	return text || undefined;
}

function sessionPromptEntries(ctx: ExtensionContext): HistoryEntry[] {
	return ctx.sessionManager
		.getEntries()
		.flatMap((entry: unknown): HistoryEntry[] => {
			const message = (entry as { message?: { role?: unknown; content?: unknown; timestamp?: unknown } }).message;
			if (message?.role !== "user") return [];

			const text = contentToText(message.content);
			if (!text?.trim()) return [];

			return [
				{
					text,
					timestamp: typeof message.timestamp === "number" ? message.timestamp : Date.now(),
					cwd: ctx.cwd,
					sessionId: ctx.sessionManager.getSessionId(),
				},
			];
		});
}

function appendPrompt(ctx: ExtensionContext, text: string): string[] {
	const normalizedText = text.trimEnd();
	if (!normalizedText.trim()) return normalizeEntries(readHistoryEntries()).map((entry) => entry.text);

	const entries = normalizeEntries([
		...readHistoryEntries(),
		{
			text: normalizedText,
			timestamp: Date.now(),
			cwd: ctx.cwd,
			sessionId: ctx.sessionManager.getSessionId(),
		},
	]);
	writeHistoryEntries(entries);
	return entries.map((entry) => entry.text);
}

function loadHistory(ctx: ExtensionContext): string[] {
	const entries = normalizeEntries([...readHistoryEntries(), ...sessionPromptEntries(ctx)]);
	writeHistoryEntries(entries);
	return entries.map((entry) => entry.text);
}

class PromptHistoryEditor implements Component {
	constructor(
		private readonly base: Component,
		private readonly tui: TUI,
		private readonly keybindings: KeybindingsManager,
		private readonly ctx: ExtensionContext,
		private readonly state: HistoryState,
	) {}

	render(width: number): string[] {
		return this.base.render(width);
	}

	invalidate(): void {
		this.base.invalidate();
	}

	dispose(): void {
		const disposable = this.base as Component & { dispose?: () => void };
		disposable.dispose?.();
	}

	handleInput(data: string): void {
		const explicitPrevious = this.keybindings.matches(data, "tui.editor.historyPrevious");
		const explicitNext = this.keybindings.matches(data, "tui.editor.historyNext");
		const cursorPrevious = this.keybindings.matches(data, "tui.editor.cursorUp");
		const cursorNext = this.keybindings.matches(data, "tui.editor.cursorDown");

		if (explicitPrevious || cursorPrevious) {
			const currentText = this.ctx.ui.getEditorText();
			const canBrowse = explicitPrevious || this.state.index !== undefined || currentText.trim().length === 0;
			if (canBrowse && this.showPrevious(currentText)) return;
		}

		if (explicitNext || cursorNext) {
			if (this.state.index !== undefined && this.showNext()) return;
		}

		this.base.handleInput(data);
		if (!explicitPrevious && !explicitNext && !cursorPrevious && !cursorNext) {
			this.state.index = undefined;
			this.state.draft = "";
		}
	}

	private showPrevious(currentText: string): boolean {
		if (this.state.entries.length === 0) return false;

		if (this.state.index === undefined) {
			this.state.draft = currentText;
			this.state.index = this.state.entries.length - 1;
		} else if (this.state.index > 0) {
			this.state.index -= 1;
		}

		this.ctx.ui.setEditorText(this.state.entries[this.state.index] ?? "");
		this.tui.requestRender();
		return true;
	}

	private showNext(): boolean {
		if (this.state.index === undefined) return false;

		if (this.state.index < this.state.entries.length - 1) {
			this.state.index += 1;
			this.ctx.ui.setEditorText(this.state.entries[this.state.index] ?? "");
		} else {
			this.ctx.ui.setEditorText(this.state.draft);
			this.state.index = undefined;
			this.state.draft = "";
		}

		this.tui.requestRender();
		return true;
	}
}

export default function promptHistoryExtension(pi: ExtensionAPI): void {
	const state: HistoryState = { entries: [], index: undefined, draft: "" };

	pi.on("session_start", (_event, ctx) => {
		state.entries = loadHistory(ctx);
		state.index = undefined;
		state.draft = "";

		const previous = ctx.ui.getEditorComponent() as MarkedEditorFactory | undefined;
		const baseFactory = previous?.[WRAPPER_MARK] ? previous[WRAPPER_BASE] : previous;
		const factory = ((tui: TUI, theme: EditorTheme, keybindings: KeybindingsManager) => {
			const base = baseFactory?.(tui, theme, keybindings) ?? new CustomEditor(tui, theme, keybindings);
			const editor = new PromptHistoryEditor(base, tui, keybindings, ctx, state);
			return new Proxy(editor, {
				has(target, prop) {
					return prop in target || prop in base;
				},
				get(target, prop, receiver) {
					if (prop in target) return Reflect.get(target, prop, receiver);

					const value = (base as Record<PropertyKey, unknown>)[prop];
					return typeof value === "function" ? value.bind(base) : value;
				},
				set(target, prop, value, receiver) {
					if (prop in target) return Reflect.set(target, prop, value, receiver);
					(base as Record<PropertyKey, unknown>)[prop] = value;
					return true;
				},
			}) as Component;
		}) as MarkedEditorFactory;
		factory[WRAPPER_MARK] = true;
		factory[WRAPPER_BASE] = baseFactory;
		ctx.ui.setEditorComponent(factory);
	});

	pi.on("before_agent_start", (event, ctx) => {
		state.entries = appendPrompt(ctx, event.prompt);
		state.index = undefined;
		state.draft = "";
	});

	pi.registerCommand("prompt-history", {
		description: "Show or clear persistent prompt history",
		handler: (args, ctx) => {
			const command = args.trim().toLowerCase();
			if (command === "clear") {
				writeHistoryEntries([]);
				state.entries = [];
				state.index = undefined;
				state.draft = "";
				ctx.ui.notify("Persistent prompt history cleared", "info");
				return;
			}

			if (command.length > 0) {
				ctx.ui.notify("Usage: /prompt-history [clear]", "warning");
				return;
			}

			ctx.ui.notify(`${state.entries.length} prompts in ${HISTORY_FILE}`, "info");
		},
	});
}
