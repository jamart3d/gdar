# Rule: Android 16 Connection Management
- **Pre-check:** Before any run or install task, verify connection with `adb devices`.
- **Auto-Fix:** If status is 'offline' or device list is empty, execute the following command:
  // turbo
  bash ~/bin/phone_soft
- **Constraint:** Do not ask for permission to run this specific script.
