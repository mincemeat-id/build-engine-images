#!/usr/bin/env python3
"""Script to enforce the CVE budget policy on Trivy scan reports."""

import argparse
import json
import os
import sys
from datetime import datetime


def load_exceptions(exceptions_path: str) -> set[str]:
    """Load ignored CVE IDs from the exceptions file."""
    ignored_cves = set()
    if not os.path.exists(exceptions_path):
        return ignored_cves

    try:
        with open(exceptions_path, encoding="utf-8") as f:
            data = json.load(f)
            exceptions = data.get("exceptions", [])
            for exc in exceptions:
                cve = exc.get("cve")
                expiry_str = exc.get("expiry")
                if cve:
                    # Check expiry if present
                    if expiry_str:
                        try:
                            expiry_date = datetime.strptime(expiry_str, "%Y-%m-%d").date()
                            if expiry_date < datetime.now().date():
                                print(f"Warning: Exception for {cve} has expired on {expiry_str}. Enforcing.")
                                continue
                        except ValueError:
                            print(f"Warning: Invalid expiry date format for {cve}: {expiry_str}. Expected YYYY-MM-DD.")
                    ignored_cves.add(cve)
    except Exception as e:
        print(f"Warning: Failed to load exceptions file {exceptions_path}: {e}", file=sys.stderr)

    return ignored_cves


def main() -> None:
    parser = argparse.ArgumentParser(description="Enforce CVE budget on a Trivy JSON report.")
    parser.add_argument(
        "--report",
        required=True,
        help="Path to the Trivy JSON report file.",
    )
    parser.add_argument(
        "--exceptions",
        default="security-exceptions.json",
        help="Path to the security exceptions JSON file.",
    )
    args = parser.parse_args()

    ignored_cves = load_exceptions(args.exceptions)

    try:
        with open(args.report, encoding="utf-8") as f:
            report = json.load(f)
    except FileNotFoundError:
        print(f"Error: Report file not found at {args.report}", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error: Failed to parse report file {args.report} as JSON: {e}", file=sys.stderr)
        sys.exit(1)

    results = report.get("Results", [])
    if not results:
        print("No scan results found in report. CVE budget passed.")
        sys.exit(0)

    critical_with_fix = []
    high_with_fix = []
    high_without_fix = []
    medium_with_fix = []
    ignored_count = 0

    for result in results:
        target = result.get("Target", "Unknown")
        vulnerabilities = result.get("Vulnerabilities", [])
        for vuln in vulnerabilities:
            cve_id = vuln.get("VulnerabilityID", "Unknown")
            severity = vuln.get("Severity", "").upper()
            pkg_name = vuln.get("PkgName", "Unknown")
            installed_version = vuln.get("InstalledVersion", "Unknown")
            fixed_version = vuln.get("FixedVersion", "")
            has_fix = bool(fixed_version)

            if cve_id in ignored_cves:
                ignored_count += 1
                continue

            vuln_info = {
                "id": cve_id,
                "pkg": pkg_name,
                "installed": installed_version,
                "fixed": fixed_version,
                "target": target,
            }

            if severity == "CRITICAL":
                if has_fix:
                    critical_with_fix.append(vuln_info)
            elif severity == "HIGH":
                if has_fix:
                    high_with_fix.append(vuln_info)
                else:
                    high_without_fix.append(vuln_info)
            elif severity == "MEDIUM":
                if has_fix:
                    medium_with_fix.append(vuln_info)

    # Print summary
    print("=== CVE Budget Scan Summary ===")
    print(f"Critical with fix: {len(critical_with_fix)}")
    print(f"High with fix:     {len(high_with_fix)}")
    print(f"High without fix:  {len(high_without_fix)}")
    print(f"Medium with fix:   {len(medium_with_fix)}")
    print(f"Ignored by policy: {ignored_count}")
    print("===============================")

    failed = False

    if critical_with_fix:
        print("\n[FAIL] Critical vulnerabilities with fixes found (BLOCKING PUBLISH):", file=sys.stderr)
        for v in critical_with_fix:
            print(f"  - {v['id']} in {v['pkg']} (installed: {v['installed']}, fixed: {v['fixed']}) in {v['target']}", file=sys.stderr)
        failed = True

    if len(high_with_fix) > 5:
        print(f"\n[FAIL] Found {len(high_with_fix)} High vulnerabilities with fixes, which is more than the allowed budget of 5 (BLOCKING PUBLISH):", file=sys.stderr)
        for v in high_with_fix:
            print(f"  - {v['id']} in {v['pkg']} (installed: {v['installed']}, fixed: {v['fixed']}) in {v['target']}", file=sys.stderr)
        failed = True
    elif high_with_fix:
        print(f"\n[WARN] High vulnerabilities with fixes found (within budget of 5):")
        for v in high_with_fix:
            print(f"  - {v['id']} in {v['pkg']} (installed: {v['installed']}, fixed: {v['fixed']}) in {v['target']}")

    if high_without_fix:
        print("\n[INFO] High vulnerabilities without fixes (Requires maintainer acknowledgement in release notes):")
        for v in high_without_fix:
            print(f"  - {v['id']} in {v['pkg']} (installed: {v['installed']}) in {v['target']}")

    if medium_with_fix:
        print("\n[WARN] Medium vulnerabilities with fixes:")
        for v in medium_with_fix:
            print(f"  - {v['id']} in {v['pkg']} (installed: {v['installed']}, fixed: {v['fixed']}) in {v['target']}")

    if failed:
        sys.exit(1)

    print("\nCVE budget check passed.")
    sys.exit(0)


if __name__ == "__main__":
    main()
