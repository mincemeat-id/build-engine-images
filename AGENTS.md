# AGENTS.md

Guidance for AI coding agents working in this repository.

## Project At A Glance

`build-engine-images` produces the curated Docker images consumed by the
Mincemeat standalone build engine. Each image:

- Is published to `ghcr.io/mincemeat-id/build-engine-images/*` as a public
  package.
- Ships a shared `/build-entrypoint.sh`.
- Is pinned by `sha256:` digest in [`manifest.json`](./manifest.json).
- Has a CycloneDX SBOM, SLSA provenance, and a cosign keyless signature.

Read [docs/design.md](./docs/design.md) before making non-trivial changes.

## Repository Layout

```text
build-engine-images/
├── node/                 # node:20, node:22 Dockerfiles
├── bun/                  # bun:1 Dockerfile
├── hugo/                 # hugo:latest Dockerfile
├── zola/                 # zola:latest Dockerfile
├── entrypoint/           # shared /build-entrypoint.sh
├── manifest.json         # digest-pinned image manifest (contract with build-engine)
├── schemas/              # JSON schemas (manifest.schema.json)
├── scripts/              # CI helpers (manifest generation, CVE budget)
├── tests/
│   ├── fixtures/         # positive and negative framework fixtures
│   └── smoke/            # cold/warm smoke runners + shell tests
├── docs/                 # design, GHCR naming, rollback, security exceptions
├── security-exceptions.json
└── .github/workflows/    # build/publish/scan/smoke/manifest workflows
```

## Hard Rules

- **No secrets.** Never add tokens, npmrc credentials, SSH keys, cloud account
  IDs, or real customer data anywhere — Dockerfiles, layers, labels, fixtures,
  scripts, or workflows. See [SECURITY.md](./SECURITY.md).
- **Pin base images by digest.** Any change to a base image must include the
  `sha256:` digest in the Dockerfile.
- **Do not mutate released image tags.** Rollback happens by reverting the
  manifest bump in `build-engine` (see [docs/rollback.md](./docs/rollback.md)),
  never by re-pushing a published tag.
- **`manifest.json` versions are immutable** once released. Every image entry
  must include `tag` and `digest`. Validate against
  [schemas/manifest.schema.json](./schemas/manifest.schema.json).
- **Public repo.** Assume every change is world-readable. Use `example.com`
  and other RFC reserved values in fixtures.

## Coding Conventions

- Shell: bash, `set -euo pipefail`, ShellCheck-clean. Config: [.shellcheckrc](./.shellcheckrc).
- Dockerfiles: Hadolint-clean. Config: [.hadolint.yaml](./.hadolint.yaml).
- Editor settings: [.editorconfig](./.editorconfig).
- Python (`scripts/`): standard library only where possible; keep scripts
  idempotent and CI-runnable.
- Prefer reusing existing images over adding new ones. A new framework should
  use `node:22` unless it requires extra native deps.

## Common Tasks

### Add or update a framework fixture

1. Add the fixture under `tests/fixtures/<name>/` with the minimum files
   needed to build deterministically.
2. Wire it into the smoke runners (`tests/smoke/run-cold.sh`,
   `tests/smoke/run-warm.sh`) and the design doc's framework matrix.
3. For negative fixtures, define the expected `BUILD_INCOMPATIBLE` code.
4. Run the smoke shell tests locally: `tests/smoke/run-tests.sh`.

### Add a new image

1. Justify the image in [docs/design.md](./docs/design.md) — most frameworks
   should reuse `node:22`. Add a new image only when native deps or size
   require it.
2. Add the Dockerfile under `<image>/<track>.Dockerfile` with a pinned base
   digest and OCI labels per [docs/ghcr-naming.md](./docs/ghcr-naming.md).
3. Add the image to `manifest.json` (digest will be filled in by CI).
4. Add build, Trivy, smoke, and size-report wiring in `.github/workflows/`.
5. Update [docs/design.md](./docs/design.md) image matrix and
   [README.md](./README.md).

### Modify the entrypoint contract

1. Update [entrypoint/build-entrypoint.sh](./entrypoint/build-entrypoint.sh).
2. Update the "Entrypoint Contract" section in
   [docs/design.md](./docs/design.md).
3. Add or update shell tests under `tests/smoke/test_*.sh`.
4. Run `tests/smoke/run-tests.sh`.

### Declare a CVE exception

Follow [docs/security-exceptions.md](./docs/security-exceptions.md). Add the
entry to [security-exceptions.json](./security-exceptions.json) with a
technical justification and an expiry (max 6 months).

## Verification

Before claiming a change is complete:

- `tests/smoke/run-tests.sh` passes for entrypoint changes.
- Affected smoke runs (`run-cold.sh`, `run-warm.sh`) succeed for fixture or
  image changes.
- `hadolint` is clean for Dockerfile changes.
- `shellcheck` is clean for shell changes.
- `scripts/generate_manifest.py` produces a manifest that validates against
  `schemas/manifest.schema.json`.
- No new occurrences of credentials, real customer data, or private hostnames.

## What Not To Do

- Don't introduce private registry dependencies.
- Don't add multi-arch builds without an explicit design update.
- Don't expand image scope ("nice to have" tools, language runtimes,
  framework-specific images) without justification in the design doc.
- Don't bypass CI gates (`--no-verify`, ignoring Trivy/Hadolint/ShellCheck
  errors) to land a change.
- Don't write to `/workspace/src`; the entrypoint only writes to
  `/workspace/out` and `/cache`.

## Where To Ask Questions

For ambiguous architectural decisions, surface them in your PR description
and reference the relevant section of [docs/design.md](./docs/design.md)
rather than guessing.
