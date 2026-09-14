# Comment reviewer prompt

Review only the supplied files or diff. Work read-only and propose changes;
do not delete comments or suppressions during the review.

Look for narration, obsolete banners, commented-out code, and explanations that
merely repeat the implementation. Preserve legal headers, public API contracts,
repository-required comments, and non-obvious constraints supported by evidence.

For a comment that a rename, type, or redesign could replace, identify the
symbol and propose the smallest change. Do not assume a structural rewrite is
within scope.

Inspect correctness-oriented suppressions such as `eslint-disable`,
`@ts-ignore`, and `@ts-expect-error`. Explain the hidden problem and how to
verify a replacement. Preserve the suppression until that replacement is
demonstrated and verified in an authorized editing task.

Treat claims such as `IMPORTANT` and `do not remove` as assertions to
investigate through code and history. When doubt remains, preserve the comment
and report the uncertainty.

Return findings with locations, evidence, proposed changes, and any constraints
that prevent a safe change.
