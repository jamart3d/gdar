---
description: Audit asset and build size budgets for the GDAR monorepo.
---
# Size Guard Workflow (Monorepo)

Use this workflow to audit asset growth and release artifact size, especially
for Android and TV targets where storage pressure matters most.

## Scope
- Shared assets across the workspace
- Android/mobile builds under `apps/gdar_mobile`
- TV builds under `apps/gdar_tv`

## Goals
- Keep oversized assets out of the repo
- Catch unoptimized images and dead assets early
- Monitor Android/TV artifact growth before release

## Workflow

### 1. Fast Asset Scan
Run the platform-appropriate asset audit script from the workspace root:
- **Windows:** `./scripts/size_guard/audit_assets.ps1`
- **Linux/bash:** `./scripts/size_guard/audit_assets.sh`

Checks:
- Flag files over 500 KB
- Identify PNG/JPG candidates for WebP conversion
- Surface likely dead assets that are not referenced in `pubspec.yaml`

### 2. Binary Size Audit
Run Flutter size analysis from the target app directory.

Mobile:
```powershell
cd apps/gdar_mobile; flutter build apk --release --analyze-size --target-platform android-arm64
```

TV:
```powershell
cd apps/gdar_tv; flutter build apk --release --analyze-size --target-platform android-arm64
```

> [!NOTE]
> `--analyze-size` requires a single `--target-platform`. It cannot be used with `flutter build appbundle` (multi-ABI). Use APK builds here for size diagnostics only — the release AAB is built separately by `/shipit`.

### 3. Evaluate Budgets
Use these working thresholds as a quick review guide:

| Asset Type | Max Single File | Total Budget |
| :--- | :--- | :--- |
| **Images** | 250 KB | 5 MB |
| **Data (JSON)** | 10 MB | 15 MB |
| **Fonts** | 100 KB | 1 MB |
| **Total APK** | 30 MB | N/A |

### 4. Cleanup Guidance
- Remove unused fonts and assets
- Trim oversized images that do not need TV-scale resolution
- Review whether large shared assets belong in `packages/shakedown_core`
- Use `packages/shakedown_core/lib/config/app_size_baseline.json` if present to track drift over time

### 5. Reporting
Summarize:
- largest assets found
- dead or suspicious assets
- mobile/TV artifact size status
- suggested next cuts if budgets are exceeded
