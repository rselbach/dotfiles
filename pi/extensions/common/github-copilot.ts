/**
 * Use OpenCode's GitHub OAuth flow for Pi's GitHub Copilot provider.
 *
 * The direct GitHub token works with api.githubcopilot.com and avoids Pi's
 * IDE-token exchange, which can fail when Copilot Chat is not enabled for the
 * emulated VS Code token.
 */

import { setTimeout as sleep } from "node:timers/promises";
import type { OAuthCredentials, OAuthLoginCallbacks } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const CLIENT_ID = "Ov23li8tweQw6odWQebz";
const DEVICE_CODE_URL = "https://github.com/login/device/code";
const ACCESS_TOKEN_URL = "https://github.com/login/oauth/access_token";
const COPILOT_API_URL = "https://api.githubcopilot.com";
const COPILOT_API_VERSION = "2026-06-01";
const USER_AGENT = "pi-github-copilot-extension";
const DEFAULT_POLL_INTERVAL_SECONDS = 5;
const DEFAULT_DEVICE_CODE_LIFETIME_SECONDS = 900;
const POLL_SAFETY_MARGIN_MS = 3_000;

interface DeviceAuthorization {
	deviceCode: string;
	userCode: string;
	verificationUri: string;
	intervalSeconds: number;
	expiresInSeconds: number;
}

interface DeviceTokenError {
	code: string;
	description?: string;
	intervalSeconds?: number;
}

function isRecord(value: unknown): value is Record<string, unknown> {
	return typeof value === "object" && value !== null;
}

function parseDeviceAuthorization(value: unknown): DeviceAuthorization {
	if (!isRecord(value)) throw new Error("Invalid GitHub device authorization response");

	const deviceCode = value.device_code;
	const userCode = value.user_code;
	const verificationUri = value.verification_uri;
	const intervalSeconds = value.interval ?? DEFAULT_POLL_INTERVAL_SECONDS;
	const expiresInSeconds = value.expires_in ?? DEFAULT_DEVICE_CODE_LIFETIME_SECONDS;
	if (
		typeof deviceCode !== "string" ||
		typeof userCode !== "string" ||
		typeof verificationUri !== "string" ||
		typeof intervalSeconds !== "number" ||
		!Number.isFinite(intervalSeconds) ||
		intervalSeconds <= 0 ||
		typeof expiresInSeconds !== "number" ||
		!Number.isFinite(expiresInSeconds) ||
		expiresInSeconds <= 0
	) {
		throw new Error("Invalid fields in GitHub device authorization response");
	}

	let verificationUrl: URL;
	try {
		verificationUrl = new URL(verificationUri);
	} catch {
		throw new Error("GitHub returned an invalid device verification URL");
	}
	if (verificationUrl.protocol !== "https:") {
		throw new Error("GitHub returned an untrusted device verification URL");
	}

	return {
		deviceCode,
		userCode,
		verificationUri: verificationUrl.href,
		intervalSeconds,
		expiresInSeconds,
	};
}

function accessTokenFrom(value: unknown): string | undefined {
	if (!isRecord(value)) return undefined;
	return typeof value.access_token === "string" ? value.access_token : undefined;
}

function tokenErrorFrom(value: unknown): DeviceTokenError | undefined {
	if (!isRecord(value) || typeof value.error !== "string") return undefined;
	return {
		code: value.error,
		description: typeof value.error_description === "string" ? value.error_description : undefined,
		intervalSeconds: typeof value.interval === "number" ? value.interval : undefined,
	};
}

async function postOAuthJson(
	url: string,
	body: Record<string, string>,
	signal: AbortSignal,
): Promise<unknown> {
	const response = await fetch(url, {
		method: "POST",
		headers: {
			Accept: "application/json",
			"Content-Type": "application/json",
			"User-Agent": USER_AGENT,
		},
		body: JSON.stringify(body),
		signal,
	});
	if (!response.ok) {
		throw new Error(
			`GitHub OAuth request failed: ${response.status} ${response.statusText}: ${await response.text()}`,
		);
	}
	return response.json();
}

async function pollForAccessToken(device: DeviceAuthorization, signal: AbortSignal): Promise<string> {
	let intervalSeconds = device.intervalSeconds;
	const expiresAt = Date.now() + device.expiresInSeconds * 1_000;

	while (Date.now() < expiresAt) {
		await sleep(intervalSeconds * 1_000 + POLL_SAFETY_MARGIN_MS, undefined, { signal });
		const value = await postOAuthJson(
			ACCESS_TOKEN_URL,
			{
				client_id: CLIENT_ID,
				device_code: device.deviceCode,
				grant_type: "urn:ietf:params:oauth:grant-type:device_code",
			},
			signal,
		);

		const accessToken = accessTokenFrom(value);
		if (accessToken) return accessToken;

		const error = tokenErrorFrom(value);
		if (!error) throw new Error("Invalid GitHub device token response");
		switch (error.code) {
			case "authorization_pending":
				continue;
			case "slow_down":
				intervalSeconds =
					error.intervalSeconds && error.intervalSeconds > 0
						? error.intervalSeconds
						: intervalSeconds + 5;
				continue;
			default: {
				const detail = error.description ? `: ${error.description}` : "";
				throw new Error(`GitHub device authorization failed: ${error.code}${detail}`);
			}
		}
	}

	throw new Error("GitHub device authorization expired");
}

async function login(callbacks: OAuthLoginCallbacks): Promise<OAuthCredentials> {
	const signal = callbacks.signal ?? new AbortController().signal;
	const value = await postOAuthJson(
		DEVICE_CODE_URL,
		{ client_id: CLIENT_ID, scope: "read:user" },
		signal,
	);
	const device = parseDeviceAuthorization(value);
	callbacks.onDeviceCode({
		userCode: device.userCode,
		verificationUri: device.verificationUri,
		intervalSeconds: device.intervalSeconds,
		expiresInSeconds: device.expiresInSeconds,
	});

	const accessToken = await pollForAccessToken(device, signal);
	return {
		access: accessToken,
		refresh: accessToken,
		expires: Number.MAX_SAFE_INTEGER,
	};
}

export default function githubCopilotExtension(pi: ExtensionAPI): void {
	pi.registerProvider("github-copilot", {
		baseUrl: COPILOT_API_URL,
		oauth: {
			name: "GitHub Copilot (direct)",
			isSubscription: true,
			login,
			async refreshToken(credentials, signal) {
				signal.throwIfAborted();
				return {
					...credentials,
					access: credentials.refresh,
					expires: Number.MAX_SAFE_INTEGER,
				};
			},
			getApiKey(credentials) {
				return credentials.refresh;
			},
		},
	});

	pi.on("before_provider_headers", (event, ctx) => {
		if (ctx.model?.provider !== "github-copilot") return;
		event.headers["User-Agent"] = USER_AGENT;
		event.headers["Editor-Version"] = null;
		event.headers["Editor-Plugin-Version"] = null;
		event.headers["Copilot-Integration-Id"] = null;
		event.headers["X-GitHub-Api-Version"] = COPILOT_API_VERSION;
	});
}
