---
description: Suggests development aliases and setup steps for Chromebook (Crostini) environments.
---
# Chromebook (Crostini) Development Setup

This workflow provides quick setup commands and aliases optimized for running and testing the Flutter app within a ChromeOS Linux container.

## 0. Workspace Validation Guidance

For manual monorepo validation runs on Chromebook, prefer **serial** Melos
execution instead of the repo's faster default concurrency.

Recommended:

```bash
dart run melos exec -c 1 -- dart analyze .
dart run melos exec -c 1 --dir-exists=test --ignore="screensaver_tv" -- flutter test
```

Avoid assuming `melos exec -c 2` is safe on Crostini for scorecard-quality
reruns. It can introduce Flutter startup-lock contention and noisier results.

## 1. Standard Web Testing Alias
WASM is disabled until further notice. When running Flutter Web inside the Linux container, bind the web server to `0.0.0.0` so the host ChromeOS browser can access it.

Add this alias to your `~/.bashrc` to quickly launch the standard web build:

```bash
echo 'alias fruc-cb="flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8080"' >> ~/.bashrc
source ~/.bashrc
```

**Usage:** After applying, you can type `fruc-cb` in the terminal, then open your Chromebook's Chrome browser and navigate to `http://penguin.linux.test:8080` (or `http://localhost:8080`).

## 2. Alternate Web Port Alias
If you need a second Chromebook alias on a different port:

```bash
echo 'alias fruc-cb-alt="flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8081"' >> ~/.bashrc
source ~/.bashrc
```

## 3. ADB Debugging (Optional)
If you are deploying to the Android subsystem on the Chromebook, ensure you have enabled ADB debugging in ChromeOS developer settings, and connect via:
```bash
adb connect 100.115.92.2:5555
```
