#!/usr/bin/env python3
"""Script to generate, update, and validate build-engine-images manifest.json."""

import argparse
import datetime
import json
import subprocess
import sys
from typing import Any

from jsonschema import Draft202012Validator


def run_cmd(args: list[str]) -> str:
    """Run a system command and return stdout."""
    res = subprocess.run(args, capture_output=True, text=True, check=True)
    return res.stdout.strip()


def get_local_docker_info(image_name: str) -> dict[str, str] | None:
    """Query docker daemon for image repo digest or ID."""
    # Look for candidate tags in order
    candidates = [
        f"build-engine-images/{image_name}-ci",
        f"build-engine-images/{image_name}",
        f"ghcr.io/mincemeat-id/build-engine-images/{image_name}",
    ]

    for candidate in candidates:
        try:
            # We fetch RepoDigests and ID
            output = run_cmd(
                [
                    "docker",
                    "image",
                    "inspect",
                    candidate,
                    "--format",
                    "{{json .RepoDigests}}||{{json .Id}}",
                ]
            )
            digests_json, img_id_json = output.split("||")
            digests = json.loads(digests_json) or []
            img_id = json.loads(img_id_json) or ""

            # Check if there is a RepoDigest
            digest = ""
            for d in digests:
                if "@sha256:" in d:
                    digest = "sha256:" + d.split("@sha256:")[-1]
                    break

            # Fallback to image ID if no repo digest exists yet (e.g. local build)
            if not digest and img_id.startswith("sha256:"):
                digest = img_id

            if digest:
                return {"digest": digest, "matched_tag": candidate}
        except subprocess.CalledProcessError:
            continue

    return None


def main() -> None:
    parser = argparse.ArgumentParser(description="Manage build engine images manifest.")
    parser.add_argument(
        "--manifest",
        default="manifest.json",
        help="Path to manifest.json file.",
    )
    parser.add_argument(
        "--schema",
        default="schemas/manifest.schema.json",
        help="Path to manifest schema file.",
    )
    parser.add_argument(
        "--version-semver",
        help="Update the manifest version.",
    )
    parser.add_argument(
        "--image-tag",
        action="append",
        default=[],
        help="Update tag for an image. Format: logical_name=tag_value",
    )
    parser.add_argument(
        "--image-digest",
        action="append",
        default=[],
        help="Update digest for an image. Format: logical_name=digest_value",
    )
    parser.add_argument(
        "--inspect",
        action="store_true",
        help="Inspect local docker daemon to populate digests.",
    )
    parser.add_argument(
        "--validate-only",
        action="store_true",
        help="Only validate the manifest and exit.",
    )
    parser.add_argument(
        "--output",
        help="Path to write the updated manifest. Defaults to overwriting the input manifest.",
    )

    args = parser.parse_args()

    # Load schema
    try:
        with open(args.schema, encoding="utf-8") as f:
            schema = json.load(f)
    except FileNotFoundError:
        print(f"Error: Schema file not found at {args.schema}", file=sys.stderr)
        sys.exit(1)

    # Validate the schema itself
    try:
        Draft202012Validator.check_schema(schema)
    except Exception as e:
        print(f"Error: Invalid JSON schema: {e}", file=sys.stderr)
        sys.exit(1)

    # Load manifest
    try:
        with open(args.manifest, encoding="utf-8") as f:
            manifest = json.load(f)
    except FileNotFoundError:
        print(f"Error: Manifest file not found at {args.manifest}", file=sys.stderr)
        sys.exit(1)

    if args.validate_only:
        v = Draft202012Validator(schema)
        errors = list(v.iter_errors(manifest))
        if errors:
            print(f"Error: Manifest validation failed against {args.schema}:", file=sys.stderr)
            for err in errors:
                loc = "/".join(str(p) for p in err.path) or "<root>"
                print(f"  {loc}: {err.message}", file=sys.stderr)
            sys.exit(1)
        print("Manifest is valid.")
        sys.exit(0)

    # Update version
    if args.version_semver:
        manifest["version"] = args.version_semver

    # Update tags
    for tag_pair in args.image_tag:
        if "=" not in tag_pair:
            print(f"Error: Invalid --image-tag format '{tag_pair}'. Expected key=value.", file=sys.stderr)
            sys.exit(1)
        name, val = tag_pair.split("=", 1)
        if name not in manifest.get("images", {}):
            print(f"Error: Image '{name}' not found in manifest.", file=sys.stderr)
            sys.exit(1)
        manifest["images"][name]["tag"] = val

    # Update digests
    for digest_pair in args.image_digest:
        if "=" not in digest_pair:
            print(f"Error: Invalid --image-digest format '{digest_pair}'. Expected key=value.", file=sys.stderr)
            sys.exit(1)
        name, val = digest_pair.split("=", 1)
        if name not in manifest.get("images", {}):
            print(f"Error: Image '{name}' not found in manifest.", file=sys.stderr)
            sys.exit(1)
        manifest["images"][name]["digest"] = val

    # Auto-inspect docker images
    if args.inspect:
        for name in manifest.get("images", {}):
            # Convert logical name 'node:22' or 'hugo:latest' to filesystem name format 'node/22' or similar
            # Logical names inside docker are build-engine-images/node:22 or build-engine-images/hugo:latest
            # So the name to query is just the logical name key!
            info = get_local_docker_info(name)
            if info:
                print(f"Auto-inspected '{name}': digest={info['digest']} (from {info['matched_tag']})")
                manifest["images"][name]["digest"] = info["digest"]
            else:
                print(f"Warning: Could not find local docker image for '{name}' to inspect.", file=sys.stderr)

    # Update generated_at
    manifest["generated_at"] = datetime.datetime.now(datetime.timezone.utc).isoformat().replace("+00:00", "Z")

    # Validate updated manifest before writing
    v = Draft202012Validator(schema)
    errors = list(v.iter_errors(manifest))
    if errors:
        print("Error: Updated manifest would be invalid:", file=sys.stderr)
        for err in errors:
            loc = "/".join(str(p) for p in err.path) or "<root>"
            print(f"  {loc}: {err.message}", file=sys.stderr)
        sys.exit(1)

    # Save manifest
    out_path = args.output if args.output else args.manifest
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
        f.write("\n")

    print(f"Successfully generated and validated manifest at {out_path}")


if __name__ == "__main__":
    main()
