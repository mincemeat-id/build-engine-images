#!/usr/bin/env python3
"""Stage 0 Quick Win: release-only guard that rejects placeholder values
in ``manifest.json``.

The JSON schema already rejects ``version: "0.0.0"`` via ``not.const``.
This script provides a second, narrower release-only gate that also
fails on tags that still contain the ``0.0.0`` placeholder so a release
event cannot accidentally ship pre-bump artifacts.

Exit codes:
  0 = manifest is release-ready
  1 = manifest still contains a placeholder
"""

from __future__ import annotations

import argparse
import json
import sys

PLACEHOLDER_VERSION = "0.0.0"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--manifest",
        default="manifest.json",
        help="Path to manifest.json (default: ./manifest.json).",
    )
    args = parser.parse_args()

    with open(args.manifest, encoding="utf-8") as f:
        manifest = json.load(f)

    errors: list[str] = []

    version = manifest.get("version", "")
    if version == PLACEHOLDER_VERSION:
        errors.append(
            f"manifest.version is the placeholder {PLACEHOLDER_VERSION!r}; bump before releasing."
        )

    for name, entry in manifest.get("images", {}).items():
        tag = entry.get("tag", "")
        if PLACEHOLDER_VERSION in tag:
            errors.append(
                f"image {name!r} tag {tag!r} still contains the placeholder {PLACEHOLDER_VERSION!r}."
            )

    if errors:
        for err in errors:
            print(f"::error file={args.manifest}::{err}", file=sys.stderr)
        return 1

    print(f"OK: {args.manifest} is release-ready (version={version}).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
