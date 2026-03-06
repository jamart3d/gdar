# Linux / ChromeOS Shell Execution Rules

**ENV:** Linux (Ubuntu / ChromeOS)

1. **Always execute commands as:** `timeout 60s bash -lc "<command>"`
2. **Never use interactive shells.**
3. **Never leave background processes running.**
