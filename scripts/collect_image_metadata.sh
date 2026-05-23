#!/usr/bin/env bash
# Emit machine-readable metadata for a locally available image.

set -euo pipefail

usage() {
    cat <<'EOF'
Usage: scripts/collect_image_metadata.sh --image IMAGE [--expected-codename CODENAME]

Emits JSON with the image digest/ID, size, /etc/os-release, tool versions, and
the dpkg package list. If --expected-codename is supplied, the script exits
non-zero when VERSION_CODENAME/DEBIAN_CODENAME does not match.
EOF
}

image=""
expected_codename=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --image)
            image="${2:-}"
            shift 2
            ;;
        --expected-codename)
            expected_codename="${2:-}"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [ -z "$image" ]; then
    echo "--image is required" >&2
    usage >&2
    exit 2
fi

if ! docker image inspect "$image" >/dev/null 2>&1; then
    echo "Image not found locally: $image" >&2
    exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

run_in_image() {
    local command="$1"
    docker run --rm --entrypoint /bin/sh "$image" -c "$command" 2>/dev/null || true
}

docker run --rm --entrypoint /bin/sh "$image" -c 'cat /etc/os-release' > "$tmp_dir/os-release"
run_in_image "dpkg-query -W -f='\${binary:Package}\t\${Version}\n' | sort" > "$tmp_dir/packages"

os_codename="$(
    awk -F= '
        $1 == "VERSION_CODENAME" || $1 == "DEBIAN_CODENAME" {
            gsub(/"/, "", $2)
            print $2
            exit
        }
    ' "$tmp_dir/os-release"
)"

if [ -n "$expected_codename" ] && [ "$os_codename" != "$expected_codename" ]; then
    echo "Expected OS codename '$expected_codename' for $image, got '${os_codename:-<unknown>}'" >&2
    exit 1
fi

repo_digests="$(docker image inspect "$image" --format '{{json .RepoDigests}}')"
image_id="$(docker image inspect "$image" --format '{{.Id}}')"
bytes="$(docker image inspect "$image" --format '{{.Size}}')"
mib="$(awk "BEGIN { printf \"%.1f\", $bytes / 1024 / 1024 }")"

node_version="$(run_in_image 'command -v node >/dev/null 2>&1 && node --version')"
npm_version="$(run_in_image 'command -v npm >/dev/null 2>&1 && npm --version')"
corepack_version="$(run_in_image 'command -v corepack >/dev/null 2>&1 && corepack --version')"
bun_version="$(run_in_image 'command -v bun >/dev/null 2>&1 && bun --version')"
hugo_version="$(run_in_image 'command -v hugo >/dev/null 2>&1 && hugo version')"
zola_version="$(run_in_image 'command -v zola >/dev/null 2>&1 && zola --version')"
git_version="$(run_in_image 'command -v git >/dev/null 2>&1 && git --version')"
jq_version="$(run_in_image 'command -v jq >/dev/null 2>&1 && jq --version')"
curl_version="$(run_in_image 'command -v curl >/dev/null 2>&1 && curl --version | sed -n "1p"')"

jq -n \
    --arg image "$image" \
    --arg image_id "$image_id" \
    --argjson repo_digests "$repo_digests" \
    --argjson bytes "$bytes" \
    --arg mib "$mib" \
    --arg os_codename "$os_codename" \
    --rawfile os_release "$tmp_dir/os-release" \
    --rawfile package_text "$tmp_dir/packages" \
    --arg node "$node_version" \
    --arg npm "$npm_version" \
    --arg corepack "$corepack_version" \
    --arg bun "$bun_version" \
    --arg hugo "$hugo_version" \
    --arg zola "$zola_version" \
    --arg git "$git_version" \
    --arg jq_version "$jq_version" \
    --arg curl "$curl_version" \
    '{
        image: $image,
        repo_digests: $repo_digests,
        image_id: $image_id,
        size: {
            bytes: $bytes,
            mib: ($mib | tonumber)
        },
        os: {
            codename: $os_codename,
            release: $os_release
        },
        tools: {
            node: ($node | if length > 0 then . else null end),
            npm: ($npm | if length > 0 then . else null end),
            corepack: ($corepack | if length > 0 then . else null end),
            bun: ($bun | if length > 0 then . else null end),
            hugo: ($hugo | if length > 0 then . else null end),
            zola: ($zola | if length > 0 then . else null end),
            git: ($git | if length > 0 then . else null end),
            jq: ($jq_version | if length > 0 then . else null end),
            curl: ($curl | if length > 0 then . else null end)
        },
        packages: (
            $package_text
            | split("\n")
            | map(select(length > 0))
            | map(split("\t") | {name: .[0], version: .[1]})
        )
    }'
