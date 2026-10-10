import assert from "node:assert/strict";
import test from "node:test";
import { createWorkflowTool, formatWorkflowResultText } from "../src/workflow-tool.js";

test("createWorkflowTool describes phases as optional and dynamic", () => {
  const tool = createWorkflowTool();

  assert.match(tool.promptSnippet ?? "", /export const meta = \{ name: 'short_snake_case', description:/);
  assert.doesNotMatch(tool.promptSnippet ?? "", /phases: \[/);
  assert.ok(tool.promptGuidelines?.some((line) => line.includes("meta.phases is optional metadata")));
  assert.ok(tool.promptGuidelines?.some((line) => line.includes("Phase names may be conditional or built in a loop")));
});

test("formatWorkflowResultText includes logs so failed agents are explained", () => {
  const text = formatWorkflowResultText({
    meta: { name: "demo", description: "demo" },
    result: { a: null },
    logs: ['agent a failed: unknown model "greendale/human-being-9000"'],
    phases: [],
    agentCount: 1,
    durationMs: 1,
  });

  assert.match(text, /Result:\n\{\n {2}"a": null\n\}/);
  assert.match(text, /Logs:\n- agent a failed: unknown model/);
});

test("formatWorkflowResultText omits the logs section when there are no logs", () => {
  const text = formatWorkflowResultText({
    meta: { name: "demo", description: "demo" },
    result: { a: 1 },
    logs: [],
    phases: [],
    agentCount: 1,
    durationMs: 1,
  });

  assert.doesNotMatch(text, /Logs:/);
});
