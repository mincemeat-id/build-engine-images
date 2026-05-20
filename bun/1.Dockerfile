# syntax=docker/dockerfile:1.7
#
# Mincemeat build-engine image: bun:1
#
# Base: official Debian variant of oven/bun:1, pinned by digest.
# Refresh the digest with:
#   docker buildx imagetools inspect oven/bun:1-debian --format '{{.Manifest.Digest}}'
FROM oven/bun:1-debian@sha256:9dba1a1b43ce28c9d7931bfc4eb00feb63b0114720a0277a8f939ae4dfc9db6f

LABEL org.opencontainers.image.source="https://github.com/mincemeat-id/build-engine-images" \
      org.opencontainers.image.title="bun:1" \
      org.opencontainers.image.description="Mincemeat build-engine image: Bun 1.x on Debian for Astro, Vite, and generic static builds." \
      org.opencontainers.image.licenses="MIT" \
      id.mincemeat.image.runtime.track="1"

ENV DEBIAN_FRONTEND=noninteractive

# Minimal toolchain. python3/make/g++ are kept for the small subset of Bun
# projects that still resolve native node-gyp dependencies. jq is required by
# /build-entrypoint.sh.
# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        jq \
        tar \
        xz-utils \
        python3 \
        make \
        g++ \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint/build-entrypoint.sh /build-entrypoint.sh
RUN chmod 0755 /build-entrypoint.sh \
    && mkdir -p /workspace/src /workspace/out /cache /build \
    && chown -R bun:bun /workspace /cache /build

WORKDIR /workspace/src

USER bun

HEALTHCHECK NONE

ENTRYPOINT ["/build-entrypoint.sh"]
