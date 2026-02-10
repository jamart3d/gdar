# Audio Cache Implementation Audit

**Date**: 2026-02-10
**App Version**: 1.0.31+31
**AI Model**: Gemini 2.0
**Project**: Shakedown (GDAR)

---

## 🎧 Executive Summary

The application utilizes `just_audio`'s **LockCachingAudioSource** for its offline buffering capabilities. This implementation ensures that audio files are downloaded once, cached securely, and reused for subsequent playback, enabling robust offline functionality and reducing bandwidth usage.

The caching logic is encapsulated within `AudioCacheService` and utilized by `AudioProvider`.

---

## 🛠️ Technical Implementation

### 1. Underlying Mechanism
- **Class**: `LockCachingAudioSource` (from `just_audio_background`)
- **Behavior**: Acts as a proxy. It intercepts the audio stream, writes bytes to a local file, and simultaneously serves the player. Once fully downloaded, the player reads directly from the local file.

### 2. Storage Architecture
- **Location**: `Directory.systemTemp` / `shakedown_audio_cache`
  - *Note*: As a temporary directory, the OS may clear this during low-storage events, which is appropriate behavior for a cache.
- **File Naming**: SHA-256 Hash of the sourced URL.
  - `sha256.convert(utf8.encode(uri.toString())).toString()`
  - **Why?**: Guaranteed uniqueness per URL, handles special characters safely, and ensures consistent mapping.

### 3. Lifecycle Management
- **Instantiation**: Created on-demand in `AudioProvider._createAudioSource()`.
- **Locking**: The file is "locked" during playback/download.
- **Monitoring**: `AudioCacheService` runs a periodic (5s) timer to count cached files when `offline_buffering` is enabled.

### 4. Cache Cleanup (LRU Strategy)
- **Trigger**: `performCacheCleanup()` is called opportunistically when queueing a new show.
- **Logic**:
  1. Identify all files matching the SHA-256 regex.
  2. Sort by **Last Modified Time** (Newest First).
  3. Keep the most recent `maxFiles` (default ~20, dynamically adjusted based on current show length).
  4. Delete the rest.
- **Safety**: Errors during deletion (e.g., file in use) are caught and ignored, preventing playback crashes.

---

## 📊 Configuration Parameters

| Parameter | Value | Description |
| :--- | :--- | :--- |
| **Directory** | `shakedown_audio_cache` | Dedicated subdirectory in system temp. |
| **Max Files** | Dynamic (~20+) | Keeps enough for current show + buffer. |
| **File Regex** | `^[a-f0-9]{64}$` | Matches valid SHA-256 hex strings. |
| **Refresh Rate** | 5 Seconds | Interval for updating UI cache count. |

---

## 🚨 Error Handling & Edge Cases

- **Cache Directory Missing**: Automatically recreated if deleted by OS.
- **Write Errors**: `LockCachingAudioSource` handles write failures internally; player surfaces them as playback errors.
- **File In Use**: Cleanup logic skips files currently locked by the player.
- **Initialization**: Lazy initialization ensures the directory exists before first write.

---

## 🏎️ Buffering Strategy (Q&A)

**Does it cache ahead of what is played?**
- **Yes, but only the Active Buffer.**
- **Mechanism**: `LockCachingAudioSource` relies on the player's buffer demand.
  - It **buffers ahead** (typically 2-3 minutes) to ensure smooth playback during network fluctuations.
  - It does **NOT** download the entire file aggressively if you are paused or just starting a track.
- **Resilience**:
  - **Network Drops**: You are safe for the duration of the look-ahead buffer.
  - **Deep Sleep**: Buffering continues in the background until the buffer goal is met, then pauses to save battery/data.
