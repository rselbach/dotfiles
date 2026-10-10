import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { SCHEMA_ENV } from "./agent.js";
import { createStructuredOutputTool } from "./structured-output.js";

/** Loaded into workflow children with `-e`; registers structured_output when the parent passed a schema. */
export default function childExtension(pi: ExtensionAPI) {
  const raw = process.env[SCHEMA_ENV];
  if (!raw) return;

  const tool = createStructuredOutputTool({ schema: JSON.parse(raw), capture: { called: false, value: undefined } });
  pi.registerTool(tool as any);
  pi.on("session_start", () => {
    const active = pi.getActiveTools();
    if (!active.includes(tool.name)) pi.setActiveTools([...active, tool.name]);
  });
}
