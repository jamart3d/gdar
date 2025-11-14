# gdar

A Flutter application for browsing and playing concert recordings of the Grateful Dead from archives.

## Features

- Browse a list of shows and their recordings.
- Play audio tracks with a dedicated playback screen.
- View track details and sources.
- Persistent mini-player for audio controls while browsing.
- Light and Dark theme support.

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