import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { getAgentDir } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";
import * as fs from "node:fs";
import * as path from "node:path";

const CONFIG_FILE = path.join(getAgentDir(), "kagi-api.json");
const KAGI_API_BASE_URL = "https://kagi.com/api/v1";

interface KagiApiConfig {
  apiKey?: string;
}

interface KagiMeta {
  trace?: string;
  node?: string;
  ms?: number;
  [key: string]: unknown;
}

interface KagiSearchResult {
  url?: string;
  title?: string;
  snippet?: string;
  time?: string;
  image?: {
    url?: string;
    height?: number;
    width?: number;
  };
  props?: Record<string, unknown>;
}

interface KagiSearchResponse {
  meta?: KagiMeta;
  data?: Record<string, unknown>;
}

interface DisplaySearchResult extends KagiSearchResult {
  category: string;
}

interface KagiExtractPage {
  url: string;
  markdown?: string | null;
}

interface KagiExtractError {
  code: string;
  url: string;
  message?: string | null;
  location?: string | null;
}

interface KagiExtractResponse {
  meta?: KagiMeta;
  data?: KagiExtractPage[];
  errors?: KagiExtractError[];
}

interface KagiApiErrorBody {
  meta?: KagiMeta;
  error?: unknown;
  errors?: unknown;
  message?: unknown;
  detail?: unknown;
}

const SEARCH_RESULT_SECTIONS = [
  "search",
  "code",
  "news",
  "interesting_news",
  "interesting_finds",
  "image",
  "video",
  "podcast",
  "podcast_creator",
  "infobox",
  "direct_answer",
  "weather",
  "listicle",
  "web_archive",
  "package_tracking",
  "public_records",
];

const RELATED_SEARCH_SECTIONS = ["related_search", "adjacent_question"];

function loadConfig(): KagiApiConfig {
  try {
    if (fs.existsSync(CONFIG_FILE)) {
      return JSON.parse(fs.readFileSync(CONFIG_FILE, "utf-8")) as KagiApiConfig;
    }
  } catch {
    // Ignore malformed or unreadable config files; the tool will report missing auth.
  }
  return {};
}

function saveConfig(config: KagiApiConfig): void {
  const dir = path.dirname(CONFIG_FILE);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true, mode: 0o700 });
  }

  fs.writeFileSync(CONFIG_FILE, JSON.stringify(config, null, 2), { mode: 0o600 });

  try {
    fs.chmodSync(CONFIG_FILE, 0o600);
  } catch {
    // Best effort only. Some platforms/filesystems do not support POSIX modes.
  }
}

function normalizeApiKey(apiKey: string): string {
  const trimmed = apiKey.trim();
  return trimmed.toLowerCase().startsWith("bearer ") ? trimmed.slice(7).trim() : trimmed;
}

function getApiKey(): string | undefined {
  const envApiKey = process.env.KAGI_API_KEY;
  if (envApiKey?.trim()) return normalizeApiKey(envApiKey);

  const configApiKey = loadConfig().apiKey;
  if (configApiKey?.trim()) return normalizeApiKey(configApiKey);

  return undefined;
}

function setApiKey(apiKey: string): void {
  const normalized = normalizeApiKey(apiKey);
  if (normalized.length < 10) {
    throw new Error("Invalid API key format");
  }
  saveConfig({ apiKey: normalized });
}

function clampInteger(value: unknown, defaultValue: number, min: number, max: number): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return defaultValue;
  return Math.max(min, Math.min(max, Math.trunc(value)));
}

function clampNumber(value: unknown, min: number, max: number): number | undefined {
  if (typeof value !== "number" || !Number.isFinite(value)) return undefined;
  return Math.max(min, Math.min(max, value));
}

function traceSuffix(meta?: KagiMeta): string {
  return meta?.trace ? ` (trace: ${meta.trace})` : "";
}

function unknownToString(value: unknown): string | undefined {
  return typeof value === "string" && value.trim() ? value.trim() : undefined;
}

