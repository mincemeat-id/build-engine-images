#!/usr/bin/env bash
# Write the structured size artifact consumed by CI and release review.

set -euo pipefail

usage() {
    cat <<'EOF'
Usage: scripts/write_image_size_record.sh --image IMAGE --logical LOGICAL --dockerfile PATH --manifest-version VERSION --output PATH
EOF
}

image=""
logical=""
dockerfile=""
manifest_version=""
output=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --image)
            image="${2:-}"
            shift 2
            ;;
        --logical)
            logical="${2:-}"
            shift 2
            ;;
        --dockerfile)
            dockerfile="${2:-}"
            shift 2
            ;;
        --manifest-version)
            manifest_version="${2:-}"
            shift 2
            ;;
        --output)
            output="${2:-}"
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

if [ -z "$image" ] || [ -z "$logical" ] || [ -z "$dockerfile" ] || [ -z "$manifest_version" ] || [ -z "$output" ]; then
    usage >&2
    exit 2
fi

if ! docker image inspect "$image" >/dev/null 2>&1; then
    echo "Image not found locally: $image" >&2
    exit 1
fi

mkdir -p "$(dirname "$output")"

bytes="$(docker image inspect "$image" --format '{{.Size}}')"
mib="$(awk "BEGIN { printf \"%.1f\", $bytes / 1024 / 1024 }")"
image_id="$(docker image inspect "$image" --format '{{.Id}}')"
repo_digests="$(docker image inspect "$image" --format '{{json .RepoDigests}}')"
git_sha="$(git rev-parse HEAD)"

jq -n \
    --arg image "$logical" \
    --arg tag "$image" \
    --argjson bytes "$bytes" \
    --arg mib "$mib" \
    --arg dockerfile "$dockerfile" \
    --arg git_sha "$git_sha" \
    --arg manifest_version "$manifest_version" \
    --arg image_id "$image_id" \
    --argjson repo_digests "$repo_digests" \
    '{
        image: $image,
        tag: $tag,
        bytes: $bytes,
        mib: ($mib | tonumber),
        dockerfile: $dockerfile,
        git_sha: $git_sha,
        manifest_version: $manifest_version,
        image_id: $image_id,
        repo_digests: $repo_digests
    }' > "$output"
