#!/usr/bin/env bash
# Verify that SvelteKit without adapter-static config fails early.

set -euo pipefail
# shellcheck source=tests/smoke/_helpers.sh
source "$(dirname "$0")/_helpers.sh"

trap cleanup_tmp_env EXIT
setup_tmp_env

# Seed a SvelteKit project with node/auto adapter instead of static.
mkdir -p "$WORKSPACE_SRC"
cat > "$WORKSPACE_SRC/svelte.config.js" <<'JS'
import adapter from '@sveltejs/adapter-node';
export default {
  kit: {
    adapter: adapter()
  }
};
JS

write_manifest <<'JSON'
{
  "framework": "sveltekit",
  "package_manager": "none",
  "build_command": "vite build",
  "output_dir": "build"
}
JSON

run_entrypoint || rc=$?
assert_nonzero "${rc:-0}" "SvelteKit without adapter-static config should exit non-zero"
assert_log_contains "BUILD_INCOMPATIBLE: SVELTEKIT_REQUIRES_STATIC_ADAPTER"
