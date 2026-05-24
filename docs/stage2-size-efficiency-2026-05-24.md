# Stage 2 Size, Efficiency, And Performance Evidence

Date: 2026-05-24

## Summary

Stage 2 removed blanket `apt-get upgrade -y` usage, kept targeted security refreshes where the base image needed them, and verified the final images against size budgets, Trivy/CVE budget checks, and cold/warm fixture smoke tests.

## Image Size Delta

| Image | Stage 1 baseline | Stage 2 final | Delta | Delta % | Budget |
|---|---:|---:|---:|---:|---:|
| `bun:1` | 651.5 MiB | 643.3 MiB | -8.2 MiB | -1.3% | 700 MiB |
| `hugo:latest` | 255.2 MiB | 255.2 MiB | 0.0 MiB | 0.0% | 275 MiB |
| `node:20` | 635.3 MiB | 632.8 MiB | -2.5 MiB | -0.4% | 650 MiB |
| `node:22` | 636.6 MiB | 636.6 MiB | 0.0 MiB | 0.0% | 650 MiB |
| `zola:latest` | 217.4 MiB | 217.4 MiB | 0.0 MiB | 0.0% | 250 MiB |

All final records passed `scripts/check_image_size_budget.py` against `image-size-budgets.json`.

## Trivy Delta

| Image | Before fixable critical/high/medium | Final fixable critical/high/medium | Final high without fix | CVE budget |
|---|---:|---:|---:|---|
| `bun:1` | 0 / 0 / 0 | 0 / 0 / 0 | 47 | Pass |
| `hugo:latest` | 0 / 0 / 0 | 0 / 0 / 0 | 17 | Pass |
| `node:20` | 0 / 0 / 0 | 0 / 0 / 0 | 47 | Pass |
| `node:22` | 0 / 0 / 0 | 0 / 0 / 0 | 47 | Pass |
| `zola:latest` | 0 / 0 / 0 | 0 / 0 / 0 | 17 | Pass |

Removing broad upgrades briefly exposed fixable inherited-package findings in `node:20` and `bun:1`. Those were resolved with explicit package refreshes for `libcap2`, `libsystemd0`, `libudev1`, and `sed`, avoiding a blanket upgrade while preserving security posture.

## Smoke Timing

| Suite | Before pass/fail | Final pass/fail | Before total | Final total | Slowest final fixture |
|---|---:|---:|---:|---:|---|
| Cold | 20 / 0 | 20 / 0 | 210.98s | 171.85s | `gatsby-blog` 81.46s |
| Warm | 15 / 0 | 15 / 0 | 65.07s | 43.38s | `gatsby-blog` 11.00s |

Final timing JSON artifacts were produced with:

- `tests/smoke/run-cold.sh --timing-output stage2-results/after/cold-timing.json`
- `tests/smoke/run-warm.sh --timing-output stage2-results/after/warm-timing.json`

The workflow now uploads cold/warm timing JSON from `.github/workflows/fixture-smoke.yml`.

## Package Review

No runtime packages were removed in Stage 2 because the current fixture matrix still exercises the shared entrypoint and framework paths that depend on them:

- Node images retain `python3`, `make`, and `g++` for native npm dependencies such as `node-gyp`-based packages.
- Node and Bun images retain `git`, `curl`, `tar`, `xz-utils`, `ca-certificates`, and `jq` for repository/theme fetches, archive handling, TLS, and entrypoint JSON parsing.
- Hugo and Zola retain `git`, `curl`, `tar`, `xz-utils`, `ca-certificates`, and `jq`; Hugo's builder stage retains `g++` and `git` for the extended Hugo build.
- `node:20` and `bun:1` explicitly refresh inherited `libcap2`, `libsystemd0`, `libudev1`, and `sed` to close fixable CVEs without restoring `apt-get upgrade -y`.

