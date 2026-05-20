#!/usr/bin/env bash
# tests/smoke/_helpers.sh - shared helpers for build-entrypoint tests.
#
# Provides:
#   setup_tmp_env   -> creates an isolated sandbox with /build /workspace /cache
#                      mirrored under a temp dir and exports BUILD_MANIFEST,
#                      WORKSPACE_SRC, WORKSPACE_OUT, CACHE_DIR.
#   write_manifest  -> write the given JSON (stdin) to $BUILD_MANIFEST.
#   run_entrypoint  -> run $ENTRYPOINT_SH with the sandbox env, capturing
#                      stdout+stderr to $TEST_LOG. Returns the exit code.
#   cleanup_tmp_env -> remove the sandbox.

set -euo pipefail

: "${ENTRYPOINT_SH:?ENTRYPOINT_SH must be set by run-tests.sh}"

setup_tmp_env() {
    TEST_TMP="$(mktemp -d)"
    export TEST_TMP
    mkdir -p "$TEST_TMP/build" "$TEST_TMP/workspace/src" "$TEST_TMP/workspace/out" "$TEST_TMP/cache"
    export BUILD_MANIFEST="$TEST_TMP/build/manifest.json"
    export WORKSPACE_SRC="$TEST_TMP/workspace/src"
    export WORKSPACE_OUT="$TEST_TMP/workspace/out"
    export CACHE_DIR="$TEST_TMP/cache"
    export TEST_LOG="$TEST_TMP/entrypoint.log"
}

write_manifest() {
    cat > "$BUILD_MANIFEST"
}

run_entrypoint() {
    set +e
    bash "$ENTRYPOINT_SH" >"$TEST_LOG" 2>&1
    rc=$?
    set -e
    return $rc
}

cleanup_tmp_env() {
    if [ -n "${TEST_TMP:-}" ] && [ -d "$TEST_TMP" ]; then
        rm -rf "$TEST_TMP"
    fi
}

# Print the captured log to stderr (for failing tests).
dump_log() {
    if [ -f "${TEST_LOG:-}" ]; then
        printf '----- entrypoint log -----\n' >&2
        cat "$TEST_LOG" >&2
        printf '--------------------------\n' >&2
    fi
}

assert_nonzero() {
    local rc="$1" msg="${2:-expected non-zero exit, got 0}"
    if [ "$rc" -eq 0 ]; then
        dump_log
        printf 'ASSERT: %s\n' "$msg" >&2
        return 1
    fi
}

assert_zero() {
    local rc="$1" msg="${2:-expected zero exit}"
    if [ "$rc" -ne 0 ]; then
        dump_log
        printf 'ASSERT: %s (rc=%d)\n' "$msg" "$rc" >&2
        return 1
    fi
}

assert_log_contains() {
    local needle="$1"
    if ! grep -qF -- "$needle" "$TEST_LOG"; then
        dump_log
        printf 'ASSERT: log did not contain: %s\n' "$needle" >&2
        return 1
    fi
}