function extractErrorMessage(body: KagiApiErrorBody | undefined, fallback: string): string {
  if (!body) return fallback;

  const message = unknownToString(body.message) ?? unknownToString(body.detail);
  if (message) return message;

  if (typeof body.error === "string") return body.error;
  if (body.error && typeof body.error === "object") {
    const error = body.error as Record<string, unknown>;
    const errorMessage = unknownToString(error.message) ?? unknownToString(error.detail) ?? unknownToString(error.code);
    if (errorMessage) return errorMessage;
  }

  if (Array.isArray(body.errors) && body.errors.length > 0) {
    const firstError = body.errors[0] as Record<string, unknown> | string;
    if (typeof firstError === "string") return firstError;
    const errorMessage = unknownToString(firstError.message) ?? unknownToString(firstError.detail) ?? unknownToString(firstError.code);
    if (errorMessage) return errorMessage;
  }

  return fallback;
}

async function kagiPost<T>(
  endpoint: string,
  apiKey: string,
  body: Record<string, unknown>,
  signal?: AbortSignal
): Promise<T> {
  const response = await fetch(`${KAGI_API_BASE_URL}${endpoint}`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
      "Accept": "application/json",
    },
    body: JSON.stringify(body),
    signal,
  });

  const text = await response.text();
  let parsed: unknown;
  if (text) {
    try {
      parsed = JSON.parse(text);
    } catch {
      parsed = undefined;
    }
  }

  if (!response.ok) {
    const errorBody = parsed && typeof parsed === "object" ? parsed as KagiApiErrorBody : undefined;
    const message = extractErrorMessage(errorBody, response.statusText || `HTTP ${response.status}`);
    const suffix = traceSuffix(errorBody?.meta);

    if (response.status === 401) {
      throw new Error(`Invalid Kagi API key${suffix}`);
    }
    if (response.status === 403) {
      throw new Error(`Kagi API access forbidden: ${message}${suffix}`);
    }
    if (response.status === 429) {
      throw new Error(`Kagi API rate limit exceeded: ${message}${suffix}`);
    }

    throw new Error(`Kagi API HTTP ${response.status}: ${message}${suffix}`);
  }

  return parsed as T;
}

async function kagiSearch(
  query: string,
  apiKey: string,
  limit: number,
  signal?: AbortSignal
): Promise<KagiSearchResponse> {
  return kagiPost<KagiSearchResponse>("/search", apiKey, {
    query,
    workflow: "search",
    limit,
  }, signal);
}

async function kagiExtract(
  urls: string[],
  apiKey: string,
  timeout: number | undefined,
  signal?: AbortSignal
): Promise<KagiExtractResponse> {
  const body: Record<string, unknown> = {
    pages: urls.map((url) => ({ url })),
  };

  if (timeout !== undefined) {
    body.timeout = timeout;
  }

  return kagiPost<KagiExtractResponse>("/extract", apiKey, body, signal);
}

function resultArray(value: unknown): KagiSearchResult[] {
  return Array.isArray(value) ? value as KagiSearchResult[] : [];
}

function collectSearchResults(response: KagiSearchResponse, limit: number): DisplaySearchResult[] {
  const data = response.data ?? {};
  const results: DisplaySearchResult[] = [];

  const sectionNames = [
    ...SEARCH_RESULT_SECTIONS,
    ...Object.keys(data).filter((section) =>
      !SEARCH_RESULT_SECTIONS.includes(section) &&
      !RELATED_SEARCH_SECTIONS.includes(section)
    ),
  ];

  for (const section of sectionNames) {
    if (results.length >= limit) break;

    for (const result of resultArray(data[section])) {
      if (results.length >= limit) break;
      if (!result || (!result.title && !result.url && !result.snippet)) continue;
      results.push({ ...result, category: section });
    }
  }

  return results;
}

function collectRelatedSearches(response: KagiSearchResponse): string[] {
  const data = response.data ?? {};
  const related: string[] = [];

  for (const section of RELATED_SEARCH_SECTIONS) {
    for (const result of resultArray(data[section])) {
      const question = unknownToString(result.props?.question);
      const title = unknownToString(result.title);
      const snippet = unknownToString(result.snippet);
      const value = question ?? title ?? snippet;
      if (value) related.push(value);
    }
  }

  return [...new Set(related)];
}

