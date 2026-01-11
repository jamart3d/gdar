# Shakedown

A Flutter application for browsing and playing concert recordings of the Grateful Dead from archives.

## Features

- Browse a list of shows and their recordings.
- **Advanced Playback**:
  - Dedicated playback screen with set list support (Set 1, Set 2, Encore).
  - Persistent mini-player for audio controls while browsing.
  - Random playback options: Play random show on startup/completion, filter by unplayed or high-rated shows.
- **Smart Clipboard Integration**:
  - Automatically detects Archive.org share links in your clipboard.
  - **Instant Playback**: Detects paste gestures and immediately initiates playback with a helpful notification.
  - Seamlessly parses SHNIDs and track names to start playback instantly.
- **Collection Management**:
  - Rate shows (1-3 stars) or block them (Red star).
  - Block specific sources (SHNIDs) for multi-source shows by swiping left on the source item.
  - **Rated Shows Library**: View and manage shows filtered by rating (including blocked shows).
  - Track played/unplayed status.
  - Sort shows by date (Oldest First / Newest First).
- **Rich Details**:
  - View track details, sources, and SHNID badges.
  - Direct links to Archive.org for source details.
  - Copy show/track info to clipboard.
- **Customization**:
  - Light and Dark theme support with dynamic color options.
  - **True Black Mode**: Pitch black backgrounds for OLED screens.
  - **Glow Effects**: Adjustable glow intensity for the playback card, adding a premium feel.
  - **Accessibility**: Semantic labels for screen readers.
  - **Hide Track Duration** option for a minimalist interface.
  - **Global UI Scale**: Consistent text scaling across all screens.
- **Enhanced UX**:
  - **Smart Rating Dialog**: Toggle "Played" status, confirmation dialogs for safety, and mutually exclusive rating/blocking logic.
  - **Expressive Swipe to Block**: Polished Material 3 design for blocking shows/sources.
  - **Single Source Cleanliness**: Simplified view for shows with only one source.
  - **Rated Shows Library**: Dynamic counts on tabs (e.g., "Played (5)") and easier navigation.
  - **Smart Random**: Manual triggers respect search filters; automated playback picks from the full library to keep music fresh.
  - **Refined Settings**: Dedicated "Random Playback" section and clearer usage instructions with improved typography.
  - **Source-Only Blocking**: Blocking now applies specifically to Source IDs rather than the entire Show, allowing for finer curation.

## Usage Guide

### **Player Controls**

- **Mini-Player**: Appears at the bottom of the screen while browsing. Tap to expand to the full Playback Screen.
- **Playback Screen**:
  - **Single Tap**: Toggle Play/Pause.
  - **Double Tap**: Like/Like+ (Cycle through ratings: 1 star → 2 stars → 3 stars).
  - **Long Press**: Show details/Expand specialized controls.
  - **Swipe Down**: Collapse to Mini-Player.
- **Show List**:
  - **Tap**: View track list (or expand show if multiple sources exist).
  - **Long Press**: Play randomly (or play specific source if expanded).
  - **Swipe Left**: Quick block (Red Star).

### **Settings**

Access settings via the gear icon in the top app bar.

- **Appearance**: Toggle **Dark Mode**, **True Black Mode** (for OLED), and **Dynamic Color** (Material You). Note: True Black requires Dynamic Color to be disabled or "Half Glow" to be enabled.
- **Playback**:
  - **Gapless Playback**: Seamless audio transitions.
  - **Random Playback**: Configure behavior for the random shuffle button.
- **Interface**:
  - **UI Scale**: Adjust text size globally.
  - **Show Single SHNID**: Toggle visibility of SHNID badges for single-source shows.
- **Source Filtering**:
  - **Filters**: Toggle specific source types (SBD, Matrix, etc.).
  - **Solo Mode**: **Long press** a filter category to solo it (disable all others).

### **Random Selection Logic**

- **Manual Random (Button)**: Respects your current search query and filters.
- **Auto-Play Random**: When a show finishes, the app creates a "radio" experience by picking a new random show. This mode **ignores** current search filters to select from your entire library, ensuring variety.
- **Exclusions**: Blocked shows (Red Star) are **never** selected by random logic.

## Project Structure

The project's Dart code is located in the `lib` directory and is organized as follows:

- **`api/`**: Contains services for fetching data, like show information.
- **`models/`**: Defines the data structures for shows, tracks, and sources.
- **`providers/`**: Manages the application's state (e.g., audio playback, show lists, settings).
- **`ui/`**: Contains the user interface code, separated into:
  - **`screens/`**: The main screens of the application (e.g., show list, playback).
  - **`widgets/`**: Reusable UI components used across different screens.
- **`utils/`**: Includes utility functions, theme definitions, and other shared resources.
- **`main.dart`**: The entry point of the application.
