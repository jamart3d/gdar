---
# Task: Decouple Logic from UI (7/10 Difficulty Cleanup)
1. Scan `lib/main.dart` and `AudioProvider`.
2. Extract the "Deep Linking" and "Inactivity Logic" into standalone classes in `shakedown_core`.
3. Remove any `package:flutter/material.dart` imports from the Provider files.
4. Replace hardcoded asset strings with a central `AssetConstants` class in the core package.
---
