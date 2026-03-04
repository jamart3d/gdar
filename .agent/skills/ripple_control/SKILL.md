---
name: ripple_control
description: >
  Detects "dependency ripples" — cascading breakages where a change to a core
  class (Provider, Service, Model) causes downstream failures across many files.
  Triggers a structured Ripple Report, surface actionable fixes, and advises on
  whether the task requires a model upgrade.
---

# Skill: Ripple Control

## When to Activate This Skill

Activate this skill **proactively** whenever any of the following are true:

1. **Analyze spike**: Running `dart analyze` returns **more than 10 errors** in
   a single session after a single logical change (e.g., renaming a method,
   adding a required parameter, changing a return type).
2. **Test cascade**: More than **3 test files** fail simultaneously after a
   single code edit in a non-test file.
3. **Fan-out detected**: A change to one of these "high-risk" core files
   is in scope:
   - Any file in `lib/providers/`
   - Any file in `lib/services/`
   - Any file in `lib/models/`
   - `lib/main.dart`
   - `pubspec.yaml`
4. **User signals**: The user uses language like "everything broke", "cascade",
   "ripple", or "it's spreading".

---

## Phase 1: Detect & Quantify the Ripple

### Step 1 — Run the Ripple Scanner

Run the Python diagnostic tool to gather a structured snapshot:

```powershell
python tools/ripple_scan.py
```

This script will:
- Run `dart analyze` and parse the output.
- Group errors by **source file** (origin) vs. **downstream file** (consumer).
- Count the total number of unique files impacted.
- Identify the most likely **epicenter** (the file with the most downstream errors).
- Output a structured JSON summary to `stdout`.

### Step 2 — Read the Output

Parse the JSON and look for:

| Field             | Meaning                                             |
|-------------------|-----------------------------------------------------|
| `epicenter`       | The file whose change started the ripple            |
| `impacted_files`  | Total downstream files broken                       |
| `error_count`     | Total number of errors                              |
| `ripple_classes`  | Grouped error types (type, missing method, etc.)    |
| `severity`        | `low` / `medium` / `high` / `critical`              |

---

## Phase 2: Generate a Ripple Report Artifact

Once the scanner runs, **always** generate a Ripple Report artifact at:

```
reports/YYYY-MM-DD_HH-MM_ripple_report.md
```

The report must include:

1.  **Ripple Summary Table** — epicenter, severity, impacted file count, error count.
2.  **Scope Map** — a markdown list of all impacted files, grouped by layer
    (Provider → Widget → Test).
3.  **Root Cause Analysis** — what specific change likely triggered the ripple
    (e.g., "Added required param `foo` to `AudioService`").
4.  **Recommended Action Plan** — ordered steps to resolve the ripple surgically.
5.  **Model Recommendation** (see Phase 3).

---

## Phase 3: Model & Strategy Recommendation

Based on severity, apply the following guidance **at the top of the report**
and surface it explicitly to the user:

| Severity   | Impacted Files | Recommended Model                  | Reason                                                              |
|------------|----------------|------------------------------------|---------------------------------------------------------------------|
| `low`      | < 5            | ✅ **Gemini 3 Flash**               | Fast edits, small scope — no change needed.                         |
| `medium`   | 5–15           | ⚠️ **Gemini 3.1 Pro (Low)**        | Better context for multi-file edits. Run `dart fix --apply` first.  |
| `high`     | 15–30          | 🔴 **Gemini 3.1 Pro (High)**       | Deep multi-file reasoning. Fix epicenter before touching consumers. |
| `critical` | 30+            | 🚨 **Claude Opus 4.6 (Thinking)**  | Maximum reasoning depth. Do NOT continue editing until switched.    |

### How to Advise a Model Switch

When recommending a model change, tell the user exactly which model to switch
to, using the names below as they appear in the **Antigravity model selector
(top-right of the chat panel)**:

| Severity   | Tell the user to switch to…       |
|------------|-----------------------------------|
| `medium`   | **Gemini 3.1 Pro (Low)**          |
| `high`     | **Gemini 3.1 Pro (High)**         |
| `critical` | **Claude Opus 4.6 (Thinking)**    |

Example phrasing:
> "This ripple is **HIGH** — **22 files** are impacted. Please switch to
> **Gemini 3.1 Pro (High)** using the model selector (top-right of the chat
> panel) before we continue. Then paste the epicenter file and I'll start the
> repair."

---

## Phase 4: Surgical Repair Strategy

After the report is generated, offer a tiered repair approach:

### Tier 1 — Automated Fixes (Always try first)
```powershell
dart fix --apply
dart format .
```
Re-run `ripple_scan.py` after and check if severity has dropped.

### Tier 2 — Epicenter-First Repair
Fix the **epicenter file** completely before touching any downstream file.
The epicenter is the source of truth — patching consumers before fixing
the source will create dependency loops.

### Tier 3 — Layer-by-Layer Repair
Work in this order to respect the dependency graph:
1. **Models** (`lib/models/`)
2. **Services** (`lib/services/`)
3. **Providers** (`lib/providers/`)
4. **Widgets** (`lib/widgets/`, `lib/screens/`)
5. **Tests** (`test/`)

### Tier 4 — Stabilize with a Stub
If the epicenter is too complex to fix immediately, add a **temporary stub**
so downstream files compile. Mark it clearly:
```dart
// TODO(ripple): Temporary stub — remove after [EpicenterFile] is fixed.
```

---

## Phase 5: Ripple Resolution Checklist

Before closing the skill session, verify:

- [ ] `dart analyze` returns 0 errors.
- [ ] All previously failing tests now pass.
- [ ] No TODO(ripple) stubs remain.
- [ ] Ripple Report artifact is updated with "RESOLVED" status.
- [ ] `CHANGELOG.md` entry is staged if the epicenter change was a public API change.
