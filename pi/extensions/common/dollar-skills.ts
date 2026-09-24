import { type ExtensionAPI, type SlashCommandInfo } from "@earendil-works/pi-coding-agent";
import {
  fuzzyFilter,
  type AutocompleteItem,
  type AutocompleteProvider,
} from "@earendil-works/pi-tui";

const DOLLAR_TOKEN = /(^|[ \t])\$([a-z0-9-]*)$/;
const DIRECT_SKILL = /^\$([a-z0-9][a-z0-9-]{0,63})(?:\s+(.*))?\s*$/;
const ENDED_TOKEN = /(^|[ \t])\$[a-z0-9-]*[ \t]$/;

function tokenBeforeCursor(text: string) {
  const match = DOLLAR_TOKEN.exec(text);
  if (!match) return null;

  const query = match[2];
  const atStart = match.index === 0;

  return {
    query,
    // Pi submits a selected slash completion at the start of the prompt.
    prefix: `${atStart ? "/" : "$"}${query}`,
  };
}

function skillName(command: SlashCommandInfo) {
  return command.name.replace(/^skill:/, "");
}

function createProvider(pi: ExtensionAPI, current: AutocompleteProvider): AutocompleteProvider {
  return {
    triggerCharacters: ["$"],

    async getSuggestions(lines, cursorLine, cursorCol, options) {
      const beforeCursor = (lines[cursorLine] ?? "").slice(0, cursorCol);
      const token = tokenBeforeCursor(beforeCursor);

      if (!token) {
        return ENDED_TOKEN.test(beforeCursor)
          ? null
          : current.getSuggestions(lines, cursorLine, cursorCol, options);
      }

      const skills = pi
        .getCommands()
        .filter((command): command is SlashCommandInfo => command.source === "skill");

      const matches = token.query
        ? fuzzyFilter(
            skills,
            token.query,
            (command) =>
              `${skillName(command)} ${command.name} ${command.description ?? ""}`,
          )
        : skills;

      if (matches.length === 0) return null;

      return {
        prefix: token.prefix,
        items: matches.map((command) => ({
          value: command.name,
          label: `$${skillName(command)}`,
          ...(command.description && { description: command.description }),
        })),
      };
    },

    applyCompletion(lines, cursorLine, cursorCol, item, prefix) {
      if (!item.value.startsWith("skill:") || !/^[/$]/.test(prefix)) {
        return current.applyCompletion(lines, cursorLine, cursorCol, item, prefix);
      }

      const line = lines[cursorLine] ?? "";
      const before = line.slice(0, cursorCol - prefix.length);
      const after = line.slice(cursorCol).replace(/^ /, "");
      const replacement = `/${item.value} `;
      const updated = [...lines];

      updated[cursorLine] = before + replacement + after;
      return {
        lines: updated,
        cursorLine,
        cursorCol: before.length + replacement.length,
      };
    },

    shouldTriggerFileCompletion(lines, cursorLine, cursorCol) {
      const beforeCursor = (lines[cursorLine] ?? "").slice(0, cursorCol);
      return (
        !!tokenBeforeCursor(beforeCursor) ||
        (current.shouldTriggerFileCompletion?.(lines, cursorLine, cursorCol) ?? true)
      );
    },
  };
}

export default function skillDollarExtension(pi: ExtensionAPI): void {
  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.addAutocompleteProvider((current) => createProvider(pi, current));
  });

  pi.on("input", async ({ source, text }) => {
    if (source === "extension" || !text.trim()) {
      return { action: "continue" };
    }

    if (text.startsWith("\\$")) {
      return { action: "transform", text: text.slice(1) };
    }

    const match = DIRECT_SKILL.exec(text);
    if (!match) return { action: "continue" };

    const args = match[2]?.trim();
    return {
      action: "transform",
      text: `/skill:${match[1]}${args ? ` ${args}` : ""}`,
    };
  });
}
