#!/usr/bin/env bash
# Unknown package_manager values must be rejected.

set -euo pipefail
# shellcheck source=tests/smoke/_helpers.sh
source "$(dirname "$0")/_helpers.sh"

trap cleanup_tmp_env EXIT
setup_tmp_env

write_manifest <<'JSON'
{
  "framework": "generic",
  "package_manager": "rye",
  "build_command": "true",
  "output_dir": "dist"
}
JSON

run_entrypoint || rc=$?
assert_nonzero "${rc:-0}" "unsupported package_manager should exit non-zero"
assert_log_contains "unsupported package_manager: rye"
