# Release Notes Template: manifest.json v<manifest-version>

> **Release Date:** YYYY-MM-DD
> **Manifest Version:** <manifest-version> (e.g. 1.0.0)
> **GitHub Release Tag:** v<manifest-version>

## Compatibility Matrix

This release is compatible with the following versions of the build engine:

| Component | Minimum Version | Maximum Version / Protocol |
|-----------|-----------------|----------------------------|
| `build-engine` | `1.0.0` (or as specified in `engine_compat.engine_min`) | |
| Protocol Version | `1` (`proto_min`) | `1` (`proto_max`) |

## Image Manifest Matrix

The table below lists the logical images defined in `manifest.json` for this release, along with their fully qualified tags, digests, and supported frameworks.

| Logical Image | Tag | Digest (sha256) | Supported Frameworks |
|---------------|-----|-----------------|----------------------|
| `node:20` | `ghcr.io/mincemeat-id/build-engine-images/node:20-<version>` | `<node-20-digest>` | `astro`, `vite`, `eleventy`, `docusaurus`, `vitepress`, `vuepress`, `gatsby`, `nextjs-export`, `nuxt-generate`, `sveltekit-static`, `generic` |
| `node:22` | `ghcr.io/mincemeat-id/build-engine-images/node:22-<version>` | `<node-22-digest>` | `astro`, `vite`, `eleventy`, `docusaurus`, `vitepress`, `vuepress`, `gatsby`, `nextjs-export`, `nuxt-generate`, `sveltekit-static`, `generic` |
| `bun:1` | `ghcr.io/mincemeat-id/build-engine-images/bun:1-<version>` | `<bun-1-digest>` | `astro`, `vite`, `generic` |
| `hugo:latest` | `ghcr.io/mincemeat-id/build-engine-images/hugo:<version>` | `<hugo-digest>` | `hugo` |

## Base Images Pinned

| Logical Image | Base Image | Pinned Base Digest |
|---------------|------------|--------------------|
| `node:20` | `node:20-bookworm-slim` | `sha256:2cf067cfed83d5ea958367df9f966191a942351a2df77d6f0193e162b5febfc0` |
| `node:22` | `node:22-bookworm-slim` | `sha256:3ebc208d842067574e826f4fad4d1e996871ccd1b0a565509531c712a3005ccb` |
| `bun:1` | `oven/bun:1-slim` | `sha256:3ebc208d842067574e826f4fad4d1e996871ccd1b0a565509531c712a3005ccb` (or latest slim build) |
| `hugo:latest` | `debian:bookworm-slim` | `sha256:f52a2656ba8ab776f3f01c7cb7afc4355ecbc868222b40a33118a1a3cc758223` (or slim build) |

## Key Changes in This Release

- Describe changes to Dockerfiles, builder tooling, or entrypoint contract here.
- Example: "Enabled Corepack by default in Node 22 image."
- Example: "Updated package manager dependencies and cache paths."

## Security Scan (Trivy) Summary

All images were scanned with Trivy prior to release and comply with the CVE budget policy:
- **Critical with fixes:** 0
- **High with fixes:** 0 (or list overrides/exceptions if any)
- **Medium with fixes:** 0 (or list warnings if any)

Detailed SBOMs (CycloneDX) and SLSA provenance are attached to each image tag in GHCR and are available for audit.
