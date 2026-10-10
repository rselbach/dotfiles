import { spawn } from "node:child_process";

const DIALOG_METHODS = new Set(["select", "confirm", "input", "editor"]);
const STDERR_CAP = 4000;
const EXIT_GRACE_MS = 10_000;

export interface ChildRunOptions {
  cwd: string;
  env: NodeJS.ProcessEnv;
  signal?: AbortSignal;
}

export interface ChildOutcome {
  settled: boolean;
  aborted: boolean;
  exitCode: number | null;
  stderr: string;
  promptError?: string;
  lastAssistant?: AssistantRecord;
  /** Text of the last assistant message that had any. */
  lastText: string;
  structured?: { value: unknown };
}

export interface AssistantRecord {
  content?: Array<{ type: string; text?: string }>;
  stopReason?: string;
  errorMessage?: string;
}

function assistantText(message: AssistantRecord): string {
  if (!Array.isArray(message.content)) return "";
  return message.content
    .filter((part) => part.type === "text")
    .map((part) => part.text ?? "")
    .join("");
}

/**
 * Runs one prompt in a `pi --mode rpc` child and collects what the parent needs.
 * The prompt goes in as an RPC command, so argv never caps it. Stdin closes after
 * `agent_settled` (or a rejected or handled prompt), and pi then exits on its own.
 */
export function runChild(
  command: string,
  args: string[],
  options: ChildRunOptions,
  prompt: string,
): Promise<ChildOutcome> {
  return new Promise((resolve, reject) => {
    const outcome: ChildOutcome = { settled: false, aborted: false, exitCode: null, stderr: "", lastText: "" };
    const child = spawn(command, args, { cwd: options.cwd, env: options.env, stdio: ["pipe", "pipe", "pipe"] });
    let stdinOpen = true;
    let killTimer: NodeJS.Timeout | undefined;

    const send = (record: unknown) => {
      if (stdinOpen) child.stdin.write(`${JSON.stringify(record)}\n`);
    };
    const closeStdin = () => {
      if (!stdinOpen) return;
      stdinOpen = false;
      child.stdin.end();
      killTimer = setTimeout(() => child.kill("SIGKILL"), EXIT_GRACE_MS);
      killTimer.unref();
    };
    const onAbort = () => {
      outcome.aborted = true;
      send({ type: "abort" });
      closeStdin();
    };

    const onRecord = (record: any) => {
      switch (record?.type) {
        case "response":
          if (record.command !== "prompt") return;
          if (!record.success) {
            outcome.promptError = String(record.error ?? "prompt rejected");
            closeStdin();
          } else if (record.data?.disposition === "handled") {
            closeStdin();
          }
          return;
        case "extension_ui_request":
          if (DIALOG_METHODS.has(record.method))
            send({ type: "extension_ui_response", id: record.id, cancelled: true });
          return;
        case "message_end":
          if (record.message?.role === "assistant") {
            outcome.lastAssistant = record.message;
            const text = assistantText(record.message);
            if (text.trim()) outcome.lastText = text;
          }
          return;
        case "tool_execution_end":
          if (record.toolName === "structured_output" && !record.isError) {
            outcome.structured = { value: record.result?.details };
          }
          return;
        case "agent_settled":
          outcome.settled = true;
          if (record.aborted) outcome.aborted = true;
          closeStdin();
          return;
      }
    };

    let buffered = "";
    child.stdout.setEncoding("utf8");
    child.stdout.on("data", (chunk: string) => {
      buffered += chunk;
      let newline = buffered.indexOf("\n");
      while (newline !== -1) {
        const line = buffered.slice(0, newline).replace(/\r$/, "");
        buffered = buffered.slice(newline + 1);
        if (line.trim()) {
          try {
            onRecord(JSON.parse(line));
          } catch {
            // stdout is protocol-only; an unparseable line is not a record we act on
          }
        }
        newline = buffered.indexOf("\n");
      }
    });
    child.stderr.setEncoding("utf8");
    child.stderr.on("data", (chunk: string) => {
      outcome.stderr = (outcome.stderr + chunk).slice(-STDERR_CAP);
    });
    child.stdin.on("error", () => {});

    child.on("error", (error) => {
      options.signal?.removeEventListener("abort", onAbort);
      reject(new Error(`could not start ${command}: ${error.message}`));
    });
    child.on("close", (code) => {
      clearTimeout(killTimer);
      options.signal?.removeEventListener("abort", onAbort);
      outcome.exitCode = code;
      resolve(outcome);
    });

    if (options.signal?.aborted) onAbort();
    else options.signal?.addEventListener("abort", onAbort, { once: true });
    send({ id: "prompt", type: "prompt", message: prompt });
  });
}
