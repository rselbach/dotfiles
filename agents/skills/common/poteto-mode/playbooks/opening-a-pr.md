### Opening a PR

Use this playbook only when the user requested a pull request or the current task already authorizes creating one.

**Repository state.** Refresh version-control status and diff first. Follow the repository's required VCS, branch, and worktree policy. Preserve unrelated and concurrent changes. Never use destructive reset, restore, clean, or ad hoc stashing to manufacture a clean branch. If existing work prevents a safe PR, stop and report the conflict.

**Commits.** Create commits only when authorized. Keep them small, ordered, and independently understandable. Do not rewrite published history or amend work you do not own.

**Review.** Use **no-comments** only for an explicit comment-review request, read-only unless editing is requested. Use **technical-writing** for the PR title, description, and any commit body, then apply **unslop**. Run **interrogate** when the change is substantial or contested.

**Titles.** Use the repository's title convention. When none exists, use Conventional Commits in the form `type(scope): subject`, with a short imperative subject and no trailing period.

**Descriptions.** Use these sections when they contain useful information:

- `## Why`. State the intent and why this approach fits.
- `## Scope`. State facts from the diff and the in/out boundary.
- `## Tradeoffs`. State real choices only.
- `## Blast Radius`. State who and what the change touches and why it is safe or risky.
- `## Verification`. State each check, how it was run, and its observed result.

Attach screenshots, recordings, or traces when they prove a claim. Do not use generic Summary or Test plan boilerplate.

**Size and stacks.** Prefer narrow PRs when each can stand alone. Use the repository's stacking tool only when it is already part of the workflow and the user has authorized the required branch operations.

**Readiness.** Choose draft or ready state from the user's request and repository convention. Verify the final state with the host's supported PR tool before reporting it.

**After opening.** Return the PR URL and continue only with work still authorized by the task. Opening a PR does not authorize babysitting, merging, deploying, or responding to reviewers.

A delegated worker that opens a PR follows the same authorization and review rules, returns the URL, and does not start a babysit loop.
