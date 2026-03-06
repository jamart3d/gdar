# App Size Guard Skill

This skill provides tools and procedures for auditing and controlling the size of the GDAR Flutter application, with a heavy focus on Google TV storage constraints.

## Goal
**Keep the APK size under 30MB.** 
Google TV devices often have limited internal storage (<16GB, sometimes <4GB available).

## Audit Workflow

### 1. Fast Asset Scan
Check the `assets/` directory for large or unoptimized files.
```powershell
./.agent/skills/size_guard/scripts/audit_assets.ps1
```
- Flag files > 500KB.
- Ensure PNGs are compressed or converted to WebP where appropriate.
- Identify "Dead Assets" that aren't referenced in `pubspec.yaml` but still live in the folder.

### 2. Flutter Binary Analysis
Run the built-in analyzer to see which Dart packages or native libraries are taking up space.
```bash
flutter build apk --analyze-size --target-platform android-arm64
```
*Note: This generates a `size-analysis.json` file.*

### 3. Cleanup & Pruning
- Remove unused Google Fonts.
- Trim high-res assets that don't display on 1080p/4K TVs.
- Use `lib/config/app_size_baseline.json` (if it exists) to track growth over time.

## Critical Thresholds
| Asset Type | Max Single File | Total Budget |
| :--- | :--- | :--- |
| **Images** | 250 KB | 5 MB |
| **Data (JSON)** | 10 MB | 15 MB |
| **Fonts** | 100 KB | 1 MB |
| **Total APK** | 30 MB | N/A |
