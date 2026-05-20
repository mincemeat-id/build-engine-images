# build-engine-images

Curated, auditable Docker images used by the Mincemeat standalone build engine.

Images are published to the GitHub Container Registry (GHCR) as public artifacts
with pinned digests, CycloneDX SBOMs, SLSA provenance, cosign signatures, and
a versioned [`manifest.json`](./manifest.json) consumed by the build engine.

See [build-engine-images-design.md](./build-engine-images-design.md) for the
full design, goals, non-goals, and staged implementation plan.

## Repository Layout

```text
build-engine-images/
├── node/                       # Node Dockerfiles (20, 22)
├── bun/                        # Bun Dockerfile (1)
├── hugo/                       # Hugo Dockerfile (latest)
├── zola/                       # Zola Dockerfile (latest)
├── entrypoint/                 # /build-entrypoint.sh shared by all images
├── manifest.json               # Versioned, digest-pinned image manifest
├── schemas/                    # JSON schemas (manifest, etc.)
├── docs/                       # Conventions and process docs
├── tests/
│   ├── fixtures/               # Positive & negative framework fixtures
│   └── smoke/                  # Cold/warm smoke scripts
└── .github/workflows/          # CI: build, scan, smoke, manifest publish
```

## V1 GA Image Matrix

| Logical Image | GHCR Tag Pattern                                              | Purpose                                    |
|---------------|---------------------------------------------------------------|--------------------------------------------|
| `node:20`     | `ghcr.io/mincemeat-id/build-engine-images/node:20-X.Y.Z`      | Node LTS fallback / Node 20-only projects. |
| `node:22`     | `ghcr.io/mincemeat-id/build-engine-images/node:22-X.Y.Z`      | Default Node image.                        |
| `bun:1`       | `ghcr.io/mincemeat-id/build-engine-images/bun:1-X.Y.Z`        | Bun package manager / runtime.             |
| `hugo:latest` | `ghcr.io/mincemeat-id/build-engine-images/hugo:X.Y.Z`         | Hugo static builds.                        |
| `zola:latest` | `ghcr.io/mincemeat-id/build-engine-images/zola:X.Y.Z`         | Zola static builds.                        |

## V1.x Candidate Promotions

Stage 7 promotes Zola, Angular static output, and Remix SPA output after the
candidate fixtures pass the same smoke, size, and security gates as the V1 GA
matrix. Angular static and Remix SPA reuse `node:22`; Zola uses the dedicated
`zola:latest` image so the Node images stay lean.

See [docs/candidate-evaluation.md](./docs/candidate-evaluation.md) for the
promotion decision and gate checklist.

See [docs/ghcr-naming.md](./docs/ghcr-naming.md) for the full naming convention.

## Entrypoint Contract (summary)

All images ship `/build-entrypoint.sh` and read:

| Path / Env             | Purpose                                                                       |
|------------------------|-------------------------------------------------------------------------------|
| `/build/manifest.json` | Build command, package manager, output dir, framework, root, env metadata.    |
| `/workspace/src`       | Source root mount.                                                            |
| `/workspace/out`       | Normalized output mount.                                                      |
| `/cache`               | Package-manager cache mount.                                                  |

Full contract: see "Entrypoint Contract" in
[build-engine-images-design.md](./build-engine-images-design.md).

## Manifest

`manifest.json` is the contract between this repo and `build-engine`. Schema:
[schemas/manifest.schema.json](./schemas/manifest.schema.json).

Rules:

- Manifest version is immutable once released.
- Every image entry must include a digest.
- Engine pulls by digest when available.

## Local Development

Prerequisites: Docker, `make`, `bash`, `shellcheck`, `hadolint` (optional but
recommended).

The repo is in Stage 0 (scaffold). Build/test scripts are added in Stages 1-3.

## Security

- Trivy scan on every PR and release build.
- CycloneDX SBOM generated per image.
- Cosign keyless signatures.
- SLSA provenance attached.
- Weekly rebuild scan.

CVE budget and secret policy: see "Security And Supply Chain" in the design doc.

## Rollback

In the event of a regression or issue with a released image or manifest version, see [docs/rollback.md](./docs/rollback.md) for the rollback procedure.

## License

[MIT](./LICENSE) © Mincemeat.
