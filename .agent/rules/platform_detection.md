---
description: How to detect the current dev machine (Windows 10 vs Chromebook) and set concurrency limits for build and test commands.
---
# Platform Detection

Use this rule at the start of any workflow that runs builds, tests, or deployments.

When this rule is invoked by an authorized Zero-Friction workflow such as `/checkup`, `/shipit`, or `/deploy`, host detection and concurrency resolution inherit the parent workflow's approval automatically and must not trigger any separate confirmation prompt.

## 1. Detect the Host

For GDAR workflow purposes, there are only two supported host classes:
- `WINDOWS_10`
- `CHROMEBOOK`

Use a conservative rule:
- If Windows is positively detected, classify as `WINDOWS_10`.
- Otherwise, fail closed to `CHROMEBOOK`.
- Never assume a generic Linux desktop for this repo's workflow decisions.

### PowerShell / cmd

Run:

```powershell
if ($env:OS -eq 'Windows_NT') { 'WINDOWS_10' } else { 'CHROMEBOOK' }
```

Expected result in the normal Windows 10 environment:

```text
WINDOWS_10
```

### Bash

Run:

```bash
if uname -s 2>/dev/null | grep -qiE 'mingw|msys|cygwin'; then
  echo WINDOWS_10
elif [ -f /dev/.cros_milestone ] || \
     grep -qiE 'penguin|cros|chromeos' /etc/hostname /proc/version /proc/sys/kernel/osrelease 2>/dev/null; then
  echo CHROMEBOOK
else
  echo CHROMEBOOK
fi
```

Expected result in the normal Chromebook/Crostini environment:

```text
CHROMEBOOK
```

## 2. Resolve Concurrency (`$MELOS_CAN_HANDLE`)

`$MELOS_CAN_HANDLE` is an integer set in the shell profile that signals available parallelism for Melos tasks (not Flutter builds - those are always sequential).

| Machine | Expected value | Fallback if unset |
|---|---|---|
| Windows 10 (16-core) | `8` | `4` |
| Chromebook (Crostini) | `2` | `1` |

Read it with:

```bash
echo "${MELOS_CAN_HANDLE:-unset}"   # Bash
$env:MELOS_CAN_HANDLE               # PowerShell
```

If unset, use the fallback for the detected host class.

## 3. Per-Platform Constraints

| Capability | Windows 10 | Chromebook |
|---|---|---|
| `flutter build appbundle` | YES | NO - OOM risk |
| `flutter build web` | YES | NO - OOM risk |
| `firebase deploy` | YES | NO |
| `melos run test/analyze/format/fix` | YES | YES |
| `dart run scripts/*.dart` | YES | YES |
| Parallel `flutter build` calls | NEVER | NEVER |

> [!CAUTION]
> `flutter build` is always sequential regardless of machine. It maximizes all available threads internally - never run two builds concurrently.

## 4. Workflow Decision Tree

```text
Detect host
|-- CHROMEBOOK
|   |-- Run: fix, format, analyze, test (melos)
|   `-- STOP - do not attempt flutter build or firebase deploy
|       Notify user: "Build/deploy steps must run on Windows 10."
`-- WINDOWS_10
    |-- Run: fix, format, analyze, test (melos)
    `-- Run: flutter build (sequential) -> firebase deploy -> git finalization
```
