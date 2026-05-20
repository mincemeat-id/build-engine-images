# syntax=docker/dockerfile:1.7
#
# Mincemeat build-engine image: hugo:latest
#
# Base: debian:bookworm-slim, pinned by digest. Hugo extended is downloaded
# from the official GitHub release and verified against a recorded SHA-256.
#
# Refresh the base digest with:
#   docker buildx imagetools inspect debian:bookworm-slim --format '{{.Manifest.Digest}}'
# Refresh Hugo with the checksums file at:
#   https://github.com/gohugoio/hugo/releases/download/v<HUGO_VERSION>/hugo_<HUGO_VERSION>_checksums.txt
FROM debian:bookworm-slim@sha256:0104b334637a5f19aa9c983a91b54c89887c0984081f2068983107a6f6c21eeb

ARG HUGO_VERSION=0.161.1
ARG HUGO_SHA256=9b82cf3211b2321f189a005dd157e6f4bd5c65f2bf5e9eefd2f5e0803c12103c

LABEL org.opencontainers.image.source="https://github.com/mincemeat-id/build-engine-images" \
      org.opencontainers.image.title="hugo:latest" \
      org.opencontainers.image.description="Mincemeat build-engine image: Hugo extended on Debian bookworm-slim for static site builds." \
      org.opencontainers.image.licenses="MIT" \
      id.mincemeat.image.runtime.track="hugo"

ENV DEBIAN_FRONTEND=noninteractive

# Minimal toolchain. Hugo binary is self-contained; we only need ca-certs,
# curl, git, jq (for entrypoint), tar, xz-utils, plus libc6 already in base.
# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        jq \
        tar \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Install Hugo extended (verified by checksum, no pipes -> hadolint clean).
RUN set -eux \
    && curl -fsSL -o /tmp/hugo.tar.gz \
        "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz" \
    && printf '%s  /tmp/hugo.tar.gz\n' "${HUGO_SHA256}" > /tmp/hugo.sha256 \
    && sha256sum -c /tmp/hugo.sha256 \
    && tar -xzf /tmp/hugo.tar.gz -C /tmp hugo \
    && install -m 0755 /tmp/hugo /usr/local/bin/hugo \
    && rm -f /tmp/hugo /tmp/hugo.tar.gz /tmp/hugo.sha256 \
    && hugo version

# Non-root builder user (Hugo image has no upstream user).
RUN groupadd --gid 1000 builder \
    && useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash builder \
    && mkdir -p /workspace/src /workspace/out /cache /build \
    && chown -R builder:builder /workspace /cache /build

COPY entrypoint/build-entrypoint.sh /build-entrypoint.sh
RUN chmod 0755 /build-entrypoint.sh

WORKDIR /workspace/src

USER builder

ENTRYPOINT ["/build-entrypoint.sh"]
