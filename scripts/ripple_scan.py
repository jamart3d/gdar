#!/usr/bin/env python3
"""
ripple_scan.py — GDAR Dependency Ripple Detector
=================================================
Runs `dart analyze`, parses the output, and produces a structured JSON
report identifying the epicenter, impacted files, error count, and severity.

Usage:
    python tools/ripple_scan.py
    python tools/ripple_scan.py --json          # raw JSON only (for piping)
    python tools/ripple_scan.py --threshold 5   # override medium threshold
"""

import argparse
import json
import os
import re
import subprocess
import sys
from collections import defaultdict
from datetime import datetime

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
SEVERITY_THRESHOLDS = {
    "low": 5,        # < 5 impacted files
    "medium": 15,    # < 15
    "high": 30,      # < 30
    "critical": 30,  # >= 30
}

# High-risk core files whose changes most commonly cause ripples
HIGH_RISK_PATHS = [
    "packages/shakedown_core/lib/providers/",
    "packages/shakedown_core/lib/services/",
    "packages/shakedown_core/lib/models/",
    "apps/gdar_web/lib/main.dart",
    "apps/gdar_mobile/lib/main.dart",
]

# Layer order for grouping the scope map
LAYER_PATTERNS = [
    ("Core Models",    r"packages[/\\]shakedown_core[/\\]lib[/\\]models[/\\]"),
    ("Core Services",  r"packages[/\\]shakedown_core[/\\]lib[/\\]services[/\\]"),
    ("Core Providers", r"packages[/\\]shakedown_core[/\\]lib[/\\]providers[/\\]"),
    ("App Logic",      r"apps[/\\][^/\\]+[/\\]lib[/\\]"),
    ("Packages",       r"packages[/\\][^/\\]+[/\\]lib[/\\]"),
    ("Tests",          r"test[/\\]|.*_test\.dart"),
    ("Other",          r".*"),
]

# ---------------------------------------------------------------------------
# Dart analyze runner
# ---------------------------------------------------------------------------
def run_dart_analyze() -> list[str]:
    """Run dart analyze and return output lines."""
    print("⏳ Running dart analyze...", file=sys.stderr)
    try:
        result = subprocess.run(
            "dart analyze --format=machine",
            shell=True,
            capture_output=True,
            text=True,
            cwd=os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        )
        lines = (result.stdout + result.stderr).splitlines()
        return lines
    except FileNotFoundError:
        print("❌ ERROR: 'dart' not found in PATH.", file=sys.stderr)
        sys.exit(1)


# ---------------------------------------------------------------------------
# Parser — machine format: SEVERITY|TYPE|FILE|LINE|COL|MESSAGE
# ---------------------------------------------------------------------------
def parse_machine_output(lines: list[str]) -> list[dict]:
    issues = []
    machine_re = re.compile(
        r"^(ERROR|WARNING|INFO|LINT)\|(\w+)\|(.+?)\|(\d+)\|(\d+)\|(.+)$"
    )
    # Also try the human-readable format as fallback
    human_re = re.compile(
        r"^\s*(error|warning|info|lint)\s*[•·]\s*(.+?)\s*[•·]\s*(.+):(\d+):(\d+)"
    )

    for line in lines:
        m = machine_re.match(line)
        if m:
            severity, error_type, filepath, lineno, col, message = m.groups()
            issues.append({
                "severity": severity.lower(),
                "type": error_type,
                "file": filepath.replace("\\", "/"),
                "line": int(lineno),
                "col": int(col),
                "message": message.strip(),
            })
            continue
        m = human_re.match(line)
        if m:
            severity, message, filepath, lineno, col = m.groups()
            issues.append({
                "severity": severity.lower(),
                "type": "unknown",
                "file": filepath.strip().replace("\\", "/"),
                "line": int(lineno),
                "col": int(col),
                "message": message.strip(),
            })

    return issues


