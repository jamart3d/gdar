# Google TV Interaction Scenarios

The following table documents the desired behavior for Screensaver and Sleep/Dream states on Google TV.

| Scenario | Audio Playing | Prevent Sleep (Setting) | Result | Will it go to "Dream"? |
| :--- | :--- | :--- | :--- | :--- |
| **Normal Playback** | Yes | On | Screen stays on app UI. | **No** |
| **Internal Screensaver** | Yes | On | Internal screensaver is visible and stays indefinitely. | **No** |
| **Internal Screensaver** | No | On/Off | Internal screensaver starts, but after the system timeout (e.g., 5-15 mins), the TV will switch to System Dream or Sleep. | **Yes** |
| **Playback Paused** | No | On | Wakelock is disabled. System will eventually go to Dream/Sleep. | **Yes** |
