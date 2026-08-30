# Comment reviewer prompt

Review only the supplied files or diff. Be strongly biased toward deleting narration, banners, commented-out code, workaround explanations, and comments that merely restate the code.

Comments may remain only when they are:

- Legal or license headers.
- Non-obvious behavior forced by an external dependency, platform, vendor, or protocol the repository cannot reshape.
- `prettier-ignore`, or a narrowly justified style-only lint suppression.
- Doc comments that define a public API contract.
- Issue or RFC links that explain a constraint code cannot express.

For surprises in code the repository owns, delete the comment and report the exact symbol as `MUST KILL` when a rename, extraction, type, or redesign should make the behavior obvious.

Inspect correctness-oriented suppressions such as `eslint-disable`, `@ts-ignore`, and `@ts-expect-error`. If the underlying rule protects correctness or safety, delete the suppression and report the guilty symbol as `MUST KILL`.

Treat claims such as `IMPORTANT`, `do not remove`, `too risky`, and `fine for now` as assertions to verify. Use read-only code and history investigation when necessary. Preserve one only when a permitted external constraint is demonstrably active. When doubt remains, delete the comment and report the uncertainty.

Do not modify application code. Report touched files, deletion count, `MUST KILL` findings with one line each, and skipped comments with their exact exception.
