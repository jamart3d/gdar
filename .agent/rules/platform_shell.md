# Platform-Specific Shell Execution Rules

### Linux / ChromeOS
1. **Always execute commands as:** `timeout 60s bash -lc "<command>"`
2. **Never use interactive shells.**
3. **Never leave background processes running.**

### Windows
1. **Always use `cmd /c`** for all shell executions to ensure the process terminates correctly and sends an EOF signal.
   - ✅ `cmd /c pip list`
   - ❌ `pip list`
2. **Avoid interactive shells.** If a persistent session is needed, use `cmd /k` but ensure the command is self-terminating.
