---
description: How to detect and handle stale background Flutter/Dart/Melos processes before starting any workflow.
---
# Process Hygiene

Apply this rule at the start of any workflow that runs builds, tests, or deployments.

## 1. Detect Hung Processes

Run the appropriate command for the current platform:

**Windows (PowerShell):**
```powershell
Get-Process | Where-Object { $_.Name -match "flutter|dart" } | Select-Object Id, Name, CPU, StartTime
```

**Linux / Chromebook (Bash):**
```bash
pgrep -a -f "flutter|dart"
```

## 2. What Qualifies as Hung

A process is considered hung if:
- It has been running for **more than 10 minutes** with no associated terminal output, OR
- It is a known slow command (`flutter doctor`, `flutter pub get`, `melos bootstrap`) running for **more than 5 minutes**, OR
- A `.dart_tool/` or `pubspec.lock` file is locked and cannot be written

## 3. How to Handle

| Situation | Action |
|---|---|
| Hung `flutter doctor` | Kill it — it provides no build value and is safe to terminate |
| Hung `flutter pub get` / `melos bootstrap` | Kill it, then re-run once the workflow starts |
| Hung `flutter build` | **Do not kill** — notify the user and wait for confirmation before terminating a build |
| Hung `melos run test` | Kill it — tests will be re-run by the workflow |
| Any process with unsaved output | Capture last stdout/stderr before killing, report to user |

**Windows kill:**
```powershell
Stop-Process -Id <PID> -Force
```

**Linux kill:**
```bash
kill -9 <PID>
```

## 4. Never Proceed Past a Hung Build

If a `flutter build appbundle` or `flutter build web` process is still running:
- **Do not start another build** — this will cause OOM kills and system thrashing.
- Notify the user: "A Flutter build process (PID: X) has been running for Y minutes. Confirm termination before proceeding."
- Wait for explicit user confirmation.

## 5. After Killing

- Re-run `git status --porcelain` — a hung process may have left lock files or partial writes that appear as dirty changes.
- If lock files appear (e.g., `.dart_tool/package_config.json` partially written), run `melos run clean` before proceeding.
 
## 6. After Any Interrupt Or Uncertain Command State

If a command was interrupted, timed out, or the agent lost track of whether it finished:
- Treat the prior command state as **unknown** until re-verified.
- Check both the process table and the terminal output before saying a command is "still running" or "finished".
- If no matching process exists, do **not** describe the command as active.
- If the terminal already shows a final success or failure line, report that result instead of waiting again.
- Before re-running a command, explicitly confirm the previous run is no longer active.

## 7. Completion Detection Is Mandatory

When waiting on any long-running command:
- Do **not** wait indefinitely just because a tool call has not returned yet.
- Actively verify whether the command has already finished by checking for:
  - process exit,
  - a returned shell prompt,
  - terminal lines that show final success or failure.
- If those signals indicate completion, stop waiting immediately and report the result.
- If completion cannot be proven after a reasonable interval, say the status is **uncertain** rather than claiming the command is still running.
- Never keep the user blocked in a passive wait loop when completion may already have happened.
