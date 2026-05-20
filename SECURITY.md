# Security Policy

Thank you for helping keep Mincemeat and its users safe.

This repository contains the source code, Dockerfiles, build scripts, and test fixtures for the public Mincemeat builder images published under the `ghcr.io/mincemeat-id/build-engine-images` namespace.

Please follow the guidance below when reporting concerns or contributing changes.

## Reporting a Vulnerability

If you believe you have found a security vulnerability in Mincemeat, Mincemeat container images, build infrastructure, or any component within this repository, please report it **privately**. Do not open a public GitHub issue, pull request, or discussion that includes vulnerability details.

Preferred reporting channels, in order:

1. Email [security@mincemeat.id](mailto:security@mincemeat.id) with a clear description of the issue, impact, and reproduction steps.
2. If email is not possible, use GitHub's private vulnerability reporting on this repository (Security tab → "Report a vulnerability").

Please include:

- A description of the issue and its potential impact.
- Steps to reproduce, proof-of-concept code, or screenshots/logs.
- Your name or handle for acknowledgement, if desired.

We aim to acknowledge new reports within **3 business days** and to provide an initial assessment within **10 business days**. Please give us reasonable time to investigate and remediate before any public disclosure.

## Reporting Sensitive Content in This Repository

If a Dockerfile, layer, test fixture, script, or configuration in this repository exposes information that should not be public—such as credentials, API tokens, customer identifiers, private domains, private hostnames, or internal configurations—report it through the same security channels above so we can remove it quickly.

## Public Repository Safety Checklist

Before opening a pull request or merging changes to this repository, contributors and reviewers must confirm that the change does **not** include any of the following:

- [ ] Production or staging credentials, API tokens, SSH keys, npmrc/yarnrc/bun config credentials, or access keys.
- [ ] Real customer account identifiers, email addresses, project names, or deployment IDs.
- [ ] Real customer domain names or DNS records (use `example.com` or other RFC-compliant example addresses).
- [ ] Private hostnames, internal IP addresses, or non-public service URLs.
- [ ] Cloud provider account IDs, organization IDs, zone IDs, or other operator-only identifiers.
- [ ] Secrets, tokens, or credentials in build arguments, labels, environment variables, or docker configuration files.
- [ ] Stack traces, logs, or build/test artifacts containing any sensitive data.
- [ ] Private repository names, internal Git remotes, or links to private repositories.

The Trivy vulnerability scanner and local git secret scanning are backstops; they are not substitutes for manual review.

## Scope

This policy covers:

- The contents of this repository (`mincemeat-id/build-engine-images`).
- The published container images under `ghcr.io/mincemeat-id/build-engine-images/*`.
