# syntax=docker/dockerfile:1.7
#
# Mincemeat build-engine image: hugo:latest
#
# Base: debian:bookworm-slim, pinned by digest. Hugo extended is built from
# the official module tag with a pinned Go toolchain so stdlib CVE fixes can
# land before upstream publishes a binary built with that Go patch release.
#
# Refresh the base digest with:
#   docker buildx imagetools inspect debian:bookworm-slim --format '{{.Manifest.Digest}}'
# Refresh the Go builder digest with:
#   docker buildx imagetools inspect golang:<GO_VERSION>-bookworm --format '{{.Manifest.Digest}}'
ARG GO_VERSION=1.26.3
FROM golang:${GO_VERSION}-bookworm@sha256:42c54f63d17473e15b9dbfb86043a2cea5edb295d6c99d46f9aa5826943a6752 AS hugo-builder

ARG HUGO_VERSION=0.161.1

ENV CGO_ENABLED=1 \
    GOFLAGS="-trimpath -buildvcs=false"

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        g++ \
        git \
    && rm -rf /var/lib/apt/lists/*

RUN go install -tags extended "github.com/gohugoio/hugo@v${HUGO_VERSION}" \
    && /go/bin/hugo version

FROM debian:bookworm-slim@sha256:0104b334637a5f19aa9c983a91b54c89887c0984081f2068983107a6f6c21eeb

ARG HUGO_VERSION=0.161.1

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
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        jq \
        tar \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

COPY --from=hugo-builder /go/bin/hugo /usr/local/bin/hugo
RUN hugo version

# Non-root builder user (Hugo image has no upstream user).
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
