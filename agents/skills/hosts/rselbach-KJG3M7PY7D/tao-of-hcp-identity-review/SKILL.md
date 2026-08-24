---
name: tao-of-hcp-identity-review
description: Review code or pull requests according to "The Tao of HCP Identity" on this host. Use only when the user explicitly asks for a Tao review, a review according to the Tao of the team, or names "The Tao of HCP Identity". Do not invoke for ordinary review requests.
compatibility: Requires access to HashiCorp Confluence through the Atlassian MCP server. Pull request reviews also require gh.
---

# Tao of HCP Identity review

## Activation

Use this skill only when the user explicitly requests a review according to the
team Tao or names "The Tao of HCP Identity." Do not infer this request from an
ordinary code review, a risky change, implementation work, or a test failure.

This is a review workflow. Do not edit code, switch branches, submit comments,
approve a pull request, or resolve review threads unless the user asks.

## Refresh the Tao

The Tao is a living document. Read the current Confluence page before every
review:

- Title: `The Tao of HCP Identity`
- Page ID: `5224857713`
- ARI: `ari:cloud:confluence:6b5964a0-ccc8-4c3b-b0d6-5c5284cacadf:page/5224857713`
- URL: <https://hashicorp.atlassian.net/wiki/spaces/CLOUD/pages/5224857713/The+Tao+of+HCP+Identity>

Use the Atlassian MCP server:

1. Call `getAccessibleAtlassianResources` to get the current cloud ID.
2. Call `fetch` with the page ARI and read the complete page.
3. If the ARI no longer resolves, use `searchConfluenceUsingCql` with:

   ```text
   type = page AND title = "The Tao of HCP Identity"
   ```

4. Treat the fetched page as authoritative when it differs from this skill.
5. Record the page version in the review report when Confluence provides it.

If the page cannot be read, report the exact failure. Ask whether to continue
with the checklist in this skill. Do not silently claim that a stale review
follows the Tao.

## Review principle

Optimize for software that is understandable, maintainable, and correct.
Question a process or convention when it no longer supports those goals rather
than enforcing it blindly.

Act as a co-author. Be direct about defects and design problems, but help the
author improve the change. Do not manufacture balance, praise, or criticism.

## Establish the review target

Read the repository instructions before reviewing. Identify the VCS before
running version-control commands and do not mix Git and JJ.

Freeze the scope:

- For a pull request, use `gh`, fetch current remote state, and record the exact
  base and head revisions. Read the title, description, template, linked ticket
  or RFC, checks, discussion, changed-file list, and complete diff. Do not check
  out the pull request without permission.
- For local changes, inspect status, the complete working-copy diff, and
  untracked files that belong to the requested change.
- For a branch, commit, patch, file, or directory, use the scope named by the
  user. Ask when the base or target is ambiguous.

Read surrounding code and tests, not only diff hunks. Understand the goal, why
the implementation chose this approach, and what behavior must remain intact.
Trace important callers, boundaries, contracts, and related work when they bear
on the change.

## Apply the Tao

### Readability

Ask whether another engineer can understand the change without reconstructing
hidden assumptions.

- Names, control flow, types, comments, and tests should make intent clear.
- The implementation should explain its important design choices or make them
  evident from the code.
- Complexity and indirection should earn their place.

### Correctness

Check whether the code does what the ticket, RFC, API contract, and pull request
claim.

- Follow success and failure paths through their callers and dependencies.
- Check authorization and business rules at the boundary that owns them.
- Verify error handling, cleanup, state transitions, and compatibility.
- Distinguish a proven defect from a question that needs author context.

### Maintainability and design

Ask whether the team will want to maintain this implementation later.

- Prefer direct code and cohesive ownership over scattered special cases.
- Check whether the change fits the surrounding architecture and relevant RFC.
- Look for coupling to work another team member may be changing.
- Flag duplication, unclear boundaries, misleading abstractions, and changes
  that make safe modification harder.

### Meaningful edge cases

Consider the cases relevant to the changed behavior, including:

- missing, empty, malformed, minimum, and maximum input;
- duplicates and resources that do not exist;
- permission failures and unauthorized requests;
- dependency failures, timeouts, and cancellation;
- partial completion and unexpected ordering;
- repeated requests, with the intended idempotency made explicit;
- concurrent operations;
- business-rule boundaries.

Do not turn this into a rote list. Trace a reachable failure and its impact
before reporting a defect.

### Tests

Every meaningful change should have useful evidence that it works. Review the
tests for the following properties:

- They test behavior rather than internal call sequences.
- They cover meaningful failure and boundary cases, not only success.
- They make refactoring safer.
- Each test is focused and readable.
- Table-driven tests use maps when the language and repository conventions
  support them.
- A production bug has a regression test when automation could have caught it.

Reviews focus on correctness, maintainability, and design. The author owns the
test plan and should already have run it. Inspect the evidence and tests; do not
merely repeat the author's test plan. Run a focused check or reproduction when
needed to validate one of your own findings.

### Pull request readiness

For pull requests, also check that:

- the title is useful and includes the ticket number;
- the description explains the goal and important design choices;
- the author provides enough evidence to believe the change is correct, with a
  PRDE run as the minimum expected integration evidence;
- important tested edge cases are documented;
- unit tests preserve the important cases;
- the pull request is atomic and reviewable in one sitting.

Treat missing evidence as missing evidence, not proof that the implementation is
wrong. If the change is still exploratory, recommend a draft review rather than
forcing premature certainty.

## Validate every finding

The reviewer owns AI-assisted findings. Before reporting one:

1. Identify the exact changed location or directly affected code.
2. Trace the input or event to the bad outcome.
3. State the violated behavior, contract, design rule, or maintenance cost.
4. Check nearby guards, callers, tests, and authoritative documentation for
   evidence that disproves it.
5. Reproduce the issue or run a focused check when practical.

Do not offload validation to the author. Label an unresolved uncertainty as a
question rather than presenting it as fact.

## Report

Put actionable findings first, ordered by impact. Use the narrowest useful file
and line reference. For each finding, state:

- what is wrong;
- the reachable case or concrete design cost;
- why it conflicts with the Tao;
- the evidence;
- a practical direction for improvement when one is clear.

Separate blocking findings, non-blocking findings, and questions. Do not bury
important feedback under cosmetic nits. If nothing survives validation, say
`No findings.`

End with a compact review record:

```markdown
## Review record
- Tao source: Confluence page version and URL
- Scope: exact pull request revisions or local change set
- Examined: changed files and important related code
- Verification: commands or reproductions and their results
- Gaps: inaccessible or unverified context and the reason
```

When reviewing an updated pull request, revisit unresolved comments. The
reviewer, not the author, should resolve a thread after confirming the rewrite.
