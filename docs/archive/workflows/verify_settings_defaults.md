---
description: Archived standalone workflow; settings defaults are now enforced by tests.
archived_on: 2026-04-11
replacement: packages/shakedown_core/test/providers/settings_provider_defaults_contract_test.dart
---
# Archived: Verify Settings Defaults Workflow

This standalone workflow was retired during workflow cleanup.

Reason for archival:
- product-default contracts are better enforced by automated tests than a
  manual release workflow
- the previous workflow referred to stale setting names that no longer matched
  the active settings model

Current enforcement lives in:
- `packages/shakedown_core/test/providers/settings_provider_defaults_contract_test.dart`
