#!/usr/bin/env bash
# Build command succeeds but the configured output_dir is not created;
# entrypoint must fail with a clear error and not silently produce an empty
# /workspace/out.

set -euo pipefail
# shellcheck source=tests/smoke/_helpers.sh
source "$(dirname "$0")/_helpers.sh"

trap cleanup_tmp_env EXIT
setup_tmp_env

write_manifest <<'JSON'
{
  "framework": "generic",
  "package_manager": "none",
  "build_command": "true",
  "output_dir": "dist"
}
JSON

run_entrypoint || rc=$?
assert_nonzero "${rc:-0}" "missing output_dir after build should exit non-zero"
assert_log_contains "configured output_dir not found after build"
