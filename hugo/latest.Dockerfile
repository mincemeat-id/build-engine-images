# syntax=docker/dockerfile:1.7
#
# Mincemeat build-engine image: hugo:latest
#
# Base: debian:trixie-slim, pinned by digest. Hugo extended is built from
# the official module tag with a pinned Go toolchain so stdlib CVE fixes can
# land before upstream publishes a binary built with that Go patch release.
#
# Refresh the base digest with:
#   docker buildx imagetools inspect debian:trixie-slim --format '{{.Manifest.Digest}}'
# Refresh the Go builder digest with:
#   docker buildx imagetools inspect golang:<GO_VERSION>-trixie --format '{{.Manifest.Digest}}'
ARG GO_VERSION=1.26.3
FROM golang:${GO_VERSION}-trixie@sha256:f34e7161a14638b812ce491bd89c81718f309cac6ec0ffe016e5fbcb4bdc8c06 AS hugo-builder

ARG HUGO_VERSION=0.161.1

ENV CGO_ENABLED=1 \
    GOFLAGS="-trimpath -buildvcs=false"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        g++ \
        git \
    && rm -rf /var/lib/apt/lists/*

RUN go install -tags extended "github.com/gohugoio/hugo@v${HUGO_VERSION}" \
    && /go/bin/hugo version

FROM debian:trixie-slim@sha256:b6e2a152f22a40ff69d92cb397223c906017e1391a73c952b588e51af8883bf8

ARG HUGO_VERSION=0.161.1
ARG VERSION=0.1.0-dev
ARG GIT_REVISION=unknown
ARG BUILD_DATE=unknown
ARG MANIFEST_VERSION=0.1.0-dev

LABEL org.opencontainers.image.source="https://github.com/mincemeat-id/build-engine-images" \
      org.opencontainers.image.revision="${GIT_REVISION}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.title="hugo:latest" \
      org.opencontainers.image.description="Mincemeat build-engine image: Hugo extended on Debian trixie-slim for static site builds." \
      org.opencontainers.image.licenses="MIT" \
      id.mincemeat.image.manifest.version="${MANIFEST_VERSION}" \
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
