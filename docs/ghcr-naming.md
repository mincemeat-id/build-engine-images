# GHCR Package Naming Conventions

All images published from this repository live under the GHCR namespace:

```
ghcr.io/mincemeat-id/build-engine-images/<logical-name>
```

`<logical-name>` matches the logical image id used in
[`manifest.json`](../manifest.json) (the segment before `:` in keys like
`node:22`).

## Tag Format

```
<runtime-track>-<manifest-version>
```

- `runtime-track` identifies the user-facing runtime version line (e.g. `20`,
  `22`, `1` for Bun). Hugo omits this segment because we ship a single track.
- `manifest-version` is the semver of the `manifest.json` release that pinned
  this image (e.g. `1.0.0`).

| Logical Image | GHCR Tag Example                                                  |
|---------------|-------------------------------------------------------------------|
| `node:20`     | `ghcr.io/mincemeat-id/build-engine-images/node:20-1.0.0`          |
| `node:22`     | `ghcr.io/mincemeat-id/build-engine-images/node:22-1.0.0`          |
| `bun:1`       | `ghcr.io/mincemeat-id/build-engine-images/bun:1-1.0.0`            |
| `hugo:latest` | `ghcr.io/mincemeat-id/build-engine-images/hugo:1.0.0`             |

## Auxiliary Tags

| Tag                              | Purpose                                                                 | Mutable?                |
|----------------------------------|-------------------------------------------------------------------------|-------------------------|
| `<runtime>-<version>`            | Immutable release tag. Pinned by digest in `manifest.json`.             | No.                     |
| `<runtime>-<version>-rc.<n>`     | Release-candidate tag pushed on merge to `main`.                        | No (per RC iteration).  |
| `<runtime>-pr-<pr_number>`       | PR build artifact for review/smoke. Not signed, not in manifest.        | Yes (overwritten by PR).|
| `<runtime>-nightly-<yyyymmdd>`   | Weekly rebuild/rescan output. Used to detect base-image drift.          | Yes (overwritten daily).|

Stable, RC, and PR tags are mutually exclusive: a release version (e.g. `22-1.0.0`)
is never overwritten once published. Rollback is performed by reverting the
manifest bump in `build-engine`, never by mutating an existing tag.

## OCI Labels

Every published image MUST carry the following OCI annotations / labels:

| Label                                | Value                                                       |
|--------------------------------------|-------------------------------------------------------------|
| `org.opencontainers.image.source`    | `https://github.com/mincemeat-id/build-engine-images`       |
| `org.opencontainers.image.revision`  | Git SHA of the build.                                       |
| `org.opencontainers.image.version`   | Manifest version (e.g. `1.0.0`).                            |
| `org.opencontainers.image.licenses`  | `MIT` (repository SPDX identifier).                         |
| `org.opencontainers.image.title`     | Logical image id (e.g. `node:22`).                          |
| `org.opencontainers.image.description`| One-line purpose, see image matrix in `README.md`.         |
| `id.mincemeat.image.manifest.version`| Manifest semver this image is pinned by.                    |
| `id.mincemeat.image.runtime.track`   | Runtime track (`20`, `22`, `1`, or `hugo`).                 |

## Visibility

- All packages MUST be **public** GHCR packages in v1.
- No private registry dependency is allowed for v1 GA.

## Digest Pinning

- `manifest.json` records the immutable `sha256:` digest of the release tag.
- `build-engine` pulls images by digest, not tag, for reproducibility.
- Base images referenced in Dockerfiles MUST be pinned by digest (or via a
  lock-metadata file checked into the repo).

## Naming Rules

- Logical names use lowercase ASCII, digits, `.`, `-`.
- Tags use lowercase ASCII, digits, `.`, `-`, `_`.
- No uppercase characters; GHCR is case-insensitive but we keep names
  consistent for tooling.
- No leading separator characters (`.`, `-`, `_`).
