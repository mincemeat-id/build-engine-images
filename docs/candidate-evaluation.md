# Candidate Image Evaluation

New candidate frameworks are promoted into the supported manifest only when
they pass the same fixture, documentation, image size, and scan gates used
for existing images.

## Image Strategy

| Candidate | Image Decision | Rationale |
|-----------|----------------|-----------|
| Zola | Add `zola:latest`. | Zola is a standalone binary and should not inflate the generic Node images. |
| Angular static | Reuse `node:22`. | Angular CLI projects build with the existing Node 22 image and native build dependencies. |
| Remix SPA | Reuse `node:22`. | Remix SPA mode is a Node/Vite build and does not need extra native packages beyond `node:22`. |

Framework-specific Node images are not needed for Angular or Remix at this
stage. Revisit this only if fixture smoke timings or image-size reports show
that common dependencies make the generic Node image too large or too slow.

## Promotion Gates

- Positive fixtures must pass in cold and warm smoke runs.
- Negative fixtures must fail with their documented `BUILD_INCOMPATIBLE` code.
- Candidate images must be present in build, Trivy, SBOM, provenance, and size
  reporting workflows before they appear in `manifest.json`.
- Release notes must list the promoted candidate frameworks and any security
  exceptions.
