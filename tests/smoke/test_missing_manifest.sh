#!/usr/bin/env bash
# A missing /build/manifest.json must cause a non-zero exit with a clear error.

set -euo pipefail
# shellcheck source=tests/smoke/_helpers.sh
source "$(dirname "$0")/_helpers.sh"

trap cleanup_tmp_env EXIT
setup_tmp_env

# Do not write the manifest file at all.
rm -f "$BUILD_MANIFEST"

run_entrypoint || rc=$?
assert_nonzero "${rc:-0}" "missing manifest should exit non-zero"
assert_log_contains "build manifest not found"
