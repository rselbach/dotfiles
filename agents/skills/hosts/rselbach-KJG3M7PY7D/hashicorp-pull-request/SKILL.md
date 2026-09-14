---
name: hashicorp-pull-request
description: Create or update pull requests for repositories that use the HashiCorp ticket title and PR template.
compatibility: Requires the gh CLI and a GitHub repository.
---

# HashiCorp pull requests

Check the repository instructions and PR template before applying this format.
Personal repositories on this host do not inherit HashiCorp requirements.

## Required format

Read [the PR body template](references/pull-request-template.md) before drafting
or changing a pull request.

Every PR title must have this exact shape:

```text
[TICKET-ID] short description
```

For example:

```text
[HCPIDN-1234] Fix stale session cleanup
```

Use the real, uppercase Jira issue ID inside square brackets. Keep the
description concise and omit a trailing period. Do not add a conventional
commit prefix. Never invent a ticket ID. Find it in the user's request, branch
name, commit messages, or Jira context. Ask the user if it cannot be determined.

## Draft the body

Copy the template without changing its headings, links, comments, section
order, or checklist wording. Fill it as follows:

1. Replace the CHANGELOG instructions with one customer-impact line.
   - For no customer or client impact, use exactly `CHANGELOG: no-impact`.
   - Otherwise start the line with exactly one of `Added`, `Changed`,
     `Deprecated`, `Removed`, `Fixed`, or `Security`, followed by a colon and a
     one-line description of the customer-visible effect.
2. Replace `--> ADD-JIRA-ISSUE-ID-AND-LINK` with a Markdown link to the ticket,
   such as `[HCPIDN-1234](https://hashicorp.atlassian.net/browse/HCPIDN-1234)`.
3. Replace the Description placeholder with a short explanation of why the
   change is needed. Include enough implementation context for a reviewer.
4. Replace the External Links placeholder with useful review links. Write
   `None.` when there are none.
5. Under Testing, state how the change was tested and include exact commands or
   manual checks when available.
6. Check a box only when the statement is true. Do not claim tests, migration
   checks, feature-flag checks, rollback review, or PCI review that did not
   happen. Keep both alternatives in the Migrations and Feature Flag sections,
   and select only the applicable path.

Base every claim on the current diff, test results, ticket, and user-provided
context. If required information is missing, leave the relevant box unchecked
or ask the user. Do not use vague filler.

## Create or update the PR

Before drafting, inspect the complete branch diff against the intended base and
check whether a PR already exists. Use `main` as the base unless the repository
or user specifies another branch.

Write the completed body to a temporary Markdown file. A body file avoids shell
quoting errors and preserves the template:

```bash
body_file="$(mktemp)"
# Write the completed template to "${body_file}".
gh pr create \
  --base main \
  --title '[HCPIDN-1234] Fix stale session cleanup' \
  --body-file "${body_file}"
rm -f "${body_file}"
```

Use `gh pr edit --title ... --body-file ...` when a PR already exists. After
creating or editing it, verify the result:

```bash
gh pr view --json url,title,body
```

Report the PR URL and any unchecked items that still need the author's
attention.
