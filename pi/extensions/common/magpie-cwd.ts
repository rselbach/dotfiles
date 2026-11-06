// magpie-cwd: states the working directory as a plain line for magpie's
// Claude subscription bridge, whose clientWorkDir reads "Current working
// directory: X" but not Pi's multi-line <cwd> section. Without it, Claude
// Code runs in magpie's shared temp folder instead of the session's.
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	pi.on("before_agent_start", (event) => {
		const opts = event.systemPromptOptions;
		opts.sections.workdir = `Current working directory: ${opts.cwd.replace(/\\/g, "/")}`;
	});
}
