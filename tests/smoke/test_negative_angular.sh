#!/usr/bin/env bash
# Verify that Angular server output fails early.

set -euo pipefail
# shellcheck source=tests/smoke/_helpers.sh
source "$(dirname "$0")/_helpers.sh"

trap cleanup_tmp_env EXIT
setup_tmp_env

cat > "$WORKSPACE_SRC/angular.json" <<'JSON'
{
  "version": 1,
  "projects": {
    "app": {
      "architect": {
        "build": {
          "options": {
            "outputMode": "server",
            "server": "src/main.server.ts",
            "ssr": true
          }
        }
      }
    }
  }
}
JSON

write_manifest <<'JSON'
{
  "framework": "angular",
  "package_manager": "none",
  "build_command": "mkdir -p dist/browser && printf '<html></html>' > dist/browser/index.html",
  "output_dir": "dist/browser"
}
JSON

run_entrypoint || rc=$?
assert_nonzero "${rc:-0}" "Angular server output should exit non-zero"
assert_log_contains "BUILD_INCOMPATIBLE: ANGULAR_REQUIRES_STATIC_OUTPUT"
