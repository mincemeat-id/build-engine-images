#!/usr/bin/env bash
# Verify install command dispatch defaults for npm, pnpm, yarn, bun.
# Uses fake shims on PATH that record their invocations instead of real
# package managers, so this test runs in any environment.

set -euo pipefail
# shellcheck source=tests/smoke/_helpers.sh
source "$(dirname "$0")/_helpers.sh"

trap cleanup_tmp_env EXIT
setup_tmp_env

# Build a stub PATH with fake npm/pnpm/yarn/bun that just echo args + exit 0.
stub_dir="$TEST_TMP/bin"
mkdir -p "$stub_dir"
for pm in npm pnpm yarn bun; do
    cat > "$stub_dir/$pm" <<EOF
#!/usr/bin/env bash
printf 'STUB-CALL $pm %s\n' "\$*"
exit 0
EOF
    chmod +x "$stub_dir/$pm"
done
# Keep jq + coreutils available; prepend our stubs.
export PATH="$stub_dir:$PATH"

check_pm() {
    local pm="$1" want_install="$2"
    setup_tmp_env  # fresh sandbox per pm
    mkdir -p "$WORKSPACE_SRC"
    cat > "$BUILD_MANIFEST" <<EOF
{
  "framework": "generic",
  "package_manager": "$pm",
  "build_command": "mkdir -p dist && touch dist/index.html",
  "output_dir": "dist"
}
EOF
    rc=0
    run_entrypoint || rc=$?
    assert_zero "$rc" "package_manager=$pm should succeed"
    assert_log_contains "install: $want_install"
    assert_log_contains "STUB-CALL $want_install"
}

check_pm npm  "npm ci"
check_pm pnpm "pnpm install --frozen-lockfile"
check_pm yarn "yarn install --frozen-lockfile"
check_pm bun  "bun install --frozen-lockfile"
