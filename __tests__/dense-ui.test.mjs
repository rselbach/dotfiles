// Run with bun test __tests__/dense-ui.test.mjs (requires Pi installed globally).
import { execFileSync } from "node:child_process";
import { createRequire } from "node:module";
import { join } from "node:path";
import { afterEach, expect, spyOn, test } from "bun:test";

const globalModules = execFileSync("npm", ["root", "-g"], { encoding: "utf8" }).trim();
const piRoot = join(globalModules, "@earendil-works/pi-coding-agent");
const piPath = join(piRoot, "dist/index.js");
const piRequire = createRequire(join(piRoot, "package.json"));
const tuiPath = join(piRoot, "node_modules/@earendil-works/pi-tui/dist/index.js");
const { visibleWidth } = await import(tuiPath);
const { createJiti } = piRequire("jiti");
const jiti = createJiti(import.meta.url, {
	alias: {
		"@earendil-works/pi-coding-agent": piPath,
		"@earendil-works/pi-tui": tuiPath,
	},
});
const denseUiExtension = await jiti.import("../pi/extensions/common/dense-ui.ts", { default: true });

let cleanup = () => {};
afterEach(() => cleanup());

function setup() {
	let now = 0;
	let editor;
	let tick;
	let renders = 0;
	const clock = spyOn(performance, "now").mockImplementation(() => now);
	const timer = spyOn(globalThis, "setInterval").mockImplementation((callback) => {
		tick = callback;
		return 1;
	});
	const clearTimer = spyOn(globalThis, "clearInterval").mockImplementation(() => {});
	const handlers = new Map();
	const tui = { requestRender: () => renders++, terminal: { rows: 40, columns: 160 } };
	const ctx = {
		cwd: "/Greendale",
		ui: {
			theme: { fg: (_color, text) => text },
			setWorkingVisible() {},
			setFooter(factory) {
				factory?.(
					tui,
					{},
					{
						getGitBranch: () => null,
						getExtensionStatuses: () => new Map(),
						onBranchChange: () => () => {},
					},
				);
			},
			setHeader() {},
			setEditorComponent(factory) {
				editor = factory?.(tui, { borderColor: (text) => text }, {});
			},
		},
		isIdle: () => true,
		hasPendingMessages: () => false,
		getContextUsage: () => undefined,
		sessionManager: { getEntries: () => [], getSessionId: () => "Greendale" },
	};
	denseUiExtension({
		on: (name, handler) => handlers.set(name, handler),
		registerCommand() {},
		getSessionName: () => "Greendale",
		getThinkingLevel: () => "high",
		getActiveTools: () => [],
	});
	const emit = (name, event = {}) => handlers.get(name)?.(event, ctx);
	cleanup = () => {
		emit("session_shutdown");
		clock.mockRestore();
		timer.mockRestore();
		clearTimer.mockRestore();
	};
	emit("session_start");
	emit("agent_start");
	return {
		emit,
		at: (time) => {
			now = time;
		},
		delta: (type, text) =>
			emit("message_update", {
				assistantMessageEvent: { type, delta: text },
			}),
		lines: (width = 160) => editor.render(width),
		footer: () => editor.render(160).at(-1),
		tick: () => tick(),
		renders: () => renders,
	};
}

test("counts text, thinking, and tool arguments, not chunks or end events", () => {
	const ui = setup();
	expect(ui.footer()).not.toContain("tok/s");
	ui.delta("text_delta", "Troy".repeat(10));
	expect(ui.footer()).not.toContain("tok/s");
	ui.at(500);
	ui.delta("thinking_delta", "Abed".repeat(10));
	ui.delta("toolcall_delta", "Dean".repeat(10));
	ui.delta("text_end", "Troy".repeat(100));
	ui.delta("text_delta", "");
	ui.at(1_000);
	expect(ui.footer()).toContain("$0.000 30 tok/s");
	expect(ui.footer()).not.toContain("~");
	const before = ui.renders();
	ui.tick();
	expect(ui.renders()).toBeGreaterThan(before);
});

