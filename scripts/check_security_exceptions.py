#!/usr/bin/env python3
"""Stage 0 Quick Win: warn (and optionally fail) if security-exceptions.json
contains only example/expired entries.

The goal is to make sure that the CVE-budget bypass ledger never silently
ships an "example" or stale exception that would unintentionally suppress
real Trivy findings. The script always succeeds with exit 0 for the
default ``--mode warn`` so it can be wired into CI as a non-blocking
check. Use ``--mode error`` from release workflows to fail hard.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime

EXAMPLE_PATTERN = re.compile(r"(?i)(example|placeholder|do[- ]?not[- ]?use|sample)")


def load_exceptions(path: str) -> list[dict]:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    return data.get("exceptions", [])


def classify(exception: dict) -> str | None:
    """Return a reason string if the exception is example/expired, else None."""
    cve = str(exception.get("cve", ""))
    reason = str(exception.get("reason", ""))
    if EXAMPLE_PATTERN.search(cve) or EXAMPLE_PATTERN.search(reason):
        return f"placeholder/example entry: {cve!r}"

    expiry_str = exception.get("expiry")
    if expiry_str:
        try:
            expiry = datetime.strptime(expiry_str, "%Y-%m-%d").date()
        except ValueError:
            return f"invalid expiry date {expiry_str!r} on {cve!r}"
        if expiry < datetime.utcnow().date():
            return f"expired entry: {cve!r} (expired {expiry_str})"
    return None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--file",
        default="security-exceptions.json",
        help="Path to security-exceptions.json (default: ./security-exceptions.json).",
    )
    parser.add_argument(
        "--mode",
        choices=("warn", "error"),
        default="warn",
        help="warn = print a notice but exit 0; error = exit 1 if the ledger contains only example/expired entries.",
    )
    args = parser.parse_args()

    try:
        exceptions = load_exceptions(args.file)
    except FileNotFoundError:
        print(f"::error file={args.file}::Security exceptions file not found.", file=sys.stderr)
        return 1
    except json.JSONDecodeError as exc:
        print(f"::error file={args.file}::Invalid JSON: {exc}", file=sys.stderr)
        return 1

    if not exceptions:
        print(f"OK: {args.file} contains no exceptions.")
        return 0

    bad: list[str] = []
    good: list[str] = []
    for entry in exceptions:
        reason = classify(entry)
        if reason:
            bad.append(reason)
        else:
            good.append(str(entry.get("cve", "<unknown>")))

    for reason in bad:
        print(f"::warning file={args.file}::{reason}")

    if good:
        print(f"OK: {len(good)} active exception(s): {', '.join(good)}")
        return 0

    msg = (
        f"{args.file} contains {len(exceptions)} entr(y/ies) but all are "
        "example/expired. Either remove them or add a real exception."
    )
    if args.mode == "error":
        print(f"::error file={args.file}::{msg}", file=sys.stderr)
        return 1
    print(f"::warning file={args.file}::{msg}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
