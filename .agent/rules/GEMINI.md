---
trigger: always_on
---

# Project Rules: GDAR Audio Player

* **Action:** When a workflow is triggered (e.g., /checkup), strictly follow every step as defined in its `.md` file, including `// turbo` auto-approval logic.
* **Action:** Before any workflow that depends on CLI orchestration tools (`/checkup`, `/verify`, `/shipit`, `/deploy`), run `.agent/workflows/toolchain_preflight.md` first and fail fast if required commands are missing.

### 1. CODING STANDARDS & ARCHITECTURE
* **Stack:** Latest Stable Flutter / Dart SDK. Strictly follow modern syntax
  (e.g., favoring `.withValues()` over `withOpacity()`) and proactively resolve
  deprecation warnings.
* **Architecture:** Clean Architecture. Strictly separate UI (Widgets),
  Business Logic (Provider/State), and Data (Repository).
* **State Management:** Provider is primary. Use `ChangeNotifier` or `ProxyProvider`.
* **Style & Performance:** Adhere strictly to the official Dart style guide,
  use `flutter format`, and use `const` constructors everywhere possible to
  prevent unnecessary rebuilds.
* **Design System:** Use strict platform separation.
  * **Android Phone/Tablet:** Material 3 (Expressive) is the foundation.
  * **Google TV / Android TV:** TV-focused Material Dark + D-Pad UX.
    * **Action:** Always utilize `settingsProvider.activeAppFont` for text styling in new widgets to ensure "Rock Salt" branding on TV isn't diluted.
  * **Web/PWA Fruit:** Apple Liquid Glass only.
  * **Hard rule for Fruit:** No Material 3 widgets, ripples, FAB patterns,
    or M3 interaction language on Fruit screens.
  * If Fruit glass effects are disabled for performance, keep Fruit layout and
    controls (no M3 fallback swap).
  * Always gate Fruit logic with `kIsWeb`/PWA checks.

### 2. RELEASE MANAGEMENT
* **Action:** Write all release history to root `CHANGELOG.md` using
  Keep a Changelog format.
* **Action:** Stage pending notes in `.agent/notes/pending_release.md`
  before running shipit.
* **Action:** In the `/shipit` workflow, ALWAYS perform a fresh version bump and rebuild; never assume the current changelog or artifact state represents the final release.
* **Constraint:** Never write to `docs/RELEASE_NOTES.txt`. That file is
  legacy and retired.
* **Action:** When updating `docs/PLAY_STORE_RELEASE.txt`, ALWAYS prepend the new release block to the top of the file. NEVER overwrite or replace the existing contents.

### 3. VERIFICATION & OUTPUT
* **Task Artifacts:** When completing a significant feature or fix, provide
  a brief Task List, Implementation Plan, Testing suggestions (unit/widget),
  and a Walkthrough of the results.
* **Smart Receipts:** When `melos run analyze`, `melos run test`, or `melos run format` pass successfully, the agent MUST update `.agent/notes/verification_status.json` with the current `git rev-parse HEAD` and results. This allows the `/shipit` workflow to skip redundant runs on an identical worktree state.
* **Context Pulse:** At the end of every 3 conversation turns or upon completion of any Slash Command, the agent MUST report the current context usage percentage and status as defined in `.agent/rules/context_protocol.md`.
