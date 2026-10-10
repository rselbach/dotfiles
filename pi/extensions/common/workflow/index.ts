import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { createWorkflowTool, currentDepth, MAX_WORKFLOW_DEPTH } from "./src/index.js";

export default function extension(pi: ExtensionAPI) {
  if (currentDepth() >= MAX_WORKFLOW_DEPTH) return;

  const workflowTool = createWorkflowTool({ thinkingLevel: () => pi.getThinkingLevel() });
  pi.registerTool(workflowTool);

  pi.on("session_start", () => {
    const active = pi.getActiveTools();
    if (!active.includes(workflowTool.name)) {
      pi.setActiveTools([...active, workflowTool.name]);
    }
  });
}
