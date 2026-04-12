# App Health Hardening Checklist

Date: 2026-04-11
Project: GDAR
Derived from:
- `reports/CODE_HYGIENE_REPORT_2026-04-11.md`
- `reports/NETWORK_HYGIENE_REPORT_2026-04-11.md`
- current repo review on `76b06e3`

## Goal

Capture the next highest-value checks after code hygiene, network hygiene, and
monorepo audits so the app family stays lean, efficient, and release-ready.

## Current Baseline

The repo already has strong fundamentals:

- workspace `format`, `analyze`, and `test` scripts via `melos`
- web build verification in CI
- size/audit utilities under `scripts/`
- broad shared-package widget, provider, and service test coverage
- explicit platform rules for mobile, TV, and Fruit/web

The next gains come less from generic cleanup and more from hardening
performance, runtime behavior, release safety, and maintenance drag.

## Recommended Next Checks

### 1. Performance Budgets and Runtime Evidence

Add explicit budgets and capture them regularly.

Suggested metrics:
- cold start time
- first frame / first interactive frame
- catalog parse time for `output.optimized_src.json`
- memory after startup and after playback begins
- web audio handoff latency
- background playback survival window on web

Why this matters:
- the app already passes static hygiene checks
- runtime regressions can still creep in while analyzer/tests stay green
- the 9.2 MB catalog asset is already isolated correctly, but it should remain
  measured over time

### 2. Native Build Smoke Coverage

Expand verification beyond the current web build lane.

Suggested checks:
- Android mobile debug or release smoke build
- Android TV debug or release smoke build
- plugin registration sanity after dependency upgrades

Why this matters:
- `just_audio` and `just_audio_background` increase native integration risk
- CI currently proves web build health well, but not the native targets

### 3. Release Security and Manifest Hardening

Do a dedicated release-pass review for manifests, permissions, and exported
surfaces.

Priority items:
- disable cleartext traffic in release builds
- verify only required permissions remain enabled
- verify exported activities/services/receivers are intentional
- confirm deep-link intent filters are as narrow as practical

Why this matters:
- the network hygiene report already identified the cleartext release flag as a
  real gap
- this is a high-value release-safety check with low maintenance cost

### 4. Resilience and Recovery Paths

Test failure and recovery behavior, not just success paths.

Suggested cases:
- Hive box corruption or unreadable persisted state
- asset parse failure or malformed data fallback
- bad/missing `SharedPreferences` values
- startup with no network
- archive reachability failure during onboarding and catalog flow
- restart/resume after partial playback state was persisted

Why this matters:
- user trust comes from graceful degradation, not only green happy-path tests

### 5. Lifecycle and Integration Checks

Add or refresh smoke coverage for the most fragile user journeys.

Suggested cases:
- deep-link handling across mobile and TV
- background to foreground resume
- notification tap routing
- audio interruption / pause / resume behavior
- offline start and recovery after connectivity returns
- screensaver launch and exit state restoration

Why this matters:
- these flows often regress at integration boundaries rather than inside single
  units

### 6. Visual Contract Protection

Protect platform UI rules with visual or contract-oriented checks.

Suggested coverage:
- Fruit screens never regress to Material widgets or Material interaction
  language
- TV focus order, badges, and scrollbar visibility stay stable
- mobile and TV startup shells remain visually sane after theme changes

Why this matters:
- GDAR has unusually strict platform contracts
- visuals can drift even when logic tests pass

### 7. Size and Asset Budgets

Keep release outputs lean with explicit thresholds.

Suggested checks:
- web bundle size budget
- APK/AAB growth tracking
- large asset growth gate
- stale generated asset cleanup
- cache growth / eviction sanity for audio preload paths

Why this matters:
- asset and build growth is gradual and easy to miss until late

### 8. Dependency and Plugin Risk Review

Audit dependencies from a release-risk perspective, not only an update
perspective.

Suggested focus:
- native plugin footprint
- beta packages in release-critical paths
- permission expansion after upgrades
- plugins that affect background behavior, notifications, or playback

Why this matters:
- a dependency can be current and still increase stability or release risk

### 9. Maintainability and Duplication Hotspots

Continue the highest-value dedupe and structure cleanup already identified in
the hygiene reports.

Best targets:
- onboarding screen duplication
- mobile/TV app lifecycle duplication
- provider setup duplication
- near-identical web/core widget forks

Why this matters:
- the analyzer is already clean
- maintenance drag now comes more from duplication than from obvious dead code

### 10. Test Surface Cleanup

Make sure old test weight is still paying for itself.

Suggested checks:
- re-enable or remove skipped regression tests
- identify flaky tests and either harden or replace them
- verify tests never hit live network endpoints
- keep targeted smoke suites for high-risk playback and platform flows

Why this matters:
- stale or skipped tests create false confidence

## Suggested Order

1. Release manifest hardening and native smoke builds
2. Performance budgets and runtime evidence capture
3. Resilience/recovery tests for startup, storage, and network loss
4. Visual/platform contract protection
5. Duplication cleanup and test-surface pruning

## Concrete Small Follow-Up

One repo-level item worth fixing soon:

- `apps/gdar_web/pubspec.yaml` points `flutter_launcher_icons.image_path` at
  `../../packages/shakedown_core/assets/images/gdar_icon_foregroup.png`
  while the existing image asset appears to be
  `gdar_icon_forground.webp`

That looks like an icon path drift issue and could break the next icon regen
pass.
