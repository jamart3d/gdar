# Playback & Background Execution Audit

**Date:** 2026-01-15
**Version:** 1.0.3+3 (Analysis based on current codebase)

## 1. Executive Summary
The application is **correctly configured** for standard background audio playback on Android 14+. The use of `just_audio_background` with a foreground service ensures playback continues when the screen is off or the app is minimized.

**Rating:**
- **Configuration (Manifest/Permissions):** ✅ Excellent
- **Gapless Logic (Intra-Show):** ✅ Excellent (`ConcatenatingAudioSource`)
- **Gapless Logic (Inter-Show / Random Radio):** ⚠️ Moderate Risk

**Key Findings:**
1.  **Permissions**: Correctly declared (`FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `WAKE_LOCK`).
2.  **Gapless Playback**: Within a show, gapless is guaranteed by the native player's playlist handling.
3.  **Random Radio Reliability**: The "Auto-Advance" feature (playing a random show after the current one) relies on the **Flutter UI Isolate** remaining active to process stream events. In "Deep Sleep" (Doze mode), the OS may suspend the UI Isolate even if the audio service is running, potentially causing playback to stop at the end of a show.

---

## 2. Configuration Analysis

### Android Manifest (`android/app/src/main/AndroidManifest.xml`)
The manifest contains all necessary directives for modern Android background execution:
- **Permissions**:
  - `android.permission.WAKE_LOCK`: Essential for keeping the CPU running.
  - `android.permission.FOREGROUND_SERVICE`: Required for services.
  - `android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK`: Mandatory for Android 14+.
- **Service**:
  - `com.ryanheise.audioservice.AudioService`: defined with `foregroundServiceType="mediaPlayback"`.
- **Activity**:
  - `launchMode="singleTask"`: Prevents multiple instances.

### Initialization (`lib/main.dart`)
- `JustAudioBackground.init()` is called correctly in `main()`.
- `androidNotificationOngoing: true` is set, ensuring the notification persists and keeps the service alive.

---

## 3. Playback Logic Analysis

### Gapless Playback (Within a Show)
**Status: Robust**
- **Mechanism**: Use of `ConcatenatingAudioSource` in `AudioProvider.dart`.
- **Why it works**: The list of URLs is handed off to the native Android `ExoPlayer` instance. The native player handles buffering the next track while the current one plays. Flutter does not need to wake up for the transition to happen.

### Random Radio Auto-Advance (Between Shows)
**Status: Risk of Failure in Deep Sleep**
- **Mechanism**: `AudioProvider` listens to `_audioPlayer.positionStream` in the **Dart/Flutter Layer**.
- **Logic**:
  ```dart
  if (isLastTrack && position >= threshold) {
      await playRandomShow(filterBySearch: false);
  }
  ```
- **The Risk**:
  - While the **Native Audio Service** stays alive (due to Foreground Service), the **Flutter Engine (UI Isolate)** is not guaranteed to receive stream updates high-frequency or at all if the Play Store or OS decides to throttle the app process aggressively ("Phantom Process" killing or simple resource reclamation).
  - If the UI Isolate is suspended, the `positionStream` listener will not fire. The current show will finish, and silence will follow.
  - Playback will likely only resume if you wake the screen (resuming the Isolate).
- **Mitigation**:
  - `audio_service` generally tries to keep the isolate alive, but it is not 100% guaranteed on all OEMs (Samsung/Xiaomi are aggressive).

---

## 4. Verification Plan (Manual)

To verify the "Random Radio" risk, perform the following test:

1.  **Setup**:
    - Enable "Play Random Show on Completion" in Settings.
    - Pick a show.
    - Seek to the **last 30 seconds** of the **last track**.
2.  **Test**:
    - Turn off the screen immediately.
    - Wait for the track to finish.
3.  **Observation**:
    - **Pass**: The next show starts playing automatically while the screen is still off.
    - **Fail**: Playback stops after the track ends. Waking the screen causes it to suddenly jump to the next show.

---

## 5. Potential Improvements

1.  **Pre-Queueing (Recommended for Stability)**:
    - Instead of waiting for the end of the show to `playRandomShow()`, calculate the next random show **immediately when the current show starts** (or when the last track starts).
    - Append the next show's `ConcatenatingAudioSource` to the current playlist *before* the playback reaches the end.
    - This pushes the responsibility to the Native Player (ExoPlayer), which is immune to Flutter Isolate suspension.
    
2.  **Wakelock Tweaks**:
    - If strictly necessary, acquire a `Wakelock` (via `wakelock_plus` package) during the critical transition window, though this is battery-intensive and discouraged for long durations.

3.  **Ignore Battery Optimizations**:
    - Detailed instruction to users to disable "Battery Optimization" for this app can reduce OS throttling.
