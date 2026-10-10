import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

/** Overrides the llama-stack models file path. */
export const MODELS_ENV = "LLAMA_STACK_MODELS";
/** The llama-stack models file installed with the setup-llama-stack skill. */
export const DEFAULT_MODELS_FILE = join(homedir(), ".agents", "skills", "setup-llama-stack", "models.json");

export type Roles = Readonly<Record<string, readonly string[]>>;

interface ModelsFile {
  roles: Record<string, string>;
  hosts: Record<string, Record<string, string | string[]>>;
}

/**
 * Resolves every llama-stack role to its model list for one host. A role names a
 * tier; the host maps each tier to one model or a panel of models. A missing file
 * yields no roles; a malformed one throws so a bad edit is not silently ignored.
 */
export function loadRoles(host: string, file: string = process.env[MODELS_ENV] ?? DEFAULT_MODELS_FILE): Roles {
  if (!existsSync(file)) return Object.freeze({});
  const parsed = JSON.parse(readFileSync(file, "utf8")) as ModelsFile;
  const tiers = parsed.hosts?.[host];
  if (!parsed.roles || !tiers) throw new Error(`${file} needs "roles" and "hosts.${host}"`);

  const roles: Record<string, readonly string[]> = {};
  for (const [role, tier] of Object.entries(parsed.roles)) {
    const models = tiers[tier];
    if (models === undefined) throw new Error(`${file}: role "${role}" uses tier "${tier}", which hosts.${host} lacks`);
    const list = Array.isArray(models) ? models : [models];
    if (list.length === 0 || list.some((model) => typeof model !== "string" || !model)) {
      throw new Error(`${file}: hosts.${host}.${tier} must be a model or a non-empty list of models`);
    }
    roles[role] = Object.freeze([...list]);
  }
  return Object.freeze(roles);
}
