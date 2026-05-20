#!/usr/bin/env bash
# Verify that NextJS without output: 'export' config fails early.

set -euo pipefail
# shellcheck source=tests/smoke/_helpers.sh
source "$(dirname "$0")/_helpers.sh"

trap cleanup_tmp_env EXIT
setup_tmp_env

# Seed a Next.js project with no export config.
mkdir -p "$WORKSPACE_SRC"
cat > "$WORKSPACE_SRC/next.config.js" <<'JS'
module.exports = {
  // Not static export
}
JS

write_manifest <<'JSON'
{
  "framework": "nextjs",
  "package_manager": "none",
  "build_command": "next build",
  "output_dir": "out"
}
JSON

run_entrypoint || rc=$?
assert_nonzero "${rc:-0}" "Next.js without export config should exit non-zero"
assert_log_contains "BUILD_INCOMPATIBLE: NEXTJS_REQUIRES_EXPORT"
