# Version Synchronization Guard

In this monorepo, version consistency across app targets is critical for release integrity.

1.  **Preflight Check**: Before starting any release workflow, the agent MUST verify that `apps/gdar_mobile`, `apps/gdar_tv`, and `apps/gdar_web` all share the exact same `version:` string in their respective `pubspec.yaml` files.
2.  **Fresh Bump**: As per `GEMINI.md`, the `shipit` workflow MUST always increment the version and build number. The agent should NEVER assume the current file version is the final release version.
3.  **Atomic Updates**: Any version bump MUST be applied to all three app targets in a single atomic operation (e.g., using `multi_replace_file_content` or chained `sed` commands).
