---
description: Suggests development aliases and setup steps for Chromebook (Crostini) environments.
---
# Chromebook (Crostini) Development Setup

This workflow provides quick setup commands and aliases optimized for running and testing the Flutter app within a ChromeOS Linux container.

## 1. WebAssembly (Wasm) Testing Alias
When running Flutter Web (Wasm) inside the Linux container, you must bind the web server to `0.0.0.0` so the host ChromeOS browser can access it, and ensure COOP/COEP headers are injected.

Add this alias to your `~/.bashrc` to quickly launch the Wasm build:

```bash
echo 'alias fruc-cb="flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8080 --wasm"' >> ~/.bashrc
source ~/.bashrc
```

**Usage:** After applying, you can type `fruc-cb` in the terminal, then open your Chromebook's Chrome browser and navigate to `http://penguin.linux.test:8080` (or `http://localhost:8080`).

## 2. Standard Web Testing Alias (Non-Wasm)
If you need to test the standard Javascript compiler on Chromebook without Wasm:

```bash
echo 'alias fruc-cb-js="flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8081"' >> ~/.bashrc
source ~/.bashrc
```

## 3. ADB Debugging (Optional)
If you are deploying to the Android subsystem on the Chromebook, ensure you have enabled ADB debugging in ChromeOS developer settings, and connect via:
```bash
adb connect 100.115.92.2:5555
```
