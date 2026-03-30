---
description: Minimal zero-friction host and command preflight for GDAR workflows.
---
# Toolchain Preflight

Use this at the start of any workflow that depends on Flutter, Dart, Git, or Firebase. Keep it small and fail fast.

When invoked from an authorized Zero-Friction workflow such as `/checkup`, `/shipit`, or `/deploy`, this preflight inherits the parent workflow's approval and must not trigger a separate confirmation prompt.

## Goal

Detect the supported host class and verify that the required top-level commands are available before a larger workflow begins.

This preflight should take only a few seconds. It is not a substitute for `/checkup`.

This preflight is read-only. It must not kill processes, clean files, mutate git state, or combine unrelated startup steps into one chained shell command.

## 1. Detect Host

Follow `.agent/rules/platform_detection.md` and resolve one of:
- `WINDOWS_10`
- `CHROMEBOOK`

### Unified Detection (Zero-Friction)

Run this single, whitelisted command on both platforms:

```bash
dart scripts/detect_platform.dart
```

## 2. Resolve Required Commands

Use shell-native command lookup before running the real workflow steps.

### PowerShell

```powershell
Get-Command git,dart,flutter
```

For release workflows also verify:

```powershell
Get-Command firebase
```

### Bash

```bash
command -v git dart flutter
```

For release workflows also verify:

```bash
command -v firebase
```

## 3. Silent Syntax Verification

Before the first use of primary orchestration tools in a session, silently verify CLI signatures.

### Core

```powershell
dart --version
flutter --help > $null
```

### Release-only

```powershell
firebase --help > $null
```

On Bash, use the equivalent non-interactive help/version calls.

## 4. Fail-Fast Rules

- If `git`, `dart`, or `flutter` cannot be resolved, abort the parent workflow immediately.
- If `firebase` cannot be resolved during a release workflow, abort the parent workflow immediately.
- If the host is not positively detected as `WINDOWS_10`, treat it as `CHROMEBOOK`.
- Do not continue into `checkup`, `shipit`, or `deploy` with a missing command and hope PATH resolves later.

## 5. Parent Workflow Inputs

Use this command matrix:

| Workflow | Required commands |
|---|---|
| `checkup` | `git`, `dart`, `flutter` |
| `verify` | `git`, `dart`, `flutter` |
| `shipit` | `git`, `dart`, `flutter`, `firebase` |
| `deploy` | `git`, `dart`, `flutter`, `firebase` |

## 6. Scope Limit

Do not expand this into a heavy environment audit. No `flutter doctor`, no package restore, no builds, no tests.

## 7. Forbidden Startup Shape

Do not start a parent workflow with a combined command like:

```powershell
$env:MELOS_CAN_HANDLE ; Get-Process flutter,dart,melos -ErrorAction SilentlyContinue | Stop-Process -Force ; git status --porcelain ; git rev-parse HEAD
```

Why this is forbidden:
- it mixes read-only preflight with destructive process cleanup
- it violates the no-black-box workflow rule
- `Stop-Process -Force` is what most often triggers an approval/confirmation boundary
- it kills processes before proving they are stale

Use separate steps instead:
1. detect host
2. resolve commands
3. verify tool syntax/version silently
4. run `git status --porcelain`
5. run `git rev-parse HEAD`
6. only then let `.agent/rules/process_hygiene.md` inspect running `flutter`/`dart` processes in a separate step if needed
