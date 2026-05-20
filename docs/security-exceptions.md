# Security Exception Documentation Process

This document defines the process for declaring, reviewing, and documenting CVE exceptions in the `build-engine-images` repository.

## CVE Budget Policy

As defined in the repository design, the publication gate enforces the following vulnerability budget:

| Severity | Policy |
|----------|--------|
| Critical with fix | Block publish. |
| More than 5 high with fixes | Block publish. |
| High without fix | Require maintainer acknowledgement in release notes. |
| Medium with fix | Warn (non-blocking). |

If a vulnerability violates this budget (e.g. a Critical CVE has a fix, but for technical reasons we cannot upgrade the package immediately, or the vulnerability is a false positive), it must be documented as an exception to bypass the block.

## How to Declare an Exception

Exceptions are configured in the `security-exceptions.json` file in the root of the repository.

### Exception Schema

The `security-exceptions.json` file contains a list of exceptions:

```json
{
  "exceptions": [
    {
      "cve": "CVE-2026-12345",
      "reason": "Vulnerability is in a build tool (e.g. git) not exposed to untrusted input at runtime, or no fix is currently available and it has been verified as not exploitable in this context.",
      "expiry": "2026-12-31"
    }
  ]
}
```

### Exception Fields

1. **`cve`** (string, required): The CVE identifier (e.g., `CVE-2023-4911`).
2. **`reason`** (string, required): Detailed technical justification explaining why the vulnerability is not exploitable in the build engine context, or why the risk is accepted.
3. **`expiry`** (string, required, format `YYYY-MM-DD`): Expiration date for the exception. Once this date has passed, the exception will be ignored and the vulnerability will once again block publication until a new exception or a fix is applied.

## Workflow

1. **Identify the Block:** If the Trivy scan job in the CI pipeline fails, inspect the job logs to identify the blocking CVE(s).
2. **Analysis:** Assess whether the CVE poses an active risk to the build engine sandbox environment.
3. **Propose Exception:** Add the CVE entry to `security-exceptions.json` with a clear, technical justification and an appropriate expiration date (maximum 6 months).
4. **Pull Request:** Open a PR. The PR description must reference the CVE and link to any relevant issue tracking the upstream fix.
5. **Review & Approval:** At least one platform maintainer must review and approve the PR.
6. **Release Note Acknowledgement:** If there are high vulnerabilities without fixes, acknowledge them in the release notes generated from `docs/release-notes-template.md`.
