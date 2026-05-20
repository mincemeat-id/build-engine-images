#!/usr/bin/env bash
# Happy path with package_manager=none: build command creates output_dir,
# entrypoint copies it to /workspace/out, env vars are exported, and the
# cache directory layout is created.

set -euo pipefail
# shellcheck source=tests/smoke/_helpers.sh
source "$(dirname "$0")/_helpers.sh"

trap cleanup_tmp_env EXIT
setup_tmp_env

# Seed a project root under /workspace/src/site.
mkdir -p "$WORKSPACE_SRC/site"

write_manifest <<'JSON'
{
  "framework": "generic",
  "package_manager": "none",
  "root": "site",
  "build_command": "mkdir -p dist && printf '%s' \"$GREETING\" > dist/index.html",
  "output_dir": "dist",
  "env": {
    "GREETING": "hello"
  }
}
JSON

run_entrypoint || rc=$?
assert_zero "${rc:-0}" "happy path should exit zero"
assert_log_contains "exporting env GREETING"
assert_log_contains "build: mkdir -p dist"
assert_log_contains "done"

# Output should be copied verbatim.
if [ ! -f "$WORKSPACE_OUT/index.html" ]; then
    dump_log
    printf 'ASSERT: %s not created\n' "$WORKSPACE_OUT/index.html" >&2
    exit 1
fi
if [ "$(cat "$WORKSPACE_OUT/index.html")" != "hello" ]; then
    dump_log
    printf 'ASSERT: index.html contents mismatch: %s\n' "$(cat "$WORKSPACE_OUT/index.html")" >&2
    exit 1
fi
