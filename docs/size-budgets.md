# Image Size Budgets

Image size is a release guardrail. CI writes one structured size record per
image and checks it against `image-size-budgets.json`.

## Current budgets

| Image | Max MiB | Baseline MiB | CI Baseline MiB |
|---|---:|---:|---:|
| `node:20` | 650 | 558.1 | 605.5 |
| `node:22` | 650 | 570.2 | 613.4 |
| `bun:1` | 700 | 640.8 | 651.5 |
| `hugo:latest` | 275 | 215.6 | 246.7 |
| `zola:latest` | 250 | 208.4 | 208.4 |

The CI baseline is used for growth checks because workflow builds tag images
as `*-ci` and can include metadata that differs from the local release tag.

## Update process

Update `image-size-budgets.json` only when the size increase is intentional
and explained in the pull request. A valid update should include:

- the new `baseline_ci_mib` from a fresh CI or local `*-ci` build;
- the new `baseline_mib` if the release-tag image also changed;
- a short rationale for the size change;
- confirmation that Trivy still passes and the cold/warm smoke suites still
  pass.

Do not raise `max_mib` for incidental package drift. Refresh the base image,
rebuild, and inspect the package list first.
