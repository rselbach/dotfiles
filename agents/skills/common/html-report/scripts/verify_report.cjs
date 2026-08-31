#!/usr/bin/env node
// Verify a generated report in a real browser at desktop and narrow widths.

const { execFileSync } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");

function loadPlaywright() {
  try {
    return require("playwright");
  } catch (error) {
    try {
      const root = execFileSync("mise", ["where", "npm:playwright"], {
        encoding: "utf8",
      }).trim();
      return require(path.join(root, "node_modules", "playwright"));
    } catch {
      throw new Error(
        "Playwright is unavailable. Install it in the project or through mise.",
        { cause: error },
      );
    }
  }
}

function parseArgs(argv) {
  const args = [...argv];
  const url = args.shift();
  const outputDir = args.shift();
  let browserPath = process.env.PLAYWRIGHT_BROWSER_PATH;

  while (args.length > 0) {
    const option = args.shift();
    if (option !== "--browser" || args.length === 0) {
      throw new Error(
        "usage: verify_report.cjs <url> <output-dir> [--browser <path>]",
      );
    }
    browserPath = args.shift();
  }

  if (!url || !outputDir) {
    throw new Error(
      "usage: verify_report.cjs <url> <output-dir> [--browser <path>]",
    );
  }

  return { url, outputDir, browserPath };
}

async function inspectViewport(browser, url, outputDir, viewport) {
  const context = await browser.newContext({ viewport: viewport.size });
  const page = await context.newPage();
  const errors = [];

  page.on("console", (message) => {
    if (
      message.type() === "error" &&
      !message.text().startsWith("Failed to load resource:")
    ) {
      errors.push(`console: ${message.text()}`);
    }
  });
  page.on("pageerror", (error) => errors.push(`page: ${error.message}`));
  page.on("response", (response) => {
    if (!response.ok() && !response.url().endsWith("/favicon.ico")) {
      errors.push(`resource: ${response.status()} ${response.url()}`);
    }
  });
  page.on("requestfailed", (request) => {
    errors.push(`request: ${request.failure()?.errorText} ${request.url()}`);
  });

  const response = await page.goto(url, { waitUntil: "networkidle" });
  if (response && !response.ok()) {
    errors.push(`request: ${response.status()} ${response.statusText()}`);
  }

  const anchors = await page.locator('a[href^="#"]').evaluateAll((links) =>
    links
      .map((link) => link.getAttribute("href"))
      .filter((href) => href && !document.querySelector(href)),
  );
  if (anchors.length > 0) errors.push(`missing anchors: ${anchors.join(", ")}`);

  const findings = page.locator(".finding");
  const filters = page.locator("[data-filter]");
  if ((await findings.count()) > 0) {
    for (let index = 0; index < (await filters.count()); index += 1) {
      const filter = filters.nth(index);
      const severity = await filter.getAttribute("data-filter");
      await filter.click();
      if ((await filter.getAttribute("aria-pressed")) !== "true") {
        errors.push(`filter did not activate: ${severity}`);
      }
      const mismatch = await findings.evaluateAll(
        (items, selected) =>
          items.some(
            (finding) =>
              finding.hidden !==
              (selected !== "all" && finding.dataset.severity !== selected),
          ),
        severity,
      );
      if (mismatch) errors.push(`filter showed the wrong findings: ${severity}`);
    }
    await page.locator('[data-filter="all"]').click();
  }

  const overflow = await page.evaluate(
    () => document.documentElement.scrollWidth > window.innerWidth + 1,
  );
  if (overflow) errors.push("screen layout has horizontal overflow");

  await page.screenshot({
    path: path.join(outputDir, `${viewport.name}.png`),
    fullPage: true,
  });

  await page.emulateMedia({ media: "print" });
  const printOverflow = await page.evaluate(
    () => document.documentElement.scrollWidth > window.innerWidth + 1,
  );
  if (printOverflow) errors.push("print layout has horizontal overflow");

  await context.close();
  return { viewport: viewport.name, errors };
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const { chromium } = loadPlaywright();
  fs.mkdirSync(args.outputDir, { recursive: true });

  const launchOptions = { headless: true };
  if (args.browserPath) launchOptions.executablePath = args.browserPath;
  const browser = await chromium.launch(launchOptions);

  try {
    const results = [];
    for (const viewport of [
      { name: "report-desktop", size: { width: 1440, height: 900 } },
      { name: "report-narrow", size: { width: 390, height: 844 } },
    ]) {
      results.push(
        await inspectViewport(browser, args.url, args.outputDir, viewport),
      );
    }

    console.log(JSON.stringify(results, null, 2));
    if (results.some((result) => result.errors.length > 0)) process.exitCode = 1;
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
