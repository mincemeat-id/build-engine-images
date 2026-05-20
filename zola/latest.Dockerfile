# syntax=docker/dockerfile:1.7
#
# Mincemeat build-engine image: zola:latest
#
# Base: debian:bookworm-slim, pinned by digest.
# Refresh the base digest with:
#   docker buildx imagetools inspect debian:bookworm-slim --format '{{.Manifest.Digest}}'
FROM debian:bookworm-slim@sha256:0104b334637a5f19aa9c983a91b54c89887c0984081f2068983107a6f6c21eeb

ARG ZOLA_VERSION=0.22.1

LABEL org.opencontainers.image.source="https://github.com/mincemeat-id/build-engine-images" \
      org.opencontainers.image.title="zola:latest" \
      org.opencontainers.image.description="Mincemeat build-engine image: Zola static site generator on Debian bookworm-slim." \
      org.opencontainers.image.licenses="MIT" \
      id.mincemeat.image.runtime.track="zola"

ENV DEBIAN_FRONTEND=noninteractive

# Zola ships as a self-contained binary. jq is required by /build-entrypoint.sh.
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
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL \
        "https://github.com/getzola/zola/releases/download/v${ZOLA_VERSION}/zola-v${ZOLA_VERSION}-x86_64-unknown-linux-gnu.tar.gz" \
        -o /tmp/zola.tar.gz \
    && tar -xzf /tmp/zola.tar.gz -C /usr/local/bin zola \
    && rm -f /tmp/zola.tar.gz \
    && zola --version

RUN groupadd --gid 1000 builder \
    && useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash builder \
    && mkdir -p /workspace/src /workspace/out /cache /build \
    && chown -R builder:builder /workspace /cache /build

COPY entrypoint/build-entrypoint.sh /build-entrypoint.sh
RUN chmod 0755 /build-entrypoint.sh

WORKDIR /workspace/src

USER builder

HEALTHCHECK NONE

ENTRYPOINT ["/build-entrypoint.sh"]