function formatCategory(category: string): string {
  return category.replace(/_/g, " ");
}

function formatSearchResults(response: KagiSearchResponse, limit: number): string {
  const results = collectSearchResults(response, limit);
  const relatedSearches = collectRelatedSearches(response);
  let output = "";

  if (results.length > 0) {
    output += "## Search Results\n\n";
    for (let i = 0; i < results.length; i++) {
      const result = results[i];
      const title = result.title?.trim() || result.url?.trim() || "Untitled result";
      output += `### ${i + 1}. ${title}\n`;
      if (result.url) output += `**URL:** ${result.url}\n`;
      if (result.category !== "search") output += `**Type:** ${formatCategory(result.category)}\n`;
      if (result.time) output += `**Date:** ${result.time}\n`;
      if (result.image?.url) output += `**Image:** ${result.image.url}\n`;
      if (result.snippet) output += `${result.snippet.trim()}\n`;
      output += "\n";
    }
  } else {
    output += "No search results found.\n";
  }

  if (relatedSearches.length > 0) {
    output += "## Related Searches\n\n";
    output += relatedSearches.map((search) => `- ${search}`).join("\n");
    output += "\n";
  }

  return output.trim();
}

function normalizeExtractUrls(urls: string[]): string[] {
  const normalized: string[] = [];
  const seen = new Set<string>();

  for (const rawUrl of urls) {
    const trimmed = rawUrl.trim();
    if (!trimmed) continue;

    let parsed: URL;
    try {
      parsed = new URL(trimmed);
    } catch {
      throw new Error(`Invalid URL: ${trimmed}`);
    }

    if (parsed.protocol !== "https:") {
      throw new Error(`Kagi Extract API requires HTTPS URLs: ${trimmed}`);
    }

    const url = parsed.toString();
    if (!seen.has(url)) {
      normalized.push(url);
      seen.add(url);
    }
  }

  if (normalized.length === 0) {
    throw new Error("At least one HTTPS URL is required");
  }

  if (normalized.length > 10) {
    throw new Error("Kagi Extract API supports at most 10 URLs per request");
  }

  return normalized;
}

function formatExtractResults(response: KagiExtractResponse): string {
  const pages = response.data ?? [];
  const errors = response.errors ?? [];
  let output = "";

  if (pages.length > 0) {
    output += "## Extracted Pages\n\n";
    for (let i = 0; i < pages.length; i++) {
      const page = pages[i];
      output += `### ${i + 1}. ${page.url}\n\n`;
      if (page.markdown?.trim()) {
        output += `${page.markdown.trim()}\n\n`;
      } else {
        output += "_No markdown content returned._\n\n";
      }
    }
  }

  if (errors.length > 0) {
    output += "## Extraction Errors\n\n";
    for (const error of errors) {
      const location = error.location ? ` (${error.location})` : "";
      const message = error.message ? `: ${error.message}` : "";
      output += `- ${error.code}${location}${message}\n`;
    }
  }

  return output.trim() || "No extracted content returned.";
}

function previewText(text: string, maxLength = 300): string {
  return text.length > maxLength ? `${text.slice(0, maxLength)}...` : text;
}

