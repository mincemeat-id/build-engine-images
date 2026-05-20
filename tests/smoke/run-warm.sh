#!/usr/bin/env bash
# tests/smoke/run-warm.sh - Run warm-cache build smoke tests for v1 GA frameworks.
#
# A warm build reuses the populated cache directory from the cold run.
#
# It resolves the builder images, runs them against positive fixtures,
# asserts that positive fixtures output index.html, asserts expected entrypoint breadcrumbs,
# and outputs a timing report.

set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$here/../.." && pwd)"
cache_dir="$here/cache"

if [ ! -d "$cache_dir" ]; then
    echo "Warning: Cache directory $cache_dir not found. Warm cache test will start cold."
    mkdir -p "$cache_dir"
fi

resolve_image() {
    local name="$1"
    local tag="$2"
    if docker image inspect "build-engine-images/$name:$tag-ci" >/dev/null 2>&1; then
        echo "build-engine-images/$name:$tag-ci"
    elif docker image inspect "build-engine-images/$name:$tag" >/dev/null 2>&1; then
        echo "build-engine-images/$name:$tag"
    else
        echo "Image build-engine-images/$name:$tag not found. Building locally..." >&2
        docker build -t "build-engine-images/$name:$tag" -f "$repo_root/$name/$tag.Dockerfile" "$repo_root" >&2
        echo "build-engine-images/$name:$tag"
    fi
}

echo "=== Resolving Docker Images ==="
NODE_20_IMG="$(resolve_image node 20)"
NODE_22_IMG="$(resolve_image node 22)"
BUN_1_IMG="$(resolve_image bun 1)"
HUGO_LATEST_IMG="$(resolve_image hugo latest)"
echo "Images resolved successfully."

# Define positive fixtures to test in warm mode
declare -a fixtures=(
    "astro-blog|$NODE_22_IMG|positive|0"
    "vite-vanilla|$BUN_1_IMG|positive|0"
    "eleventy-blog|$NODE_22_IMG|positive|0"
    "docusaurus-docs|$NODE_22_IMG|positive|0"
    "vitepress-docs|$NODE_22_IMG|positive|0"
    "vuepress-docs|$NODE_22_IMG|positive|0"
    "gatsby-blog|$NODE_22_IMG|positive|0"
    "hugo-quickstart|$HUGO_LATEST_IMG|positive|0"
    "nextjs-export|$NODE_22_IMG|positive|0"
    "nuxt-generate|$NODE_22_IMG|positive|0"
    "sveltekit-static|$NODE_22_IMG|positive|0"
    "generic-static|$NODE_20_IMG|positive|0"
)

failed=0
declare -a results=()

echo ""
echo "=== Running Warm Build Smoke Tests ==="

for entry in "${fixtures[@]}"; do
    IFS='|' read -r name img type _ <<< "$entry"
    
    echo "Running fixture: $name on $img ($type)..."
    
    fixture_dir="$repo_root/tests/fixtures/$name"
    manifest_file="$fixture_dir/manifest.json"
    
    if [ ! -d "$fixture_dir" ]; then
        echo "Error: Fixture directory $fixture_dir does not exist." >&2
        exit 2
    fi
    
    # Create temp out dir
    out_dir="$(mktemp -d)"
    log_file="$(mktemp)"
    
    start_time=$(date +%s.%N)
    
    set +e
    docker run --rm \
        -v "$manifest_file:/build/manifest.json:ro" \
        -v "$fixture_dir:/workspace/src" \
        -v "$out_dir:/workspace/out" \
        -v "$cache_dir:/cache" \
        "$img" > "$log_file" 2>&1
    rc=$?
    set -e
    
    end_time=$(date +%s.%N)
    duration=$(awk "BEGIN { print $end_time - $start_time }")
    duration_fmt=$(printf "%.2f" "$duration")
    
    # Assertions
    pass=1
    err_msg=""
    
    if [ "$rc" -ne 0 ]; then
        pass=0
        err_msg="Exit code was $rc (expected 0)"
    elif [ ! -f "$out_dir/index.html" ] && [ ! -f "$out_dir/index.htm" ] && [ ! -d "$out_dir" ]; then
        pass=0
        err_msg="Output does not contain index.html"
    elif ! find "$out_dir" -name "index.html" | grep -q .; then
        pass=0
        err_msg="Output index.html file not found in $out_dir"
    else
        # Assert breadcrumbs
        if ! grep -q "install:" "$log_file" && ! grep -q "install: skipped" "$log_file"; then
            pass=0
            err_msg="Missing install breadcrumb in logs"
        elif ! grep -q "build:" "$log_file"; then
            pass=0
            err_msg="Missing build breadcrumb in logs"
        elif ! grep -q "done" "$log_file"; then
            pass=0
            err_msg="Missing done breadcrumb in logs"
        fi
    fi
    
    # Cleanup out/log
    rm -rf "$out_dir"
    
    if [ "$pass" -eq 1 ]; then
        echo "  PASSED ($duration_fmt s)"
        results+=("$name|PASSED|$duration_fmt")
    else
        echo "  FAILED: $err_msg"
        cat "$log_file" >&2
        results+=("$name|FAILED|$duration_fmt")
        failed=$((failed + 1))
    fi
    
    rm -f "$log_file"
done

# Timing report
echo ""
echo "=================================================="
echo "          WARM BUILD SMOKE REPORT"
echo "=================================================="
printf "%-30s %-10s %-10s\n" "Fixture" "Status" "Duration"
echo "--------------------------------------------------"
for res in "${results[@]}"; do
    IFS='|' read -r name status dur <<< "$res"
    if [ "$status" = "PASSED" ]; then
        printf "%-30s \033[32m%-10s\033[0m %-10ss\n" "$name" "$status" "$dur"
    else
        printf "%-30s \033[31m%-10s\033[0m %-10ss\n" "$name" "$status" "$dur"
    fi
done
echo "=================================================="

if [ "$failed" -gt 0 ]; then
    echo "$failed smoke test(s) failed." >&2
    exit 1
fi

echo "All warm build smoke tests passed!"
exit 0