test("uses a rolling three-second window and drops to zero during a stall", () => {
	const ui = setup();
	ui.delta("text_delta", "Troy".repeat(90));
	ui.at(2_000);
	ui.delta("text_delta", "Abed".repeat(30));
	ui.at(3_000);
	expect(ui.footer()).toContain("10 tok/s");
	ui.at(5_000);
	ui.tick();
	expect(ui.footer()).toContain("0 tok/s");
});

test("keeps a time-weighted average between responses without counting idle time", () => {
	const ui = setup();
	ui.delta("text_delta", "Troy".repeat(40));
	ui.at(1_000);
	expect(ui.footer()).toContain("40 tok/s");
	ui.emit("message_end", { message: { role: "assistant" } });
	expect(ui.footer()).toContain("avg 40 tok/s");
	ui.emit("message_end", { message: { role: "toolResult" } });
	ui.emit("agent_settled");
	ui.at(20_000);
	expect(ui.footer()).toContain("avg 40 tok/s");
	ui.emit("agent_start");
	ui.emit("message_start", { message: { role: "assistant" } });
	expect(ui.footer()).toContain("avg 40 tok/s");
	ui.at(30_000);
	ui.delta("toolcall_delta", "Abed".repeat(20));
	expect(ui.footer()).toContain("avg 40 tok/s");
	ui.at(32_000);
	expect(ui.footer()).toContain("10 tok/s");
	expect(ui.footer()).not.toContain("avg");
	ui.emit("message_end", { message: { role: "assistant" } });
	ui.emit("agent_settled");
	ui.at(60_000);
	expect(ui.footer()).toContain("avg 20 tok/s");
	ui.emit("session_start");
	expect(ui.footer()).not.toContain("tok/s");
});

test("averages the full stream even after rolling samples expire", () => {
	const ui = setup();
	ui.delta("thinking_delta", "Troy".repeat(90));
	ui.at(2_000);
	ui.delta("text_delta", "Abed".repeat(30));
	ui.at(5_000);
	expect(ui.footer()).toContain("0 tok/s");
	ui.emit("message_end", { message: { role: "assistant" } });
	expect(ui.footer()).toContain("avg 24 tok/s");
});

test("retains partial output when an agent settles without a message end", () => {
	const ui = setup();
	ui.delta("thinking_delta", "Troy".repeat(10));
	ui.at(1_000);
	ui.emit("agent_settled");
	expect(ui.footer()).toContain("avg 10 tok/s");
	ui.at(10_000);
	ui.emit("agent_settled");
	ui.emit("message_start", { message: { role: "assistant" } });
	ui.emit("message_end", { message: { role: "assistant" } });
	expect(ui.footer()).toContain("avg 10 tok/s");
});

test("bounds short-burst estimates and ignores empty responses", () => {
	const ui = setup();
	ui.emit("message_end", { message: { role: "assistant" } });
	expect(ui.footer()).not.toContain("tok/s");
	ui.delta("text_delta", "Troy".repeat(10));
	const before = ui.renders();
	ui.emit("message_end", { message: { role: "assistant", stopReason: "aborted" } });
	expect(ui.renders()).toBeGreaterThan(before);
	expect(ui.footer()).toContain("avg 40 tok/s");
});

test("clears interrupted streams on message start and session replacement", () => {
	const ui = setup();
	for (const event of ["message_start", "session_start"]) {
		ui.at(0);
		ui.delta("thinking_delta", "Troy".repeat(10));
		ui.at(1_000);
		expect(ui.footer()).toContain("10 tok/s");
		ui.emit(event, { message: { role: "assistant" } });
		expect(ui.footer()).not.toContain("tok/s");
	}
});

test("keeps rendered editor lines within the terminal width", () => {
	const ui = setup();
	ui.delta("text_delta", "Troy".repeat(40));
	ui.at(1_000);
	for (const idle of [false, true]) {
		if (idle) ui.emit("message_end", { message: { role: "assistant" } });
		for (const width of [12, 20, 40, 80, 120, 160]) {
			for (const line of ui.lines(width)) expect(visibleWidth(line)).toBeLessThanOrEqual(width);
		}
	}
});
