---
description: Capture a screenshot from the connected Android device via ADB and save it locally for review.
---

1. Create the screenshots directory if it doesn't exist.
   ```bash
   mkdir -p tool/screenshots
   ```

2. Capture the screenshot on the device.
   ```bash
   adb shell screencap -p /sdcard/capture.png
   ```

3. Pull the screenshot to the local machine.
   ```bash
   adb pull /sdcard/capture.png tool/screenshots/latest_capture.png
   ```

4. (Optional) Remove the temporary file from the device.
   ```bash
   adb shell rm /sdcard/capture.png
   ```

5. Notify the user that the screenshot is ready at `tool/screenshots/latest_capture.png`.