function pluralize(count: number, singular: string, plural = `${singular}s`): string {
  return `${count} ${count === 1 ? singular : plural}`;
}

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "kagi_search",
    label: "Kagi Search",
    description: "Search the web using the official Kagi Search API",
    promptSnippet: "kagi_search: Search the web using the official Kagi Search API.",
    promptGuidelines: [
      "Use kagi_search when current web search results would help answer the user's request.",
      "kagi_search returns search result metadata and snippets; use kagi_extract for full page markdown when needed.",
    ],
    parameters: Type.Object({
      query: Type.String({ description: "Search query" }),
      limit: Type.Optional(Type.Number({
        description: "Maximum number of results to return (1-50); default: 10",
        minimum: 1,
        maximum: 50,
      })),
    }),

    async execute(_toolCallId, params, signal, onUpdate, _ctx) {
      if (!params.query?.trim()) {
        throw new Error("Query cannot be empty");
      }

      const apiKey = getApiKey();
      if (!apiKey) {
        throw new Error("No Kagi API key configured. Set KAGI_API_KEY or use /kagi-api-login.");
      }

      const limit = clampInteger(params.limit, 10, 1, 50);

      onUpdate?.({
        content: [{ type: "text", text: `Searching Kagi for \"${params.query}\"...` }],
        details: {},
      });

      try {
        const response = await kagiSearch(params.query, apiKey, limit, signal);
        const results = collectSearchResults(response, limit);
        const relatedSearches = collectRelatedSearches(response);
        const output = formatSearchResults(response, limit);

        return {
          content: [{ type: "text", text: output }],
          details: {
            query: params.query,
            resultCount: results.length,
            relatedCount: relatedSearches.length,
            trace: response.meta?.trace,
            ms: response.meta?.ms,
          },
        };
      } catch (err) {
        const isAbort = err instanceof Error && err.name === "AbortError";
        if (isAbort) {
          return {
            content: [{ type: "text", text: "Search cancelled." }],
            details: { cancelled: true },
          };
        }

        const message = err instanceof Error ? err.message : String(err);
        throw new Error(message);
      }
    },

    renderCall(args, theme) {
      const query = String(args.query ?? "");
      const display = query.length > 50 ? `${query.slice(0, 47)}...` : query;
      return new Text(
        theme.fg("toolTitle", theme.bold("kagi_search ")) +
        theme.fg("accent", `\"${display}\"`),
        0, 0
      );
    },

    renderResult(result, { expanded, isPartial }, theme, context) {
      const details = result.details as {
        resultCount?: number;
        relatedCount?: number;
        trace?: string;
        ms?: number;
        error?: string;
        cancelled?: boolean;
      };

      if (isPartial) {
        return new Text(theme.fg("accent", "Searching..."), 0, 0);
      }

      if (details?.cancelled) {
        return new Text(theme.fg("muted", "Cancelled"), 0, 0);
      }

      if (details?.error || context.isError) {
        const errorText = details?.error || result.content.find(c => c.type === "text")?.text || "Unknown error";
        return new Text(theme.fg("error", `Error: ${errorText}`), 0, 0);
      }

      let statusLine = theme.fg("success", pluralize(details?.resultCount ?? 0, "result"));
      if ((details?.relatedCount ?? 0) > 0) {
        statusLine += theme.fg("muted", ` (${pluralize(details?.relatedCount ?? 0, "related search", "related searches")})`);
      }
      if (details?.ms) {
        statusLine += theme.fg("dim", ` in ${details.ms}ms`);
      }

      if (!expanded) {
        return new Text(statusLine, 0, 0);
      }

      const textContent = result.content.find(c => c.type === "text")?.text || "";
      return new Text(statusLine + "\n" + theme.fg("dim", previewText(textContent)), 0, 0);
    },
  });

  pi.registerTool({
    name: "kagi_extract",
    label: "Kagi Extract",
    description: "Extract page contents as markdown using the official Kagi Extract API",
    promptSnippet: "kagi_extract: Extract HTTPS page contents as markdown using the official Kagi Extract API.",
    promptGuidelines: [
      "Use kagi_extract when full page markdown is needed after search results or when the user asks to fetch page contents.",
      "kagi_extract requires HTTPS URLs and may incur additional Kagi API cost; do not call it unless page content is actually needed.",
    ],
    parameters: Type.Object({
      urls: Type.Array(Type.String({ description: "HTTPS URL to extract" }), {
        description: "HTTPS URLs to extract; Kagi supports 1-10 URLs per request",
        minItems: 1,
        maxItems: 10,
      }),
      timeout: Type.Optional(Type.Number({
        description: "Optional extraction timeout in seconds (0.5-10)",
        minimum: 0.5,
        maximum: 10,
      })),
    }),

    async execute(_toolCallId, params, signal, onUpdate, _ctx) {
      const apiKey = getApiKey();
      if (!apiKey) {
        throw new Error("No Kagi API key configured. Set KAGI_API_KEY or use /kagi-api-login.");
      }

      const urls = normalizeExtractUrls(params.urls ?? []);
      const timeout = clampNumber(params.timeout, 0.5, 10);

      onUpdate?.({
        content: [{ type: "text", text: `Extracting ${pluralize(urls.length, "page")} with Kagi...` }],
        details: {},
      });

      try {
        const response = await kagiExtract(urls, apiKey, timeout, signal);
        const output = formatExtractResults(response);
        const errors = response.errors ?? [];
        const pages = response.data ?? [];

        return {
          content: [{ type: "text", text: output }],
          details: {
            urls,
            pageCount: pages.length,
            errorCount: errors.length,
            trace: response.meta?.trace,
            ms: response.meta?.ms,
          },
        };
      } catch (err) {
        const isAbort = err instanceof Error && err.name === "AbortError";
        if (isAbort) {
          return {
            content: [{ type: "text", text: "Extraction cancelled." }],
            details: { cancelled: true },
          };
        }

        const message = err instanceof Error ? err.message : String(err);
        throw new Error(message);
      }
    },

    renderCall(args, theme) {
      const urls = Array.isArray(args.urls) ? args.urls : [];
      const firstUrl = String(urls[0] ?? "");
      const display = firstUrl.length > 50 ? `${firstUrl.slice(0, 47)}...` : firstUrl;
      const suffix = urls.length > 1 ? theme.fg("muted", ` +${urls.length - 1}`) : "";
      return new Text(
        theme.fg("toolTitle", theme.bold("kagi_extract ")) +
        theme.fg("accent", display) + suffix,
        0, 0
      );
    },

    renderResult(result, { expanded, isPartial }, theme, context) {
      const details = result.details as {
        pageCount?: number;
        errorCount?: number;
        trace?: string;
        ms?: number;
        error?: string;
        cancelled?: boolean;
      };

      if (isPartial) {
        return new Text(theme.fg("accent", "Extracting..."), 0, 0);
      }

      if (details?.cancelled) {
        return new Text(theme.fg("muted", "Cancelled"), 0, 0);
      }

      if (details?.error || context.isError) {
        const errorText = details?.error || result.content.find(c => c.type === "text")?.text || "Unknown error";
        return new Text(theme.fg("error", `Error: ${errorText}`), 0, 0);
      }

      let statusLine = theme.fg("success", pluralize(details?.pageCount ?? 0, "page"));
      if ((details?.errorCount ?? 0) > 0) {
        statusLine += theme.fg("warning", `, ${pluralize(details?.errorCount ?? 0, "error")}`);
      }
      if (details?.ms) {
        statusLine += theme.fg("dim", ` in ${details.ms}ms`);
      }

      if (!expanded) {
        return new Text(statusLine, 0, 0);
      }

      const textContent = result.content.find(c => c.type === "text")?.text || "";
      return new Text(statusLine + "\n" + theme.fg("dim", previewText(textContent)), 0, 0);
    },
  });

  pi.registerCommand("kagi-api-login", {
    description: "Set Kagi API key for official Kagi API tools",
    handler: async (_args, ctx) => {
      const currentApiKey = getApiKey();

      const apiKey = await ctx.ui.input(
        "Enter your Kagi API key:",
        currentApiKey ? "Current API key set (enter new key to change)" : "Get a key from https://kagi.com/api/keys"
      );

      if (!apiKey) {
        ctx.ui.notify("Kagi API login cancelled", "warning");
        return;
      }

      try {
        setApiKey(apiKey);
        ctx.ui.notify(`Kagi API key saved to ${CONFIG_FILE}`, "info");
      } catch (err) {
        const message = err instanceof Error ? err.message : String(err);
        ctx.ui.notify(`Failed to save Kagi API key: ${message}`, "error");
      }
    },
  });
}