# ---------------------------------------------------------------------------
# Analysis
# ---------------------------------------------------------------------------
def analyze_issues(issues: list[dict]) -> dict:
    errors_only = [i for i in issues if i["severity"] == "error"]

    # Count errors per file
    file_error_counts: dict[str, int] = defaultdict(int)
    for issue in errors_only:
        file_error_counts[issue["file"]] += 1

    impacted_files = list(file_error_counts.keys())
    num_impacted = len(impacted_files)

    # Find epicenter: the file with the most errors, skipping test files
    core_files = {
        f: c for f, c in file_error_counts.items()
        if not f.startswith("test/") and not f.startswith("test\\")
    }
    epicenter = max(core_files, key=core_files.get) if core_files else (
        max(file_error_counts, key=file_error_counts.get) if file_error_counts else None
    )

    # Check if epicenter is a high-risk file
    is_core_epicenter = any(
        epicenter and (hr in epicenter) for hr in HIGH_RISK_PATHS
    )

    # Group by ripple class (error type)
    ripple_classes: dict[str, int] = defaultdict(int)
    for issue in errors_only:
        ripple_classes[issue["type"]] += 1

    # Severity
    if num_impacted < SEVERITY_THRESHOLDS["low"]:
        severity = "low"
    elif num_impacted < SEVERITY_THRESHOLDS["medium"]:
        severity = "medium"
    elif num_impacted < SEVERITY_THRESHOLDS["high"]:
        severity = "high"
    else:
        severity = "critical"

    # Scope map — group impacted files by layer
    scope_map: dict[str, list[str]] = defaultdict(list)
    for f in impacted_files:
        for layer_name, pattern in LAYER_PATTERNS:
            if re.search(pattern, f):
                scope_map[layer_name].append(f)
                break

    return {
        "timestamp": datetime.now().isoformat(timespec="seconds"),
        "epicenter": epicenter,
        "is_core_epicenter": is_core_epicenter,
        "impacted_files": impacted_files,
        "impacted_file_count": num_impacted,
        "error_count": len(errors_only),
        "warning_count": len([i for i in issues if i["severity"] == "warning"]),
        "ripple_classes": dict(ripple_classes),
        "severity": severity,
        "scope_map": {k: v for k, v in scope_map.items()},
        "all_issues": errors_only,
    }


# ---------------------------------------------------------------------------
# Pretty printer
# ---------------------------------------------------------------------------
SEVERITY_ICON = {
    "low": "✅",
    "medium": "⚠️ ",
    "high": "🔴",
    "critical": "🚨",
}

MODEL_ADVICE = {
    "low":      "✅ Stay on Gemini 3 Flash. Fix errors one file at a time.",
    "medium":   "⚠️  Switch to Gemini 3.1 Pro (Low). Run `dart fix --apply` as a first pass.",
    "high":     "🔴 Switch to Gemini 3.1 Pro (High). Fix the epicenter file before touching consumers.",
    "critical": "🚨 Switch to Claude Opus 4.6 (Thinking) IMMEDIATELY. Do NOT continue editing until switched.",
}


def pretty_print(report: dict) -> None:
    sev = report["severity"]
    icon = SEVERITY_ICON.get(sev, "❓")

    print("\n" + "=" * 60)
    print(f"  🌊 GDAR RIPPLE SCAN — {report['timestamp']}")
    print("=" * 60)
    print(f"  Severity : {icon} {sev.upper()}")
    print(f"  Epicenter: {report['epicenter'] or 'Unknown'}")
    print(f"  Errors   : {report['error_count']}")
    print(f"  Warnings : {report['warning_count']}")
    print(f"  Impacted : {report['impacted_file_count']} files")
    print()

    if report["ripple_classes"]:
        print("  Error Types:")
        for etype, count in sorted(report["ripple_classes"].items(), key=lambda x: -x[1]):
            print(f"    {count:>4}x  {etype}")
        print()

    if report["scope_map"]:
        print("  Scope Map (by layer):")
        for layer, files in report["scope_map"].items():
            print(f"    [{layer}]")
            for f in sorted(files):
                print(f"      • {f}")
        print()

    print(f"  🤖 Model Advice: {MODEL_ADVICE[sev]}")
    print("=" * 60 + "\n")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(description="GDAR Ripple Detector")
    parser.add_argument("--json", action="store_true", help="Output raw JSON only")
    parser.add_argument(
        "--threshold", type=int, default=None,
        help="Override the 'medium' severity threshold (default: 5)"
    )
    args = parser.parse_args()

    if args.threshold:
        SEVERITY_THRESHOLDS["low"] = args.threshold

    lines = run_dart_analyze()
    issues = parse_machine_output(lines)
    report = analyze_issues(issues)

    if args.json:
        print(json.dumps(report, indent=2))
    else:
        pretty_print(report)
        # Also write JSON to stderr for piping
        print(json.dumps(report, indent=2), file=sys.stderr)


if __name__ == "__main__":
    main()
