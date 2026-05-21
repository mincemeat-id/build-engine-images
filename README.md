# build-engine-images

Curated, auditable Docker images used by the Mincemeat standalone build engine.

Images are published to the GitHub Container Registry (GHCR) as public artifacts
with pinned digests, CycloneDX SBOMs, SLSA provenance, cosign signatures, and a
versioned [`manifest.json`](./manifest.json) consumed by the build engine.

## Image Matrix

| Logical Image | GHCR Tag Pattern                                              | Purpose                                    |
|---------------|---------------------------------------------------------------|--------------------------------------------|
| `node:20`     | `ghcr.io/mincemeat-id/build-engine-images/node:20-X.Y.Z`      | Node LTS fallback / Node 20-only projects. |
| `node:22`     | `ghcr.io/mincemeat-id/build-engine-images/node:22-X.Y.Z`      | Default Node image.                        |
| `bun:1`       | `ghcr.io/mincemeat-id/build-engine-images/bun:1-X.Y.Z`        | Bun package manager / runtime.             |
| `hugo:latest` | `ghcr.io/mincemeat-id/build-engine-images/hugo:X.Y.Z`         | Hugo static builds.                        |
| `zola:latest` | `ghcr.io/mincemeat-id/build-engine-images/zola:X.Y.Z`         | Zola static builds.                        |

Pull by digest from [`manifest.json`](./manifest.json) — never by floating tag.

## Manifest

`manifest.json` is the contract between this repo and `build-engine`:

- Manifest version is immutable once released.
- Every image entry includes a `sha256:` digest.
- Engine pulls by digest.

Schema: [schemas/manifest.schema.json](./schemas/manifest.schema.json).

## Security

- Trivy scan on every PR and release build.
- CycloneDX SBOM generated per image.
- Cosign keyless signatures.
- SLSA provenance attached.
- Weekly rebuild scan.

CVE budget and secret policy: see [docs/design.md](./docs/design.md) and
[SECURITY.md](./SECURITY.md).

Report vulnerabilities privately via [SECURITY.md](./SECURITY.md).

## Documentation

- [docs/design.md](./docs/design.md) — full design, goals, contracts.
- [docs/verification.md](./docs/verification.md) — cosign + SLSA verification recipes.
- [docs/ghcr-naming.md](./docs/ghcr-naming.md) — GHCR package and tag conventions.
- [docs/rollback.md](./docs/rollback.md) — rollback procedure.
- [docs/security-exceptions.md](./docs/security-exceptions.md) — CVE exception process.
- [docs/release-notes-template.md](./docs/release-notes-template.md) — release notes template.

## License

[MIT](./LICENSE) © Mincemeat.
