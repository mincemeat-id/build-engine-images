#!/usr/bin/env bash
# Manifest with invalid JSON must cause a non-zero exit with a clear error.

set -euo pipefail
# shellcheck source=tests/smoke/_helpers.sh
source "$(dirname "$0")/_helpers.sh"

trap cleanup_tmp_env EXIT
setup_tmp_env

# Not valid JSON: trailing comma, unclosed brace.
printf '{ "framework": "astro", }\n' > "$BUILD_MANIFEST"

run_entrypoint || rc=$?
assert_nonzero "${rc:-0}" "malformed JSON manifest should exit non-zero"
assert_log_contains "not valid JSON"
