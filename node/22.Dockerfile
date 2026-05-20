# syntax=docker/dockerfile:1.7
#
# Mincemeat build-engine image: node:22 (default Node image).
#
# Base: official Debian (bookworm-slim) variant of node:22, pinned by digest.
# Refresh the digest with:
#   docker buildx imagetools inspect node:22-bookworm-slim --format '{{.Manifest.Digest}}'
FROM node:22-bookworm-slim@sha256:3ebc208d842067574e826f4fad4d1e996871ccd1b0a565509531c712a3005ccb

LABEL org.opencontainers.image.source="https://github.com/mincemeat-id/build-engine-images" \
      org.opencontainers.image.title="node:22" \
      org.opencontainers.image.description="Mincemeat build-engine image: Node.js 22 (default) on Debian bookworm-slim with Corepack and native build deps." \
      org.opencontainers.image.licenses="MIT" \
      id.mincemeat.image.runtime.track="22"

ENV DEBIAN_FRONTEND=noninteractive \
    NPM_CONFIG_UPDATE_NOTIFIER=false \
    NPM_CONFIG_FUND=false \
    COREPACK_ENABLE_DOWNLOAD_PROMPT=0

# Minimal toolchain. python3/make/g++ are required by many native npm modules
# (sharp, sqlite3, node-gyp). jq is required by /build-entrypoint.sh.
# hadolint ignore=DL3008
RUN apt-get update \
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

# Enable Corepack so projects can opt into pnpm/yarn via packageManager field.
RUN corepack enable

COPY entrypoint/build-entrypoint.sh /build-entrypoint.sh
RUN chmod 0755 /build-entrypoint.sh \
    && mkdir -p /workspace/src /workspace/out /cache /build \
    && chown -R node:node /workspace /cache /build

WORKDIR /workspace/src

USER node

ENTRYPOINT ["/build-entrypoint.sh"]
