import assert from "node:assert/strict";
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { loadRoles } from "../src/roles.js";
import { runWorkflow } from "../src/workflow.js";

const realModelsFile = fileURLToPath(
  new URL("../../../../../agents/skills/common/setup-llama-stack/models.json", import.meta.url),
);

function modelsFile(content: unknown): string {
  const file = join(mkdtempSync(join(tmpdir(), "greendale-")), "models.json");
  writeFileSync(file, JSON.stringify(content));
  return file;
}

const sample = {
  roles: { "bug-fix": "strongest", "how critics": "panel" },
  hosts: { pi: { strongest: "openai-codex/gpt-6.1-sol", panel: ["inherit-parent", "fireworks/a/b"] } },
};

test("loadRoles resolves single-model and panel tiers to lists", () => {
  assert.deepEqual(loadRoles("pi", modelsFile(sample)), {
    "bug-fix": ["openai-codex/gpt-6.1-sol"],
    "how critics": ["inherit-parent", "fireworks/a/b"],
  });
});

test("loadRoles returns no roles when the file is missing", () => {
  assert.deepEqual(loadRoles("pi", join(tmpdir(), "no-such-greendale-models.json")), {});
});

test("loadRoles rejects a role whose tier the host lacks", () => {
  const file = modelsFile({ ...sample, hosts: { pi: { strongest: "x/y" } } });
  assert.throws(() => loadRoles("pi", file), /role "how critics" uses tier "panel", which hosts.pi lacks/);
});

test("loadRoles rejects a missing host", () => {
  assert.throws(() => loadRoles("codex", modelsFile(sample)), /needs "roles" and "hosts.codex"/);
});

test("loadRoles rejects an empty panel", () => {
  const file = modelsFile({ ...sample, hosts: { pi: { strongest: "x/y", panel: [] } } });
  assert.throws(() => loadRoles("pi", file), /hosts.pi.panel must be a model or a non-empty list/);
});

test("the shipped models file resolves every role for every host", () => {
  for (const host of ["pi", "claude-code", "codex", "opencode"]) {
    const roles = loadRoles(host, realModelsFile);
    assert.ok(Object.keys(roles).length > 0, host);
  }
});

test("workflow scripts can fan out over a role's models", async () => {
  const calls: Array<string | undefined> = [];
  const agent = {
    async run(_prompt: string, options: { model?: string } = {}) {
      calls.push(options.model);
      return "ok";
    },
  };

  await runWorkflow(
    `export const meta = { name: 'roles_demo', description: 'Fan out over a role' }
await parallel(roles['how critics'].map(model => () => agent('critique', { label: model, model })))
return { ok: true }
`,
    { agent: agent as any, roles: loadRoles("pi", modelsFile(sample)) },
  );

  assert.deepEqual(calls, ["inherit-parent", "fireworks/a/b"]);
});
