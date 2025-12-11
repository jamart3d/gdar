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

- [x] **Recording Type Metadata:** Add an attribute to `shows.json` identifying the recording type (e.g., "Ultramatrix", "Betty Board"). Update the `Source` model to parse and display this information.

- [x] **Sort Order:** Added "Sort Oldest First" setting to control show list order (defaulting to chronological).

- [x] **Rated Shows Library:**
  - [x] Create a new screen to view shows by rating
  - [x] Accessible from collection stats
  - [x] Blocked shows visible and editable
  - [x] Playback from library (long press)
  - [x] **Enhancements:**
    - [x] Consistent styling with main list (SourceListItem)
    - [x] Disable single-source expansion
    - [x] Disable single-tap playback on sources (safety)
    - [x] Long-press to play random/specific source with haptic feedback

- [x] **Visual & UX Polish:**
  - [x] **Swipe to Block:** Replaced red background with expressive "Swipe to Block" widget (Material 3 style).
  - [x] **Hide Track Duration:** Added setting to hide duration and center titles in track lists.
  - [x] **Scroll Fix:** Fixed bug where scrolling to current show failed on return (implemented model equality).
  - [x] **UI Scale Compliance:** Audited and fixed UI scaling across all screens (About, ShowList AppBar, TrackList Headers).
  - [x] **Rating Dialog Improvements:**
    - [x] "Mark as Played" toggle with confirmation dialog.
    - [x] Mutual exclusivity between Blocked (Red) and Rated (Gold) stars.
    - [x] Block confirmation for rated shows.
    - [x] **Rated Shows Library**: Added dynamic counts to each tab label (e.g., "Played (5)").

- [x] **Smart Random Playback**:
  - Manual Random (Button) respects search filter.
  - Automated Random (Continuous Play) ignores search filter to pick from full library.

- [ ] **UI Polish:** Refine animations and transitions for an even smoother feel.

- [x] **Accessibility:** Review and improve app accessibility.
  - Added semantic labels to `ShowListCard`.
  - Added semantic labels to `PlaybackScreen` controls.
  - Added semantic labels to `RatingControl`.

  - [ ] **Source Filtering:** Add setting to only list the latest source (SHNID) for each show date, if multiple sources exist.

  - [ ] **Source Category Filtering:**
    - Add setting to filter which `src` types are shown in the show list.
    - **Categories:**
      - **Betty:** [betty, betty board, bbd]
      - **Ultra:** [ultramatrix, miller.pearson.healy, ultra]
      - **Matrix:** [mtx, matrix] (Default Active)
      - **DSBD:** [dsbd]
      - **FM:** [fm, prefm, pre-fm]
      - **SBD:** [sbd, sdb, sby, sbeok]
    - **UI:** List of source badges that can be activated/deactivated.
    - **Constraint:** At least one category must remain active.

## Low Priority / Ideas

- [ ] **Google TV Support:** Create a dedicated screen/layout optimized for Google TV and Android TV.

- [ ] **Google Assistant Integration:** Add support for voice commands (e.g., "Hey Google, play a random show on gdar") using App Actions.

- [ ] **Calendar Feature:** View shows by date on a calendar interface (e.g., "On This Day").

- [ ] **Play Count & History**: Consider how to track and display how many times a show has been played. Display only in Rate Dialog or Rated Shows Library (not in Playback Controls).

- [ ] **Smart Random Setting**: Add a setting to toggle whether "Automated Random (Continuous Play) ignores search filter to pick from full library" (currently enabled by default).

- [ ] **Search Help**: Add functionality to help users enter month names in the search field (e.g., autocomplete or chips).

- [ ] **Compact Player Mode:** Add setting to minimize the playback screen player (showing only duration/progress) and move the play/pause control to an icon on the currently playing track in the list.

- [ ] **Swipe to Block Follow-up:** When using "Swipe to Block" to remove a show, provide an option (or setting) to immediately trigger a new random selection.

- [ ] **Rename Category:** Rename category 'unk'/'unknown' to 'fix'/'fix needed'.

- [ ] **Move Encore Tracks:** Create a Python script to identify and move end tracks into an 'Encore' set.
