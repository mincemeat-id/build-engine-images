#!/usr/bin/env bash
# Verify that Nuxt with build command other than generate fails early.

set -euo pipefail
# shellcheck source=tests/smoke/_helpers.sh
source "$(dirname "$0")/_helpers.sh"

trap cleanup_tmp_env EXIT
setup_tmp_env

# Nuxt without generate in build command
mkdir -p "$WORKSPACE_SRC"

write_manifest <<'JSON'
{
  "framework": "nuxt",
  "package_manager": "none",
  "build_command": "nuxt build",
  "output_dir": ".output/public"
}
JSON

run_entrypoint || rc=$?
assert_nonzero "${rc:-0}" "Nuxt without generate in build command should exit non-zero"
assert_log_contains "BUILD_INCOMPATIBLE: NUXT_REQUIRES_GENERATE"
