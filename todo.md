# gdar - To-Do List

This file tracks planned features, enhancements, and bug fixes for the gdar application.

## High Priority

- [x] **Unit Tests:** Write unit tests for providers (`AudioProvider`, `ShowListProvider`) to ensure business logic is correct.
- [x] **Widget Tests:** Write widget tests for critical UI components like `ShowListCard` and `PlaybackScreen`.
- [x] **Error Handling:** Implement more robust error handling for audio playback (e.g., show a snackbar if a track URL is invalid or network fails).
- [x] **App Startup:** Refactor startup to be synchronous, remove initial loading screen, and respect splash screen setting immediately.
- [x] **Random Show:** Ensure app scrolls to and expands the random show when "Play Random Show on Startup" is enabled.
- [x] **App Icon:** Update application icon.
- [x] **Bug Investigation:** Check into why RGB border is not visible on Android 16 vs 15.

## Medium Priority

- [x] **Advanced Rating & Playback Logic:**
  - [x] **Rating System:** Red Star (Block/Hide), 0 Stars (Unplayed), 1-3 Gold Stars.
  - [x] **Random Logic:** Never pick Red Star. Prioritize Unplayed. Weighted randomness for stars (3>2>1).
  - [x] **Settings:** Options for "Only Select Unplayed" and "Only Select High Rated (2-3 Stars)".
  - [x] **Stats:** Track counts for Unplayed, Played, and Starred shows.
  - [x] **UI Location:** Upper right corner of Show Card and Playback Controls.

- [x] **Archive.org Link:** Tap SHNID badge on Playback Screen and Rating Dialog to open show details in browser.

- [x] **Rate Show Dialog UI:** Improve the layout and design of the rating dialog.
- [x] **SHNID Badge Size:** Increase the size of the SHNID badge in the Playback Screen (it's too small).
- [x] **Clipboard Icon:** Add a clipboard icon next to the venue name in Playback Screen to copy show/track info.

- [x] **Quick Block:** Left swipe on a Show Card (for single source shows) or an individual Source Item (for multi-source shows) to instantly mark it as "Red Star" (Blocked). Handles stopping playback and provides undo options.

- [ ] **Clipboard Playback:** Feature to parse a shared show/track string from the clipboard and instantly play that specific track/position.

- [x] **Set Lists:** Organize tracks into sets (Set 1, Set 2, Encore) in the track list view.
  - *Implementation Note:* `shows2.json` now includes a `setlist` attribute. Update `Show` or `Track` models to support this structure and parse it from the new JSON.

- [ ] **Recording Type Metadata:** Add an attribute to `shows.json` identifying the recording type (e.g., "Ultramatrix", "Betty Board"). Update the `Source` model to parse and display this information.

- [x] **Sort Order:** Added "Sort Oldest First" setting to control show list order (defaulting to chronological).

- [ ] **Rated Shows Library:** Create a dedicated screen to view and manage shows filtered by rating (Blocked, 1, 2, 3 stars). This allows users to review blocked shows or see their favorites.

- [ ] **UI Polish:** Refine animations and transitions for an even smoother feel.

- [ ] **Accessibility:** Review the app for accessibility improvements (e.g., screen reader labels).

## Low Priority / Ideas

- [ ] **Google TV Support:** Create a dedicated screen/layout optimized for Google TV and Android TV.

- [ ] **Google Assistant Integration:** Add support for voice commands (e.g., "Hey Google, play a random show on gdar") using App Actions.

- [ ] **Calendar Feature:** View shows by date on a calendar interface (e.g., "On This Day").
