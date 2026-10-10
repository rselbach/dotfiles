import { fileURLToPath } from "node:url";
import type { Static, TSchema } from "typebox";
import { runChild } from "./child.js";

/** Environment variable carrying the structured-output schema to a child. */
export const SCHEMA_ENV = "PI_WORKFLOW_SCHEMA";
/** Environment variable carrying how many workflow layers sit above a process. */
export const DEPTH_ENV = "PI_WORKFLOW_DEPTH";
/** Processes at this depth or deeper do not get the workflow tool, so fan-out nests at most twice. */
export const MAX_WORKFLOW_DEPTH = 2;

const CHILD_EXTENSION = fileURLToPath(new URL("./child-extension.ts", import.meta.url));

export interface ModelLookup {
  find(provider: string, modelId: string): unknown;
}

export interface WorkflowAgentOptions {
  cwd?: string;
  /** Extra system guidance prepended to every subagent task. */
  instructions?: string;
  /** Validates requested models before a child starts. */
  modelRegistry?: ModelLookup;
  /** Parent session model as "provider/model-id"; children use it when no model is requested. */
  parentModel?: string;
  /** Thinking level passed to every child. */
  thinkingLevel?: string;
  /** Executable that starts pi. Default: `pi` on PATH. */
  command?: string;
  /** Arguments placed before pi's own, for a command such as `node cli.js`. */
  commandArgs?: string[];
}

export interface AgentRunOptions<TSchemaDef extends TSchema | undefined = undefined> {
  label?: string;
  /** Model as "provider/model-id"; defaults to the parent session's model. */
  model?: string;
  schema?: TSchemaDef;
  instructions?: string;
  signal?: AbortSignal;
}

export type AgentRunResult<TSchemaDef extends TSchema | undefined> = TSchemaDef extends TSchema
  ? Static<TSchemaDef>
  : string;

/** Model values that run a child on the parent session's model. */
export const PARENT_MODEL_ALIASES: readonly string[] = ["inherit-parent", "auto"];

/** Validates a "provider/model-id" reference; model ids may contain slashes. */
export function resolveModel(registry: ModelLookup | undefined, ref: string): string {
  const slash = ref.indexOf("/");
  if (slash <= 0 || slash === ref.length - 1) {
    throw new Error(`model "${ref}" must be "provider/model-id"`);
  }
  if (registry && !registry.find(ref.slice(0, slash), ref.slice(slash + 1))) {
    throw new Error(`unknown model "${ref}"`);
  }
  return ref;
}

/** Number of workflow layers above this process, from its environment. */
export function currentDepth(env: NodeJS.ProcessEnv = process.env): number {
  const depth = Number(env[DEPTH_ENV] ?? 0);
  return Number.isInteger(depth) && depth > 0 ? depth : 0;
}

/** Runs each subagent as its own `pi --mode rpc` process. */
export class WorkflowAgent {
  private readonly cwd: string;
  private readonly instructions?: string;
  private readonly modelRegistry?: ModelLookup;
  private readonly parentModel?: string;
  private readonly thinkingLevel?: string;
  private readonly command: string;
  private readonly commandArgs: string[];

  constructor(options: WorkflowAgentOptions = {}) {
    this.cwd = options.cwd ?? process.cwd();
    this.instructions = options.instructions;
    this.modelRegistry = options.modelRegistry;
    this.parentModel = options.parentModel;
    this.thinkingLevel = options.thinkingLevel;
    this.command = options.command ?? "pi";
    this.commandArgs = options.commandArgs ?? [];
  }

  async run<TSchemaDef extends TSchema | undefined = undefined>(
    prompt: string,
    options: AgentRunOptions<TSchemaDef> = {},
  ): Promise<AgentRunResult<TSchemaDef>> {
    if (options.signal?.aborted) throw new Error("Subagent was aborted");
    const model =
      options.model && !PARENT_MODEL_ALIASES.includes(options.model)
        ? resolveModel(this.modelRegistry, options.model)
        : this.parentModel;

    const args = [...this.commandArgs, "--mode", "rpc", "--no-session", "-e", CHILD_EXTENSION];
    if (model) args.push("--model", model);
    if (this.thinkingLevel) args.push("--thinking", this.thinkingLevel);

    const env: NodeJS.ProcessEnv = { ...process.env, [DEPTH_ENV]: String(currentDepth() + 1) };
    if (options.schema) env[SCHEMA_ENV] = JSON.stringify(options.schema);
    else delete env[SCHEMA_ENV];

    const outcome = await runChild(
      this.command,
      args,
      { cwd: this.cwd, env, signal: options.signal },
      this.buildPrompt(prompt, options as AgentRunOptions<any>, Boolean(options.schema)),
    );

    if (outcome.aborted || options.signal?.aborted) throw new Error("Subagent was aborted");
    if (outcome.promptError) throw new Error(outcome.promptError);
    if (!outcome.settled) {
      const detail = outcome.stderr.trim() ? `: ${outcome.stderr.trim()}` : "";
      throw new Error(`pi exited with code ${outcome.exitCode} before finishing${detail}`);
    }
    if (outcome.lastAssistant?.stopReason === "error") {
      throw new Error(outcome.lastAssistant.errorMessage ?? "subagent model request failed");
    }

    if (options.schema) {
      if (!outcome.structured) throw new Error("Subagent finished without calling structured_output");
      return outcome.structured.value as AgentRunResult<TSchemaDef>;
    }
    return outcome.lastText as AgentRunResult<TSchemaDef>;
  }

  private buildPrompt(prompt: string, options: AgentRunOptions<any>, structured: boolean): string {
    const parts = [
      this.instructions,
      options.instructions,
      options.label ? `Task label: ${options.label}` : undefined,
      prompt,
    ].filter(Boolean);

    if (structured) {
      parts.push(
        [
          "Final output contract:",
          "- Your final action MUST be a structured_output tool call.",
          "- The structured_output arguments are the return value of this subagent.",
          "- Do not emit a prose final answer instead of structured_output.",
          "- If you need to inspect files or run commands first, do so, then call structured_output exactly once.",
        ].join("\n"),
      );
    }

    return parts.join("\n\n");
  }
}
