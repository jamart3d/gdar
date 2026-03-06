# Windows Shell Execution Rules

**ENV:** Windows

1. **Always use `cmd /c`** for all shell executions to ensure the process terminates correctly and sends an EOF signal.
   - ✅ `cmd /c pip list`
   - ❌ `pip list`

2. **Avoid interactive shells.** If a persistent session is needed, use `cmd /k` but ensure the command is self-terminating.
