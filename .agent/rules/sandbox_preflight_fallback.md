---
description: Fallback policy for sandbox-stalled preflight commands.
---
# Sandbox Preflight Fallback

Scope note: This is a Codex sandbox execution workaround. Do not treat it as a
global requirement for other agent runtimes or normal local terminal usage.

Apply this rule when running:

- `dart scripts/preflight_check.dart --preflight-only`
- `dart scripts/preflight_check.dart --help`

## 1. Default Execution Policy

Run these commands unsandboxed first.

Do not run a sandbox probe first for these two commands.

## 2. Timeout Policy

- Unsandboxed timeout: 10 seconds.
- On timeout: stop immediately and report a one-line status.
- Do not loop or retry automatically.

## 3. Optional Sandbox Retest

Only retest sandbox for these commands if explicitly requested by the user.

If explicitly requested:
- run one sandbox attempt with a 5-second timeout
- if it times out or produces no output, return to unsandboxed-first policy

## 4. Process Hygiene Guard

After interrupt/timeouts, check for stale `dart`, `dartvm`, and
`flutter_tester` processes and clear stale entries older than 60 minutes when
safe.
