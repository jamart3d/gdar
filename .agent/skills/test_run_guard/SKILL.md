---
name: test_run_guard
description: >
  Prevents Antigravity from getting stuck waiting on background flutter/dart
  test commands that have silently completed or hung. Enforces the correct
  MCP tool, defines strict polling limits, specifies bail-out behavior, and
  maps deprecated `flutter pub run` commands to their modern equivalents.
---

# Skill: Test Run Guard

## Purpose

`flutter test` and `dart test` background commands frequently hang, silently
complete without signaling, or stall on compile steps. This skill defines the
MANDATORY protocol Antigravity MUST follow every time tests are run.

---

## Rule 1 — Always Use the MCP Test Runner

> ❌ NEVER use `run_command` with `flutter test` or `dart test` as a
> background command.
>
> ✅ ALWAYS use `mcp_dart-mcp-server_run_tests` instead.

The MCP `run_tests` tool is purpose-built for agent use. It:
- Streams output natively without polling
- Signals completion reliably
- Returns structured pass/fail results
- Does NOT hang waiting for device connections

### Correct Usage

```
Use: mcp_dart-mcp-server_run_tests
  roots: [{ root: "file:///c:/Users/jeff/StudioProjects/gdar" }]
  testRunnerArgs: { name: ["test_name_substring"] }  # optional filter
```

---

## Rule 2 — If `run_command` Was Already Started (Recovery Protocol)

If a `flutter test` or `dart test` command was run via `run_command` and
Antigravity is now polling `command_status` waiting for it:

### Step 1 — Short Poll First
Call `command_status` with `WaitDurationSeconds: 30` and `OutputCharacterCount: 3000`.

### Step 2 — Check for Stuck Condition
After each poll, check:
- Is the `status` still `"running"`?
- Has the output changed since the last poll?

If **status is running AND output has NOT changed** across **2 consecutive polls**
→ The command is **stuck**. Proceed to the bail-out.

### Step 3 — Bail-Out Protocol
Do NOT wait indefinitely. After hitting the stuck condition OR after a total
of **3 polls with no completion**, do the following:

1. **Read** the existing output immediately using `OutputCharacterCount: 8000`.
2. **Parse** what is there — look for `pass`, `fail`, `error`, test counts.
3. **Terminate** the command using `send_command_input` with `Terminate: true`.
4. **Report** to the user what was captured, clearly labeling it as
   a partial/interrupted result.
5. **Suggest** re-running using `mcp_dart-mcp-server_run_tests` instead.

### Maximum Total Wait Time
Never wait more than **3 minutes total** (180 seconds) on any single test
command via `run_command`. After that, always bail out.

---

## Rule 3 — Stuck Detection Heuristics

Treat a test command as hung if ANY of these are true:

| Signal | Meaning |
|---|---|
| Output ends with `"Compiling..."` and hasn't changed in 60s | Stuck on build step |
| Output ends with `"connecting to device"` | Device not found / emulator issue |
| Output is empty after 60s | Silent hang |
| Last lines repeat identically across 2 polls | Spinner stuck |
| Status is `"running"` after 3+ minutes | Hard timeout |

---

## Rule 4 — Reporting After Bail-Out

When bailing out, always give the user this structured summary:

```
⚠️ Test command did not complete cleanly.
  Status    : [running / timed out / stuck]
  Ran for   : [N] minutes
  Last output captured:
    [paste last 10–20 lines of output]

  Recommended next step:
    Re-run using the MCP test runner for reliable results.
```

---

## Rule 5 — Prevention Checklist (Before Running Any Test)

Before triggering any test run, verify:

- [ ] Using `mcp_dart-mcp-server_run_tests` (not `run_command`)
- [ ] No emulator/device dependency for pure unit tests
- [ ] Test file path is correct and exists
- [ ] `dart analyze` shows 0 errors (don't run tests into a broken build)

---

## Rule 6 — `flutter pub run` Is Deprecated. Use the Right Tool.

When you see output like:
```
Deprecated. Use `dart run` instead.
```
it means `flutter pub run <package>` was used. This MUST be replaced.

### Command Reference Table

| ❌ Deprecated | ✅ Correct | MCP? |
|---|---|---|
| `flutter pub run build_runner build` | `dart run build_runner build` | ❌ Use `run_command` |
| `flutter pub run build_runner build --delete-conflicting-outputs` | `dart run build_runner build --delete-conflicting-outputs` | ❌ Use `run_command` |
| `flutter pub run build_runner watch` | `dart run build_runner watch` | ❌ Use `run_command` |
| `flutter pub run mockito` | `dart run mockito` | ❌ Use `run_command` |
| `flutter pub get` | `mcp_dart-mcp-server_pub get` | ✅ MCP |
| `flutter pub add <pkg>` | `mcp_dart-mcp-server_pub add <pkg>` | ✅ MCP |
| `flutter pub upgrade` | `mcp_dart-mcp-server_pub upgrade` | ✅ MCP |
| `flutter pub outdated` | `mcp_dart-mcp-server_pub outdated` | ✅ MCP |

### Most Common Case — build_runner

The most frequent use in this project is code generation. Always run it as:

```powershell
dart run build_runner build --delete-conflicting-outputs
```

This is safe to run via `run_command` with a generous `WaitMsBeforeAsync`
(e.g. `120000` ms) since build_runner can take time on large projects.
Poll with `command_status` at 30s intervals and read output when done.

### Summary Rule
> ❌ Never prefix with `flutter pub run`
> ✅ For pub lifecycle → use `mcp_dart-mcp-server_pub`
> ✅ For code execution → use `dart run <package>`
