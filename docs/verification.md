# Verification

> **Audience:** build-engine maintainers, security reviewers, external
> auditors. Verification steps required before pulling any image or trusting
> any `manifest.json` from this repository.

Every release of `build-engine-images` ships three classes of signed
artifacts:

1. **Image signatures** — keyless cosign signatures over the image manifest
   digest, published next to the image in GHCR.
2. **SLSA build provenance** — in-toto attestations of type
   `https://slsa.dev/provenance/v1`, also stored beside the image in GHCR.
3. **Manifest signature** — a cosign blob signature over `manifest.json`,
   attached to the GitHub Release alongside `manifest.json.sig`,
   `manifest.json.pem`, and `manifest.json.sha256`.

All three rely on Sigstore keyless signing via GitHub OIDC. The certificate
subject identifies the workflow that produced the artifact; the issuer is
`https://token.actions.githubusercontent.com`.

## Prerequisites

```shell
# cosign >= 2.2
brew install cosign      # macOS
# or download from https://github.com/sigstore/cosign/releases

# slsa-verifier >= 2.5
brew install slsa-verifier
# or download from https://github.com/slsa-framework/slsa-verifier/releases

# gh CLI authenticated against your GitHub account
gh auth login
```

## Verify an image cosign signature

```shell
IMAGE=ghcr.io/mincemeat-id/build-engine-images/node@sha256:<digest>

cosign verify "$IMAGE" \
  --certificate-identity-regexp "^https://github.com/mincemeat-id/build-engine-images/" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com"
```

A non-zero exit code means the image was either not signed by this
repository's workflow or has been tampered with.

## Verify a SLSA build-provenance attestation

```shell
IMAGE=ghcr.io/mincemeat-id/build-engine-images/node@sha256:<digest>

cosign verify-attestation "$IMAGE" \
  --type slsaprovenance1 \
  --certificate-identity-regexp "^https://github.com/mincemeat-id/build-engine-images/" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com"
```

For a stronger guarantee that the attestation references the exact source
revision you expect, use `slsa-verifier`:

```shell
slsa-verifier verify-image "$IMAGE" \
  --source-uri github.com/mincemeat-id/build-engine-images \
  --source-tag v<X.Y.Z>
```

## Verify the released manifest.json

The release workflow attaches `manifest.json`, `manifest.json.sig`, and
`manifest.json.pem` to every GitHub Release.

```shell
RELEASE_TAG=v1.0.0
gh release download "$RELEASE_TAG" \
  --repo mincemeat-id/build-engine-images \
  --pattern 'manifest.json*'

# Confirm bundle integrity.
sha256sum -c manifest.json.sha256

# Verify the cosign keyless blob signature.
cosign verify-blob \
  --certificate manifest.json.pem \
  --signature  manifest.json.sig \
  --certificate-identity-regexp "^https://github.com/mincemeat-id/build-engine-images/" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  manifest.json
```

If the signature verifies, every image digest inside `manifest.json` can be
trusted as having been produced by the release workflow. From there, pull
images strictly by digest:

```shell
DIGEST=$(jq -r '.images["node:22"].digest' manifest.json)
docker pull "ghcr.io/mincemeat-id/build-engine-images/node@${DIGEST}"
```

## Verify a 1.0 release candidate locally

The committed development manifest can intentionally contain placeholder tags.
Release-readiness checks should be run against a generated candidate manifest
so the working-tree `manifest.json` remains development-safe until the release
workflow publishes the signed manifest artifact.

```shell
python scripts/generate_manifest.py --validate-only

tmp_manifest=$(mktemp)
python scripts/generate_manifest.py \
  --output "$tmp_manifest" \
  --version-semver 1.0.0 \
  --image-tag node:20=ghcr.io/mincemeat-id/build-engine-images/node:20-1.0.0 \
  --image-tag node:22=ghcr.io/mincemeat-id/build-engine-images/node:22-1.0.0 \
  --image-tag bun:1=ghcr.io/mincemeat-id/build-engine-images/bun:1-1.0.0 \
  --image-tag hugo:latest=ghcr.io/mincemeat-id/build-engine-images/hugo:1.0.0 \
  --image-tag zola:latest=ghcr.io/mincemeat-id/build-engine-images/zola:1.0.0

python scripts/check_manifest_release.py --manifest "$tmp_manifest"
rm -f "$tmp_manifest"
```

During an actual release candidate rehearsal, add the `--image-digest
<logical>=sha256:<digest>` arguments captured from the candidate build artifacts
so the manifest check also covers the exact digests that will be promoted.

## Inspect the SBOM

Every published image carries a CycloneDX SBOM as a CI artifact and, where
available, alongside the image in GHCR. To inspect locally:

```shell
gh run download <run-id> --name sbom-node-22
jq '.components[] | {name, version, purl}' sbom.json | head
```

## SLSA Level Claim

The pipeline targets **SLSA Build Level 3**; see
[design.md](./design.md#slsa-level-claim) for the rationale and the list of
controls that justify the claim.

## What to do on a verification failure

1. Treat the artifact as compromised — do not pull, do not deploy.
2. Open a security issue per [SECURITY.md](../SECURITY.md).
3. Roll back the engine to the previous manifest version per
   [rollback.md](./rollback.md).
