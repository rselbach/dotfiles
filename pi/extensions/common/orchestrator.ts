import { readFileSync } from "node:fs";
import { join } from "node:path";
import type { AssistantMessage, TextContent } from "@earendil-works/pi-ai";
import {
	createAgentSession,
	DefaultResourceLoader,
	getAgentDir,
	SessionManager,
	SettingsManager,
	truncateHead,
	type ExtensionAPI,
	type ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const MINION_PROMPT_PATH = join(getAgentDir(), "agents", "minion.md");
const MINION_TOOL = "minion";
const STATUS_KEY = "orchestrator";
const WORKFLOW_TOOL = "workflow";

const MinionParams = Type.Object({
	task: Type.String({
		description: "Self-contained task brief for one focused minion",
	}),
});

const ORCHESTRATOR_PROMPT = `Orchestrator mode is enabled. You are the primary coordinating agent for this repository. Do meta-work only: coordinate, brief, and synthesize. Delegate all actual work through the minion tool, including implementation, exploration, discovery, codebase searches, and trivial edits.

Use one minion call for an indivisible task. When work can be decomposed, make multiple minion tool calls in the same response so Pi runs them in parallel. Use later minion calls for sequential follow-up work after reviewing earlier results.

Direct tool use is reserved for coordination overhead: a quick peek to write a better brief, a fast read-only check of a minion report, or answering a question about coordination state. If a tool call would produce the answer or artifact the user requested, delegate it.

Give every minion a clear, self-contained brief with the goal, constraints, expected output, relevant paths and known context. Minions already receive the managed minion system prompt and repository instructions.

Synthesize minion results, decide next steps, and report back concisely.`;

function loadMinionPrompt(): string {
	const prompt = readFileSync(MINION_PROMPT_PATH, "utf8").trim();
	if (!prompt) throw new Error(`Minion prompt is empty: ${MINION_PROMPT_PATH}`);
	return prompt;
}

function lastAssistantText(messages: unknown[]): string {
	for (let index = messages.length - 1; index >= 0; index--) {
		const message = messages[index] as Partial<AssistantMessage> | undefined;
		if (message?.role !== "assistant" || !Array.isArray(message.content)) {
			continue;
		}
		const text = message.content
			.filter((part): part is TextContent => part.type === "text")
			.map((part) => part.text)
			.join("");
		if (text.trim()) return text;
	}
	return "";
}

export default function orchestratorExtension(pi: ExtensionAPI) {
	const minionPrompt = loadMinionPrompt();
	let enabled = false;

	function setOrchestratorTools(active: boolean): void {
		const tools = pi
			.getActiveTools()
			.filter((tool) => tool !== MINION_TOOL && tool !== WORKFLOW_TOOL);
		if (active) tools.push(MINION_TOOL);
		pi.setActiveTools(tools);
	}

	function updateStatus(ctx: ExtensionContext): void {
		ctx.ui.setStatus(
			STATUS_KEY,
			enabled ? ctx.ui.theme.fg("accent", "orchestrator") : undefined,
		);
	}

	function setMode(active: boolean, ctx: ExtensionContext): void {
		enabled = active;
		setOrchestratorTools(active);
		updateStatus(ctx);
		ctx.ui.notify(
			`Orchestrator mode ${active ? "enabled" : "disabled"}`,
			"info",
		);
	}

	pi.registerTool({
		name: MINION_TOOL,
		label: "Minion",
		description:
			"Delegate one focused task to an isolated Pi minion using the current model at medium reasoning. Multiple minion calls in one response run in parallel. Output is limited to 50KB or 2000 lines.",
		promptSnippet:
			"Delegate one focused task to an isolated minion using the current model at medium reasoning",
		promptGuidelines: [
			"Use minion for all execution work while orchestrator mode is enabled. Give each minion a self-contained task brief.",
			"Issue multiple minion calls in the same response when tasks are independent so they run in parallel.",
		],
		parameters: MinionParams,
		async execute(_toolCallId, params, signal, onUpdate, ctx) {
			if (!ctx.model) throw new Error("Minion cannot start without a selected model");
			if (signal?.aborted) throw new Error("Minion was aborted");

			onUpdate?.({
				content: [{ type: "text", text: "Minion working..." }],
			});

			const settingsManager = SettingsManager.inMemory({
				defaultThinkingLevel: "medium",
			});
			const resourceLoader = new DefaultResourceLoader({
				cwd: ctx.cwd,
				agentDir: getAgentDir(),
				settingsManager,
				noExtensions: true,
				appendSystemPrompt: [minionPrompt],
			});
			await resourceLoader.reload();

			const model = ctx.model;
			const { session } = await createAgentSession({
				cwd: ctx.cwd,
				agentDir: getAgentDir(),
				model,
				modelRegistry: ctx.modelRegistry,
				thinkingLevel: "medium",
				tools: ["read", "bash", "edit", "write", "grep", "find", "ls"],
				resourceLoader,
				settingsManager,
				sessionManager: SessionManager.inMemory(ctx.cwd),
			});

			let abortPromise: Promise<void> | undefined;
			const onAbort = () => {
				abortPromise = session.abort();
			};
			signal?.addEventListener("abort", onAbort, { once: true });
			if (signal?.aborted) onAbort();

			try {
				if (abortPromise) {
					await abortPromise;
					throw new Error("Minion was aborted");
				}
				await session.prompt(params.task);
				if (signal?.aborted) throw new Error("Minion was aborted");

				const output = lastAssistantText(session.messages);
				if (!output.trim()) throw new Error("Minion returned no final response");
				const truncated = truncateHead(output);
				const suffix = truncated.truncated
					? "\n\n[Minion output truncated to 50KB or 2000 lines]"
					: "";
				return {
					content: [
						{ type: "text", text: `${truncated.content}${suffix}` },
					],
					details: {
						model: `${model.provider}/${model.id}`,
						thinkingLevel: session.thinkingLevel,
						truncated: truncated.truncated,
					},
				};
			} finally {
				signal?.removeEventListener("abort", onAbort);
				if (abortPromise) await abortPromise;
				session.dispose();
			}
		},
	});

	pi.on("session_start", (_event, ctx) => {
		enabled = false;
		setOrchestratorTools(false);
		updateStatus(ctx);
	});

	pi.on("before_agent_start", (event) => {
		if (!enabled) {
			setOrchestratorTools(false);
			return undefined;
		}
		return {
			systemPrompt: `${event.systemPrompt}\n\n${ORCHESTRATOR_PROMPT}`,
		};
	});

	pi.on("tool_call", (event) => {
		if (event.toolName !== MINION_TOOL && event.toolName !== WORKFLOW_TOOL) {
			return undefined;
		}
		if (event.toolName === WORKFLOW_TOOL) {
			return {
				block: true,
				reason: "Use the minion tool for orchestrator delegation.",
			};
		}
		if (enabled) return undefined;
		return {
			block: true,
			reason: "Orchestrator mode is disabled. Run /orchestrator on first.",
		};
	});

	pi.registerCommand("orchestrator", {
		description: "Toggle minion-based orchestrator mode",
		handler: async (args, ctx) => {
			const requested = args.trim().toLowerCase();
			if (requested === "status") {
				ctx.ui.notify(
					`Orchestrator mode is ${enabled ? "enabled" : "disabled"}`,
					"info",
				);
				return;
			}
			if (
				requested !== "" &&
				requested !== "on" &&
				requested !== "off"
			) {
				ctx.ui.notify(
					"Usage: /orchestrator [on|off|status]",
					"warning",
				);
				return;
			}

			await ctx.waitForIdle();
			const active = requested === "on" || (requested === "" && !enabled);
			setMode(active, ctx);
		},
	});
}
