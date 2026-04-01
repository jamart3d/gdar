---
description: Minimal zero-friction host and command preflight for GDAR workflows.
---
# Toolchain Preflight

Use this at the start of any workflow that depends on Flutter, Dart, Git, or Firebase.

When invoked from an authorized Zero-Friction workflow, this preflight
inherits the parent workflow's approval automatically.

## Usage

Run the unified preflight script:

```
dart scripts/preflight_check.dart          # checkup, verify
dart scripts/preflight_check.dart --release # shipit, deploy (adds firebase check)
```

The script handles:
- Host detection (`WINDOWS_10` or `CHROMEBOOK`).
- Toolchain verification (`git`, `dart`, `flutter`, optionally `firebase`).
- Process hygiene (hung flutter/dart detection).
- Smart-skip melos verification (SHA comparison + suite run if stale).
- `verification_status.json` update on success.

## Output

| Output | Meaning |
|---|---|
| `WINDOWS_10:VERIFIED` | All clear — proceed with the parent workflow. |
| `CHROMEBOOK:STOP` | Health suite ran but builds/deploy must run on Windows. |
| Exit code 1 | Toolchain missing or melos suite failed — abort. |

## Scope Limit

This preflight does NOT run `melos run fix`, design scans, or builds.
Those belong in the parent workflow (`/checkup`, `/shipit`).
