#!/usr/bin/env bash
# tests/smoke/run-tests.sh - shell tests for build-entrypoint.sh.
#
# Each test is a file matching tests/smoke/test_*.sh. Tests are run in their
# own subshell. A test passes when it exits 0.

set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$here/../.." && pwd)"

ENTRYPOINT_SH="$repo_root/entrypoint/build-entrypoint.sh"
export ENTRYPOINT_SH

if ! command -v jq >/dev/null 2>&1; then
    printf 'jq is required to run the build-entrypoint tests\n' >&2
    exit 2
fi

if [ ! -f "$ENTRYPOINT_SH" ]; then
    printf 'entrypoint script not found at %s\n' "$ENTRYPOINT_SH" >&2
    exit 2
fi

failed=0
total=0
for t in "$here"/test_*.sh; do
    [ -e "$t" ] || continue
    total=$((total + 1))
    name="$(basename "$t")"
    printf 'RUN  %s\n' "$name"
    if bash "$t"; then
        printf 'PASS %s\n' "$name"
    else
        printf 'FAIL %s\n' "$name"
        failed=$((failed + 1))
    fi
done

if [ "$total" -eq 0 ]; then
    printf 'no tests found in %s\n' "$here" >&2
    exit 2
fi

if [ "$failed" -gt 0 ]; then
    printf '\n%d/%d test(s) failed\n' "$failed" "$total" >&2
    exit 1
fi
printf '\nall %d test(s) passed\n' "$total"
