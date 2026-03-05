---
description: Security-focused review of current changes
---
Do a security-focused review of my current uncommitted changes. Detect whether this is a jj or git repo first. Look specifically for:
- injection vulnerabilities (SQL, command, XSS)
- authentication/authorization gaps
- sensitive data exposure (secrets, tokens, PII in logs)
- insecure defaults or missing input validation
- race conditions and TOCTOU issues

Only report actual security concerns, not general code quality.

$@