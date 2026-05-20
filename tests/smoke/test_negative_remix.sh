#!/usr/bin/env bash
# Verify that Remix without ssr: false config fails early.

set -euo pipefail
# shellcheck source=tests/smoke/_helpers.sh
source "$(dirname "$0")/_helpers.sh"

trap cleanup_tmp_env EXIT
setup_tmp_env

# Seed a Remix project without ssr: false.
mkdir -p "$WORKSPACE_SRC"
cat > "$WORKSPACE_SRC/vite.config.js" <<'JS'
import { vitePlugin as remix } from "@remix-run/dev";
export default {
  plugins: [remix()],
}
JS

write_manifest <<'JSON'
{
  "framework": "remix",
  "package_manager": "none",
  "build_command": "vite build",
  "output_dir": "dist"
}
JSON

run_entrypoint || rc=$?
assert_nonzero "${rc:-0}" "Remix without ssr: false config should exit non-zero"
assert_log_contains "BUILD_INCOMPATIBLE: REMIX_REQUIRES_SPA_MODE"
