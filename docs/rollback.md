# Rollback Procedure for Build Engine Images

This document outlines the procedure for rolling back builder images or the image manifest in case of build-engine failures or regressions.

## Rollback Policy

1. **Do Not Mutate Existing Tags:** Once an image tag is published to GHCR (e.g., `node:22-1.0.0`), it is immutable. Do not delete, overwrite, or re-push to an existing release tag. This ensures builds remain deterministic and reproducible.
2. **Revert Manifest Bump:** The authoritative link between the build engine and the builder images is the `manifest.json` file inside the `mincemeat-id/build-engine` codebase. Rolling back is done by reverting the manifest bump in the build engine.

## Step-by-Step Rollback Workflow

In the event of a regression introduced by a new image or manifest version:

### 1. Identify the Last Known Good Manifest Version
Determine the version of `manifest.json` that was stable. You can find this in:
- The git history of the `mincemeat-id/build-engine` repository.
- The releases list of the `build-engine-images` repository.

### 2. Revert the Manifest Bump in `build-engine`
Locate the pull request or commit that bumped the manifest version in the `mincemeat-id/build-engine` repository.
Revert the commit:
```bash
git clone git@github.com:mincemeat-id/build-engine.git
cd build-engine
git revert <commit-hash-of-manifest-bump>
```
Push the revert to a branch, open a PR, merge it, or push directly to the main branch as allowed by the repository policy.

### 3. Redeploy the Build Engine
Redeploy the build engine. The build engine will now load the reverted (previous accepted) `manifest.json`, which references the older, stable image tags and their corresponding pinned digests.

### 4. Investigate and Fix
Do not modify the release that was just rolled back. Fix the root cause in the `build-engine-images` repository, run smoke tests locally, and publish a new version (e.g., `v1.0.1`) containing the fix.
