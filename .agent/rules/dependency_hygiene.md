# Dependency Hygiene & Native Stability

### 1. Native Plugin Upgrades
When upgrading plugins that have native components (e.g., `device_info_plus`, `connectivity_plus`, `app_links`, `hive_ce`), you MUST verify local build stability before committing.

*   **Action:** After a major version bump or a community-edition migration, run `flutter build appbundle --debug` or `flutter build ios --no-codesign` to ensure the `GeneratedPluginRegistrant.java` or Podfile logic is still valid.
*   **Verification:** If a build failure occurs, check for stale build caches or incompatible Java/Gradle versions introduced by the new dependency.

### 2. Community Edition Migrations
When migrating to Community Edition (CE) forks (e.g., `hive` → `hive_ce`):
*   **Action:** Strictly follow the migration guide for the specific package.
*   **Persistence:** Verify that Hive adapters and boxes remain backward compatible to prevent data loss for existing users.
*   **Mocking:** Update all Mockito/Mocktail stubs in the test suite to use the new CE classes immediately.

### 3. Generated Plugin Registration
*   **Action:** If a `MissingPluginException` occurs after an upgrade, use the `/refresh_native` workflow to force a rebuild of the plugin registration logic.
