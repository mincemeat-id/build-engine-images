# Stage 0 Baseline Artifact - 2026-05-23

This directory records the local Stage 0 baseline for the current image set.

## Environment

- Docker daemon: 29.5.2
- Docker Buildx: v0.34.0
- Trivy runner: `aquasec/trivy:0.58.2`

## OS baseline

| Image | Runtime OS codename |
|---|---|
| `node:20` | `bookworm` |
| `node:22` | `bookworm` |
| `bun:1` | `trixie` |
| `hugo:latest` | `bookworm` |
| `zola:latest` | `bookworm` |

`bun:1` is based on Oven's generic Debian track and currently reports Debian
13/Trixie at runtime. The Node, Hugo, and Zola images remain Bookworm-based.

## Size baseline

| Image | Release MiB | CI MiB | Max MiB |
|---|---:|---:|---:|
| `node:20` | 558.1 | 605.5 | 650 |
| `node:22` | 570.2 | 613.4 | 650 |
| `bun:1` | 640.8 | 651.5 | 700 |
| `hugo:latest` | 215.6 | 246.7 | 275 |
| `zola:latest` | 208.4 | 208.4 | 250 |

Structured CI size records are in `size-records/`, with a combined
`size-summary.json`.

## Metadata and package lists

Per-image metadata lives in `image-metadata/`. Each file includes:

- image ID and local digest data;
- byte and MiB size;
- raw `/etc/os-release`;
- runtime tool versions;
- full `dpkg-query` package list.

## Trivy baseline

`trivy-summary.json` contains compact severity counts from local
`aquasec/trivy:0.58.2` scans. The current budget gate passed for every image
because there were no critical/high findings with fixes.

| Image | Critical | High | Medium | Low | Unknown | Critical/High With Fix |
|---|---:|---:|---:|---:|---:|---:|
| `node:20` | 6 | 153 | 814 | 704 | 8 | 0 |
| `node:22` | 6 | 153 | 814 | 704 | 8 | 0 |
| `bun:1` | 4 | 47 | 295 | 633 | 4 | 0 |
| `hugo:latest` | 1 | 22 | 90 | 136 | 4 | 0 |
| `zola:latest` | 1 | 22 | 90 | 136 | 4 | 0 |

Unfixed critical/high findings still need release-note acknowledgement under
the existing policy.

## Fixture timing

Cold and warm smoke logs are saved as `cold-smoke.log` and `warm-smoke.log`.

| Fixture | Cold seconds | Warm seconds |
|---|---:|---:|
| `astro-blog` | 6.45 | 3.13 |
| `vite-vanilla` | 0.57 | 0.48 |
| `eleventy-blog` | 1.83 | 1.31 |
| `docusaurus-docs` | 59.62 | 4.53 |
| `vitepress-docs` | 3.48 | 3.29 |
| `vuepress-docs` | 4.37 | 3.12 |
| `gatsby-blog` | 81.04 | 9.80 |
| `hugo-quickstart` | 0.36 | 0.34 |
| `zola-quickstart` | 0.33 | 0.32 |
| `nextjs-export` | 8.21 | 7.42 |
| `nuxt-generate` | 4.36 | 4.23 |
| `sveltekit-static` | 3.20 | 2.51 |
| `angular-static` | 0.40 | 0.44 |
| `remix-spa` | 0.39 | 0.40 |
| `generic-static` | 0.69 | 0.62 |

The cold suite also covered the negative fixtures:

| Fixture | Cold seconds |
|---|---:|
| `nextjs-noexport` | 0.30 |
| `remix-ssr` | 0.29 |
| `angular-ssr` | 0.31 |
| `sveltekit-node-adapter` | 0.30 |
| `nuxt-ssr-build` | 0.29 |

## Secret preflight status

GitHub CLI preflight details are recorded in
`github-secret-preflight.md`. The authenticated user has admin access to both
repositories, and the workflow grants the default `GITHUB_TOKEN` `packages:
write` permission for GHCR publish.

The workflow files reference the expected secrets and permissions:

- `build-and-publish.yml` grants `packages: write` and uses the default
  `GITHUB_TOKEN` for GHCR publish.
- `manifest-publish.yml` references `MANIFEST_BUMP_APP_ID` and
  `MANIFEST_BUMP_APP_PRIVATE_KEY`.
- `manifest-publish.yml` scopes the GitHub App token to
  `mincemeat-id/build-engine`.

Repository-level Actions secrets are not configured. Confirming whether the
manifest bump secrets exist as org-level Actions secrets, and confirming the
GitHub App installation permissions, still requires org Actions-secret
visibility or GitHub App JWT credentials.
