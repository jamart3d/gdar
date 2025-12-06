# gdar

A Flutter application for browsing and playing concert recordings of the Grateful Dead from archives.

## Features

- Browse a list of shows and their recordings.
- **Advanced Playback**:
  - Dedicated playback screen with set list support (Set 1, Set 2, Encore).
  - Persistent mini-player for audio controls while browsing.
  - Random playback options: Play random show on startup/completion, filter by unplayed or high-rated shows.
- **Collection Management**:
  - Rate shows (1-3 stars) or block them (Red star).
  - Block specific sources (SHNIDs) for multi-source shows by swiping left on the source item.
  - Track played/unplayed status.
  - Sort shows by date (Oldest First / Newest First).
- **Rich Details**:
  - View track details, sources, and SHNID badges.
  - Direct links to Archive.org for source details.
  - Copy show/track info to clipboard.
- **Customization**:
  - Light and Dark theme support with dynamic color options.
  - "True Black" mode for OLED screens.
  - Customizable UI scale and font options.

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
