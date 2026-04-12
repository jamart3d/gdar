---
description: Minimal zero-friction host and command preflight for GDAR workflows.
---
# Toolchain Preflight Rule

Use this at the start of any workflow that depends on Flutter, Dart, Git, or Firebase.

When invoked from an authorized Zero-Friction workflow, this preflight
inherits the parent workflow's approval automatically.

## Usage

Run the unified preflight script:

``` 
dart scripts/preflight_check.dart --preflight-only # validate
dart scripts/preflight_check.dart          # verify
dart scripts/preflight_check.dart --release # publish, deploy (adds firebase check)
dart scripts/preflight_check.dart --record-pass # refresh receipt after /validate
```

The script handles:
- Host detection (`WINDOWS_10` or `CHROMEBOOK`).
- Toolchain verification (`git`, `dart`, `flutter`, optionally `firebase`).
- Process hygiene (hung flutter/dart detection).
- Smart-skip melos verification (SHA comparison + suite run if stale) unless `--preflight-only` is used.
- `verification_status.json` update on success unless `--preflight-only` is used.
- Fast receipt refresh for `/validate` via `--record-pass`, which writes a fresh
  `PASS` receipt without rerunning the full preflight or melos suite.

For `--preflight-only` or `--help`, follow unsandboxed-first execution policy in:
`.agent/rules/sandbox_preflight_fallback.md`.

## Output

| Output | Meaning |
|---|---|
| `WINDOWS_10:VERIFIED` or `LINUX:VERIFIED` | All clear — proceed with the parent workflow. |
| `RECORD_PASS:VERIFIED` | Fresh `PASS` receipt written successfully for the current `HEAD`. |
| `CHROMEBOOK:STOP` | Health suite ran but builds/deploy must run on Windows. |
| Exit code 1 | Toolchain missing or melos suite failed — abort. |

## Scope Limit

This preflight does NOT run `melos run fix`, design scans, or builds.
Those belong in the parent workflow (`/validate`, `/publish`).
