# Unify App Orchestration Phase 2A Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the inline provider graph in web with the shared provider builder while preserving existing web-only behavior and current deep-link behavior.

**Architecture:** Web adopts the shared provider builder only. Web keeps app-local startup code, URL-driven theme selection, and Fruit-vs-Android shell branching in `apps/gdar_web/lib/main.dart`.

**Tech Stack:** Flutter, Dart, Provider, package imports from `shakedown_core`

---

## Dependencies

- Requires `docs/superpowers/plans/2026-04-25-unify-app-orchestration-phase-1a-provider-graph.md` to be complete first.

## Scope

### Write Scope
- Modify: `apps/gdar_web/lib/main.dart`

### Invariants
- Do not add web automation parity
- Preserve current `_handleDeepLink` behavior
- Preserve URL-based theme override logic
- Preserve Fruit-vs-Android shell logic

## Task 1: Swap Web to the Shared Provider Builder

**Files:**
- Modify: `apps/gdar_web/lib/main.dart`

- [ ] **Step 1: Replace the inline provider list with the shared builder**

```dart
return MultiProvider(
  providers: buildGdarAppProviders(
    prefs: widget.prefs,
    isTv: _isTv,
    overrides: GdarAppProviderOverrides(
      settingsProvider: _settingsProvider,
      showListProvider: _showListProvider,
    ),
  ),
  child: Consumer2<ThemeProvider, SettingsProvider>(
    builder: (context, themeProvider, settingsProvider, child) {
      // Keep the existing Fruit/Android shell logic here.
    },
  ),
);
```

- [ ] **Step 2: Add required imports and remove no-longer-needed provider setup imports**

Run: `dart analyze apps/gdar_web/lib/main.dart`
Expected: PASS

## Task 2: Verify Web Behavior Is Unchanged

- [ ] **Step 1: Run focused analysis**

Run: `flutter analyze apps/gdar_web`
Expected: PASS

- [ ] **Step 2: Commit**

```bash
git add apps/gdar_web/lib/main.dart
git commit -m "refactor: use shared provider graph in web app"
```

## Handoff

Save results to:
- `reports/2026-04-25_worker_c_web_integration_handoff.md`
