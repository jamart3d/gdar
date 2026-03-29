---
description: How to detect the current dev machine (Windows 10 vs Chromebook/Linux) and set concurrency limits for build and test commands.
---
# Platform Detection

Use this rule at the start of any workflow that runs builds, tests, or deployments.

## 1. Detect the OS

Run the following and inspect the output:

```bash
uname -s 2>/dev/null || echo "Windows_NT"
```

| Output | Machine | Shell |
|---|---|---|
| `Linux` | Chromebook (Crostini) | Bash |
| `Windows_NT` (or command not found) | Windows 10 dev machine | PowerShell / cmd |

On Windows you can also confirm with `echo $env:OS` in PowerShell — it returns `Windows_NT`.

## 2. Resolve Concurrency (`$MELOS_CAN_HANDLE`)

`$MELOS_CAN_HANDLE` is an integer set in the shell profile that signals available parallelism for Melos tasks (NOT Flutter builds — those are always sequential).

| Machine | Expected value | Fallback if unset |
|---|---|---|
| Windows 10 (16-core) | `8` | `4` |
| Chromebook (Crostini) | `2` | `1` |

Read it with:
```bash
echo "${MELOS_CAN_HANDLE:-unset}"   # Bash
$env:MELOS_CAN_HANDLE               # PowerShell
```

If unset, use the fallback for the detected OS.

## 3. Per-Platform Constraints

| Capability | Windows 10 | Chromebook |
|---|---|---|
| `flutter build appbundle` | YES | NO — OOM risk |
| `flutter build web` | YES | NO — OOM risk |
| `firebase deploy` | YES | NO |
| `melos run test/analyze/format/fix` | YES | YES |
| `dart run scripts/*.dart` | YES | YES |
| Parallel `flutter build` calls | NEVER | NEVER |

> [!CAUTION]
> `flutter build` is always sequential regardless of machine. It maximizes all available threads internally — never run two builds concurrently.

## 4. Workflow Decision Tree

```
Detect OS
├── Linux (Chromebook)
│   ├── Run: fix, format, analyze, test (melos)
│   └── STOP — do not attempt flutter build or firebase deploy
│       Notify user: "Build/deploy steps must run on Windows."
└── Windows 10
    ├── Run: fix, format, analyze, test (melos)
    └── Run: flutter build (sequential) → firebase deploy → git finalization
```
