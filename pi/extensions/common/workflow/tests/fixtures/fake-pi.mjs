// Speaks just enough of pi's RPC protocol for WorkflowAgent tests. FAKE_PI_MODE picks the behavior.
const mode = process.env.FAKE_PI_MODE ?? "text";
const write = (record) => process.stdout.write(`${JSON.stringify(record)}\n`);
const assistant = (content, extra = {}) =>
  write({ type: "message_end", message: { role: "assistant", content, stopReason: "stop", ...extra } });

if (mode === "crash") {
  process.stderr.write("fake pi crashed\n");
  process.exit(3);
}

let buffered = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => {
  buffered += chunk;
  let newline = buffered.indexOf("\n");
  while (newline !== -1) {
    const record = JSON.parse(buffered.slice(0, newline));
    buffered = buffered.slice(newline + 1);
    handle(record);
    newline = buffered.indexOf("\n");
  }
});

function handle(record) {
  if (record.type === "prompt") {
    if (mode === "reject") {
      write({ id: record.id, type: "response", command: "prompt", success: false, error: "no model" });
      return;
    }
    write({ id: record.id, type: "response", command: "prompt", success: true, data: { disposition: "started" } });
    const report = {
      argv: process.argv.slice(2),
      schema: process.env.PI_WORKFLOW_SCHEMA ?? null,
      depth: process.env.PI_WORKFLOW_DEPTH,
      prompt: record.message,
    };
    if (mode === "ui") {
      write({ type: "extension_ui_request", id: "ui-1", method: "confirm", title: "Allow?" });
      return;
    }
    if (mode === "hang") return;
    if (mode === "error") assistant([], { stopReason: "error", errorMessage: "token expired" });
    else if (mode === "schema") {
      assistant([{ type: "toolCall", name: "structured_output" }], { stopReason: "toolUse" });
      write({
        type: "tool_execution_end",
        toolName: "structured_output",
        isError: false,
        result: { details: { ok: true } },
      });
    } else {
      assistant([{ type: "text", text: JSON.stringify(report) }]);
      assistant([]);
    }
    write({ type: "agent_settled", aborted: false });
  }
  if (record.type === "extension_ui_response") {
    assistant([{ type: "text", text: JSON.stringify(record) }]);
    write({ type: "agent_settled", aborted: false });
  }
  if (record.type === "abort") write({ type: "agent_settled", aborted: true });
}
