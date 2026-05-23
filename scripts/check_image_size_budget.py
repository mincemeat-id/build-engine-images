#!/usr/bin/env python3
"""Enforce committed image size budgets against a structured size record."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

MIB = 1024 * 1024


def load_json(path: Path) -> dict:
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--record", required=True, type=Path, help="image-size-*.json record")
    parser.add_argument(
        "--budgets",
        default=Path("image-size-budgets.json"),
        type=Path,
        help="Path to image-size-budgets.json",
    )
    args = parser.parse_args()

    record = load_json(args.record)
    budgets = load_json(args.budgets)
    image = record.get("image")
    if not image:
        print(f"::error file={args.record}::Size record is missing image", file=sys.stderr)
        return 1

    image_budget = budgets.get("images", {}).get(image)
    if image_budget is None:
        print(f"::error file={args.budgets}::No size budget configured for {image}", file=sys.stderr)
        return 1

    current_bytes = int(record["bytes"])
    current_mib = current_bytes / MIB
    max_mib = float(image_budget["max_mib"])
    baseline_mib = float(image_budget["baseline_ci_mib"])
    max_growth_percent = float(image_budget.get("max_growth_percent", budgets.get("max_growth_percent", 10)))
    growth_limit_mib = baseline_mib * (1 + max_growth_percent / 100)

    failures: list[str] = []
    if current_mib > max_mib:
        failures.append(f"{current_mib:.1f} MiB exceeds max budget {max_mib:.1f} MiB")
    if current_mib > growth_limit_mib:
        failures.append(
            f"{current_mib:.1f} MiB exceeds {max_growth_percent:.1f}% growth limit "
            f"from baseline {baseline_mib:.1f} MiB ({growth_limit_mib:.1f} MiB)"
        )

    if failures:
        for failure in failures:
            print(f"::error file={args.record}::{image}: {failure}", file=sys.stderr)
        return 1

    print(
        f"OK: {image} size {current_mib:.1f} MiB within max {max_mib:.1f} MiB "
        f"and {max_growth_percent:.1f}% growth baseline {baseline_mib:.1f} MiB."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
