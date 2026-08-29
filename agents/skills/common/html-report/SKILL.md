---
name: html-report
description: "Create substantive reviews, audits, assessments, investigations, findings, status reports, and similar deliverables as polished self-contained HTML. Use whenever the user asks to review something, generate or write a report, audit a system, summarize findings, assess quality or risk, or produce a document-like analysis. Save the HTML in a fresh temporary directory and open it in a browser before handoff. Skip for brief inline answers or when the user explicitly requests another format."
---

# HTML report

Turn the result of a review or report into a self-contained HTML document. Use
the bundled renderer for routine work. Do not redesign the page each time.

## Workflow

1. Complete the underlying investigation first. Gather exact evidence, source
   locations, commands, and limitations with the skills appropriate to the
   subject.
2. Create a fresh temporary directory:

   ```sh
   report_dir="$(mktemp -d "${TMPDIR:-/tmp}/codex-report.XXXXXX")"
   ```

3. Copy `assets/report-data.example.json` to `${report_dir}/report.json` and
   replace the example content. Keep the supplied shape and remove unused
   fields. Use plain strings; wrap short code identifiers in backticks.
4. Render the document:

   ```sh
   python3 scripts/render_report.py \
     "${report_dir}/report.json" \
     --output-dir "${report_dir}"
   ```

   Run the script from this skill directory, or use absolute paths for both
   scripts and assets. The renderer prints the final HTML path.
5. Start the bundled loopback server as a persistent process:

   ```sh
   python3 scripts/serve_report.py "${report_dir}/report.html"
   ```

6. Load the available browser-control skill, open the printed URL, and inspect
   the report at desktop and narrow viewport widths. Check the browser console,
   filters, anchor links, overflow, and print layout when relevant. Fix content
   or renderer defects before handoff. Mark the report page as the browser
   deliverable when the browser tool supports it.
7. End with a link to the HTML file and a short verification summary. Keep the
   server alive until the browser check and handoff are complete.

## Data shape

The example JSON is the source of truth. These fields cover routine reports:

- `eyebrow`, `title`, `subtitle`, and `verdict` define the opening.
- `metadata` records scope, revision, date, or comparison base.
- `metrics` gives three to five useful counts or facts. Do not invent metrics
  to fill the layout.
- `summary` contains the decision-ready headline and supporting paragraphs.
- `findings` contains ranked issues. Each finding supports `id`, `severity`,
  `title`, `summary`, `details`, `evidence`, `recommendation`, and `references`.
- `sections` contains positive observations, architecture notes, decisions, or
  any other grouped material as cards.
- `verification` records commands and observed results.
- `scope` lists what was and was not examined.
- `actions` is the ordered next-step list.

Valid severities are `critical`, `high`, `medium`, `low`, and `info`. Valid
verification statuses are `pass`, `fail`, and `not-run`.

## Editorial rules

- Lead with the verdict and highest-impact evidence. A reader should understand
  the result without scrolling.
- Separate observed facts from inference. State uncertainty and untested areas.
- Give every finding a concrete consequence and a practical recommendation.
- Use exact file and line references for code reviews. Use direct source links
  for researched reports.
- Prefer five strong findings to a padded list. Omit empty sections.
- Keep prose compact. The page already provides hierarchy; do not repeat the
  same conclusion in every section.

## Template rules

- Keep the output self-contained: no CDN, remote font, image, stylesheet, or
  script dependencies.
- Reuse `assets/report-template.html` and its existing CSS variables, layout,
  filter controls, responsive behavior, and print styles.
- Do not edit the template for an ordinary report. Change it only when the user
  explicitly requests a different visual system or the report exposes a real
  reusable gap.
- Put reusable improvements back into this skill rather than patching generated
  HTML repeatedly.
- Honor an explicitly requested output format instead of forcing HTML.
