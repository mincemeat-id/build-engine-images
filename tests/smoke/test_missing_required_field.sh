#!/usr/bin/env bash
# A manifest missing a required field must cause a non-zero exit naming the field.

set -euo pipefail
# shellcheck source=tests/smoke/_helpers.sh
source "$(dirname "$0")/_helpers.sh"

trap cleanup_tmp_env EXIT
setup_tmp_env

# Missing 'output_dir'.
write_manifest <<'JSON'
{
  "framework": "generic",
  "package_manager": "none",
  "build_command": "true"
}
JSON

run_entrypoint || rc=$?
assert_nonzero "${rc:-0}" "manifest missing 'output_dir' should exit non-zero"
assert_log_contains "'output_dir' is required"
