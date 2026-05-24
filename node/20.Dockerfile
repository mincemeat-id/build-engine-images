# syntax=docker/dockerfile:1.7
#
# Mincemeat build-engine image: node:20
#
# Base: official Debian (trixie-slim) variant of node:20, pinned by digest.
# Refresh the digest with:
#   docker buildx imagetools inspect node:20-trixie-slim --format '{{.Manifest.Digest}}'
FROM node:20-trixie-slim@sha256:abfbe12cc943141a0c9e8c0a57d710df1dadd95d35e8662cc02958b284d1f35b

ARG VERSION=0.1.0-dev
ARG GIT_REVISION=unknown
ARG BUILD_DATE=unknown
ARG MANIFEST_VERSION=0.1.0-dev

LABEL org.opencontainers.image.source="https://github.com/mincemeat-id/build-engine-images" \
      org.opencontainers.image.revision="${GIT_REVISION}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.title="node:20" \
      org.opencontainers.image.description="Mincemeat build-engine image: Node.js 20 LTS on Debian trixie-slim with Corepack and native build deps." \
      org.opencontainers.image.licenses="MIT" \
      id.mincemeat.image.manifest.version="${MANIFEST_VERSION}" \
      id.mincemeat.image.runtime.track="20"

ENV DEBIAN_FRONTEND=noninteractive \
    NPM_CONFIG_UPDATE_NOTIFIER=false \
    NPM_CONFIG_FUND=false \
    COREPACK_ENABLE_DOWNLOAD_PROMPT=0

ARG NPM_VERSION=11.14.1
ARG BRACE_EXPANSION_VERSION=5.0.6

# Minimal toolchain. python3/make/g++ are required by many native npm modules
# (sharp, sqlite3, node-gyp). jq is required by /build-entrypoint.sh.
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

RUN npm install -g "npm@${NPM_VERSION}" \
    && tmp_dir="$(mktemp -d)" \
    && npm pack "brace-expansion@${BRACE_EXPANSION_VERSION}" --pack-destination "${tmp_dir}" \
    && rm -rf /usr/local/lib/node_modules/npm/node_modules/brace-expansion \
    && mkdir -p /usr/local/lib/node_modules/npm/node_modules/brace-expansion \
    && tar -xzf "${tmp_dir}/brace-expansion-${BRACE_EXPANSION_VERSION}.tgz" \
        -C /usr/local/lib/node_modules/npm/node_modules/brace-expansion \
        --strip-components=1 \
    && rm -rf "${tmp_dir}"

# Enable Corepack so projects can opt into pnpm/yarn via packageManager field.
RUN corepack enable

COPY entrypoint/build-entrypoint.sh /build-entrypoint.sh
RUN chmod 0755 /build-entrypoint.sh \
    && mkdir -p /workspace/src /workspace/out /cache /build \
    && chown -R node:node /workspace /cache /build

WORKDIR /workspace/src

USER node

HEALTHCHECK NONE

ENTRYPOINT ["/build-entrypoint.sh"]
