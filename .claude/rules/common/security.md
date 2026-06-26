# Security Rules

## Mandatory Checks

Before ANY commit or deployment:

1. **No hardcoded secrets** — API keys, passwords, tokens must use environment variables
2. **Input validation** — All user inputs validated before processing
3. **Path sanitization** — Prevent directory traversal attacks
4. **Error safety** — Error messages must not expose system internals

## Secret Management

- NEVER commit secrets in source code or config files
- ALWAYS use environment variables or `.env` files (excluded from git)
- Validate required secrets at startup
- Rotate exposed secrets immediately

## File System Security

- Stay within designated directories (`StudySystem/`)
- Sanitize filenames to prevent injection
- Use atomic writes for critical files
- Clean up temporary files after processing

## Data Privacy

- User data stays local (no external analytics)
- Sensitive data never sent to external services
- Audit logs must not contain sensitive information

## Incident Response

If security issue found:
1. STOP immediately
2. Document in `{SYSTEM_ROOT}/4-meta/security-incident.md`
3. Isolate affected files
4. Notify user with severity assessment
5. Rotate any exposed secrets

## Severity Levels

| Level | Response |
|-------|----------|
| CRITICAL | Immediate stop and remediation |
| HIGH | Fix within current session |
| MEDIUM | Fix before next commit |
| LOW | Note for future improvement |
