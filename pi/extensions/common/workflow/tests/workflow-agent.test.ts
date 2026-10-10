import assert from "node:assert/strict";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { currentDepth, resolveModel, WorkflowAgent } from "../src/agent.js";

const models = [
  { provider: "openai-codex", id: "gpt-6.1-sol" },
  { provider: "fireworks", id: "accounts/fireworks/models/kimi-k3" },
];

const registry = {
  find(provider: string, modelId: string) {
    return models.find((model) => model.provider === provider && model.id === modelId);
  },
};

const fakePi = fileURLToPath(new URL("./fixtures/fake-pi.mjs", import.meta.url));

function fakeAgent(mode: string, options: { parentModel?: string; thinkingLevel?: string } = {}) {
  process.env.FAKE_PI_MODE = mode;
  return new WorkflowAgent({ command: process.execPath, commandArgs: [fakePi], modelRegistry: registry, ...options });
}

test("resolveModel accepts a known provider-qualified model", () => {
  assert.equal(resolveModel(registry, "openai-codex/gpt-6.1-sol"), "openai-codex/gpt-6.1-sol");
});

test("resolveModel splits on the first slash so model ids may contain slashes", () => {
  assert.equal(
    resolveModel(registry, "fireworks/accounts/fireworks/models/kimi-k3"),
    "fireworks/accounts/fireworks/models/kimi-k3",
  );
});

test("resolveModel rejects unknown models", () => {
  assert.throws(
    () => resolveModel(registry, "greendale/human-being-9000"),
    /unknown model "greendale\/human-being-9000"/,
  );
});

test("resolveModel rejects models without a provider", () => {
  assert.throws(() => resolveModel(registry, "gpt-6.1-sol"), /must be "provider\/model-id"/);
});

test("currentDepth reads the depth variable and treats junk as zero", () => {
  assert.equal(currentDepth({ PI_WORKFLOW_DEPTH: "1" }), 1);
  assert.equal(currentDepth({ PI_WORKFLOW_DEPTH: "nope" }), 0);
  assert.equal(currentDepth({}), 0);
});

test("a child runs pi in rpc mode on the requested model and thinking level", async () => {
  const text = await fakeAgent("text", { parentModel: "claude-bridge/claude-opus-5-5", thinkingLevel: "high" }).run(
    "hello",
    { model: "openai-codex/gpt-6.1-sol", label: "probe" },
  );
  const report = JSON.parse(text);

  assert.deepEqual(report.argv.slice(0, 3), ["--mode", "rpc", "--no-session"]);
  assert.equal(report.argv[report.argv.indexOf("--model") + 1], "openai-codex/gpt-6.1-sol");
  assert.equal(report.argv[report.argv.indexOf("--thinking") + 1], "high");
  assert.match(report.argv[report.argv.indexOf("-e") + 1], /child-extension\.ts$/);
  assert.equal(report.schema, null);
  assert.equal(report.depth, String(currentDepth() + 1));
  assert.match(report.prompt, /Task label: probe\n\nhello/);
});

test("a child without a requested model runs on the parent's model", async () => {
  const report = JSON.parse(await fakeAgent("text", { parentModel: "claude-bridge/claude-opus-5-5" }).run("hi"));
  assert.equal(report.argv[report.argv.indexOf("--model") + 1], "claude-bridge/claude-opus-5-5");
});

test("a schema reaches the child and its structured_output becomes the result", async () => {
  const schema = { type: "object", properties: { ok: { type: "boolean" } } } as any;
  assert.deepEqual(await fakeAgent("schema").run("go", { schema }), { ok: true });
});

test("a model error in the child fails the agent with the provider's message", async () => {
  await assert.rejects(fakeAgent("error").run("go"), /token expired/);
});

test("a rejected prompt fails the agent", async () => {
  await assert.rejects(fakeAgent("reject").run("go"), /no model/);
});

test("a child that exits early fails the agent with its stderr", async () => {
  await assert.rejects(fakeAgent("crash").run("go"), /code 3 before finishing: fake pi crashed/);
});

test("extension dialogs in a child are cancelled instead of hanging", async () => {
  const response = JSON.parse(await fakeAgent("ui").run("go"));
  assert.deepEqual(response, { type: "extension_ui_response", id: "ui-1", cancelled: true });
});

test("aborting the signal aborts the child", async () => {
  const controller = new AbortController();
  const run = fakeAgent("hang").run("go", { signal: controller.signal });
  setTimeout(() => controller.abort(), 100);
  await assert.rejects(run, /aborted/);
});

test("inherit-parent and auto run the child on the parent's model", async () => {
  for (const model of ["inherit-parent", "auto"]) {
    const report = JSON.parse(
      await fakeAgent("text", { parentModel: "claude-bridge/claude-opus-5-5" }).run("hi", { model }),
    );
    assert.equal(report.argv[report.argv.indexOf("--model") + 1], "claude-bridge/claude-opus-5-5");
  }
});
