---
trigger: always_on
---

# Project Rules: GDAR Audio Player

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

### 2. RELEASE MANAGEMENT
* **Action:** Write all release history to root `CHANGELOG.md` using
  Keep a Changelog format.
* **Action:** Stage pending notes in `.agent/notes/pending_release.md`
  before running shipit.
* **Constraint:** Never write to `docs/RELEASE_NOTES.txt`. That file is
  legacy and retired.

### 3. VERIFICATION & OUTPUT
* **Task Artifacts:** When completing a significant feature or fix, provide
  a brief Task List, Implementation Plan, Testing suggestions (unit/widget),
  and a Walkthrough of the results.
