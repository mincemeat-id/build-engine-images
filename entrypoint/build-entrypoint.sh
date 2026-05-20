#!/usr/bin/env bash
# /build-entrypoint.sh - shared entrypoint for build-engine-images.
#
# Contract (see build-engine-images-design.md "Entrypoint Contract"):
#   Inputs (mounted by the build engine):
#     /build/manifest.json   Build manifest (framework, package_manager,
#                            root, install_command, build_command,
#                            output_dir, env).
#     /workspace/src         Source tree mount.
#     /workspace/out         Normalized output mount (written by this script).
#     /cache                 Package-manager cache mount.
#
#   Steps:
#     1. Parse /build/manifest.json.
#     2. Configure package-manager cache paths under /cache.
#     3. Run the install command (defaulted per package manager).
#     4. Run the build command.
#     5. Copy configured output_dir into /workspace/out.
#     6. Stream stdout/stderr unmodified for engine log capture.
#     7. Exit non-zero on any failure.
#
# Paths can be overridden via env vars for local testing:
#   BUILD_MANIFEST, WORKSPACE_SRC, WORKSPACE_OUT, CACHE_DIR.

set -euo pipefail

BUILD_MANIFEST="${BUILD_MANIFEST:-/build/manifest.json}"
WORKSPACE_SRC="${WORKSPACE_SRC:-/workspace/src}"
WORKSPACE_OUT="${WORKSPACE_OUT:-/workspace/out}"
CACHE_DIR="${CACHE_DIR:-/cache}"

log() {
    printf '[build-entrypoint] %s\n' "$*" >&2
}

die() {
    printf '[build-entrypoint] error: %s\n' "$*" >&2
    exit 1
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

require_cmd jq

[ -f "$BUILD_MANIFEST" ] || die "build manifest not found at $BUILD_MANIFEST"

# Validate JSON parseability up front so malformed manifests fail fast with
# a clear error rather than a confusing jq error mid-pipeline.
if ! jq_err="$(jq -e '.' "$BUILD_MANIFEST" 2>&1 >/dev/null)"; then
    die "build manifest is not valid JSON: $jq_err"
fi

framework="$(jq -r '.framework // ""' "$BUILD_MANIFEST")"
package_manager="$(jq -r '.package_manager // ""' "$BUILD_MANIFEST")"
build_command="$(jq -r '.build_command // ""' "$BUILD_MANIFEST")"
output_dir="$(jq -r '.output_dir // ""' "$BUILD_MANIFEST")"
root_rel="$(jq -r '.root // "."' "$BUILD_MANIFEST")"
install_command="$(jq -r '.install_command // ""' "$BUILD_MANIFEST")"

[ -n "$framework" ]       || die "manifest field 'framework' is required"
[ -n "$package_manager" ] || die "manifest field 'package_manager' is required"
[ -n "$build_command" ]   || die "manifest field 'build_command' is required"
[ -n "$output_dir" ]      || die "manifest field 'output_dir' is required"

case "$package_manager" in
    npm|pnpm|yarn|bun|none) ;;
    *) die "unsupported package_manager: $package_manager (expected one of: npm, pnpm, yarn, bun, none)" ;;
esac

[ -d "$WORKSPACE_SRC" ] || die "source mount not found at $WORKSPACE_SRC"

# Resolve project root inside the source tree.
project_root="$(cd "$WORKSPACE_SRC" && cd "$root_rel" 2>/dev/null && pwd)" \
    || die "project root not found: $WORKSPACE_SRC/$root_rel"

log "framework=$framework package_manager=$package_manager root=$root_rel"
log "project_root=$project_root"

# Export user-supplied env from manifest.env.
while IFS=$'\t' read -r key value; do
    [ -z "$key" ] && continue
    log "exporting env $key"
    export "$key=$value"
done < <(jq -r '.env // {} | to_entries[] | [.key, (.value|tostring)] | @tsv' "$BUILD_MANIFEST")

# Configure package-manager cache paths.
mkdir -p "$CACHE_DIR"
case "$package_manager" in
    npm)
        export NPM_CONFIG_CACHE="$CACHE_DIR/npm"
        mkdir -p "$NPM_CONFIG_CACHE"
        log "npm cache: $NPM_CONFIG_CACHE"
        ;;
    pnpm)
        export PNPM_STORE_DIR="$CACHE_DIR/pnpm"
        mkdir -p "$PNPM_STORE_DIR"
        log "pnpm store: $PNPM_STORE_DIR"
        ;;
    yarn)
        export YARN_CACHE_FOLDER="$CACHE_DIR/yarn"
        mkdir -p "$YARN_CACHE_FOLDER"
        log "yarn cache: $YARN_CACHE_FOLDER"
        ;;
    bun)
        export BUN_INSTALL_CACHE_DIR="$CACHE_DIR/bun"
        mkdir -p "$BUN_INSTALL_CACHE_DIR"
        log "bun cache: $BUN_INSTALL_CACHE_DIR"
        ;;
    none)
        log "no package manager cache (package_manager=none)"
        ;;
esac

default_install_command() {
    case "$package_manager" in
        npm)  printf 'npm ci' ;;
        pnpm) printf 'pnpm install --frozen-lockfile' ;;
        yarn) printf 'yarn install --frozen-lockfile' ;;
        bun)  printf 'bun install --frozen-lockfile' ;;
        none) printf '' ;;
    esac
}

if [ -z "$install_command" ]; then
    install_command="$(default_install_command)"
fi

cd "$project_root"

if [ -n "$install_command" ]; then
    # pnpm requires explicit store-dir config for some versions; setting the
    # env var above covers most, but configure here too for robustness.
    if [ "$package_manager" = "pnpm" ] && command -v pnpm >/dev/null 2>&1; then
        pnpm config set store-dir "$PNPM_STORE_DIR" >/dev/null 2>&1 || true
    fi
    log "install: $install_command"
    bash -c "$install_command"
else
    log "install: skipped (package_manager=none)"
fi

log "build: $build_command"
bash -c "$build_command"

# Copy configured output to /workspace/out.
output_src="$project_root/$output_dir"
[ -d "$output_src" ] || die "configured output_dir not found after build: $output_src"

mkdir -p "$WORKSPACE_OUT"
# Clear destination for a deterministic copy.
find "$WORKSPACE_OUT" -mindepth 1 -delete

log "copying $output_src -> $WORKSPACE_OUT"
# Copy each top-level child individually so file mode/timestamps are preserved
# but cp never tries to update metadata on $WORKSPACE_OUT itself. The output
# mount is typically owned by the host runner UID, and a non-root container
# user cannot utime()/chmod() that directory.
find "$output_src" -mindepth 1 -maxdepth 1 -exec cp -a -t "$WORKSPACE_OUT/" {} +

log "done"
