# Pending Release Notes
[Unreleased] entries will be moved to CHANGELOG.md during the next /shipit run.

## [Unreleased]
- Post-shipit dependency maintenance session completed.
- Ran `flutter pub outdated` as a fresh baseline:
  - `9` dependencies remained constrained below resolvable versions.
- Ran `flutter pub upgrade --major-versions`:
  - Updated constraints in:
    - `pubspec.yaml` (`melos`)
    - `packages/shakedown_core/pubspec.yaml`
    - `apps/gdar_mobile/pubspec.yaml`
    - `apps/gdar_tv/pubspec.yaml`
    - `apps/gdar_web/pubspec.yaml`
  - Upgraded major dependencies including:
    - `connectivity_plus` `6.1.5 -> 7.1.0`
    - `device_info_plus` `11.5.0 -> 12.4.0`
    - `package_info_plus` `8.3.1 -> 9.0.1`
    - `permission_handler` `11.4.0 -> 12.0.1`
    - `permission_handler_android` `12.1.0 -> 13.0.1`
    - `wakelock_plus` `1.3.3 -> 1.5.1`
    - `flame_test` `1.19.2 -> 2.2.3`
    - `flutter_launcher_icons` `0.13.1 -> 0.14.4`
    - `melos` `7.5.0 -> 7.5.1`
- Verified workspace health after major upgrades:
  - `dart run melos run analyze` passed.
  - `dart run melos run test` passed.
