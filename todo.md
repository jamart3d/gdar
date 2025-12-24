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
- [x] **Album Art:** Update default album art to `assets/images/t_steal.webp`.

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
    - [ ] **Show List Scrollbar:** Implement a custom scrollbar for the Show List.
      - [ ] **Settings:** Option for "Always Visible" vs "Auto Hide".
      - [ ] **Thumb Details:** Large, scalable thumb (respects UI Scale) that displays the year's last two digits (e.g., '77).
    - [x] Block confirmation for rated shows.
    - [x] **Rated Shows Library**: Added dynamic counts to each tab label (e.g., "Played (5)").

- [x] **Smart Random Playback**:
  - Manual Random (Button) respects search filter.
  - Automated Random (Continuous Play) ignores search filter to pick from full library.

- [ ] **UI Polish:** Refine animations and transitions for an even smoother feel.
- [ ] **3D Rotating Stars:** Animate rating stars by rotating them around their Y-axis to give a 3D effect.
- [x] **Font Selection:** Add setting to choose the handwriting font. Options: Caveat, Permanent Marker, Lacquer, Rock Salt.
- [x] **Fix highlight:** With Dark Mode + Dynamic Color + Glow Border: Fix issue where glow is uniform on all shows, and missing when expanded. Implement "half glow" for all, and "regular glow" for current show/shnid.
- [ ] **Improve Playback Controls:** Enhance the layout and interactivity of controls in the Playback Screen.
  - [ ] **Venue Name Positioning:**
    - [ ] Add setting to display venue name under the date in Playback Screen appbar.
    - [ ] Move venue name in Playback Controls (expanded) to just above the date.
    - [ ] Hide venue name in Playback Controls when collapsed.
- [x] **Haptic Feedback Idetified Improvements:**
  - [x] Add `HapticFeedback.mediumImpact()` to Source Filter "Solo" Mode (Long Press).
  - [x] **Polish:** Add subtle feedback (`selectionClick`) to:
    - [x] Play/Pause and Next/Prev buttons.
    - [x] Expand/Collapse Show Card.
    - [x] Star Rating taps.

- [x] **Accessibility:** Review and improve app accessibility.
  - Added semantic labels to `ShowListCard`.
  - Added semantic labels to `PlaybackScreen` controls.
  - Added semantic labels to `RatingControl`.

  - [x] **Source Filtering:** Add setting to only list the latest source (SHNID) for each show date, if multiple sources exist.

  - [x] **Source Category Filtering:**
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

- [ ] **Miniplayer Fix:** Fix miniplayer rebuild when navigating between shows screen and track list screen, or integrate it better with the playback controls from the playback screen.

- [ ] **Volume Control:**
  - Add volume slider/control to Playback Screen controls.
  - Add setting in Playback Settings to toggle visibility of volume control.

- [ ] **Investigate ConcatenatingAudioSource:** explore using `ConcatenatingAudioSource` in `just_audio` for better gapless playback and playlist management.
- [ ] **Smart Random Setting**: Add a setting to toggle whether "Automated Random (Continuous Play) ignores search filter to pick from full library" (currently enabled by default).
- [ ] **Hide Forward/Reverse Controls:** Add setting to hide Next/Previous track buttons in the player interfaces for a minimalist look.

## Low Priority / Ideas

- [ ] **Google TV Support:** Create a dedicated screen/layout optimized for Google TV and Android TV.

- [ ] **Google Assistant Integration:** Add support for voice commands (e.g., "Hey Google, play a random show on gdar") using App Actions.

- [ ] **Calendar Feature:** View shows by date on a calendar interface (e.g., "On This Day").

- [ ] **Play Count & History**: Consider how to track and display how many times a show has been played. Display only in Rate Dialog or Rated Shows Library (not in Playback Controls).

- [ ] **Search Help**: Add functionality to help users enter month names in the search field (e.g., autocomplete or chips).

- [ ] **Compact Player Mode:** Move the play/pause control to an icon on the currently playing track in the list. When enabled and expanded, do not show any playback controls.
- [ ] **Track Progress Indicator:** Add setting to show a progress indicator on the currently playing track list item. Should not show time labels and must respect the "Hide Track Duration" setting.

- [ ] **Swipe to Block Follow-up:** When using "Swipe to Block" to remove a show, provide an option (or setting) to immediately trigger a new random selection.
- [ ] **RGB Glow Setting:** Add a setting to control/boost the "glow" intensity of the RGB border effect.



- [x] **Move Encore Tracks:** Create a Python script to identify and move end tracks into an 'Encore' set.
  - [x] `remove_encore_prefix.py` handles prefix removal and moving misplaced tracks.
- [x] **Data Cleaning Scripts:**
  - [x] `fix2_with_database.py`: Clean setlist data and generate review lists.
  - [x] `report_review_shnids.py`: Generate lexicographically sorted SHNID lists for review.
  - [x] **Investigate Sequences Following 'Tuning':** Analyze tracks appearing after "Tuning" to identify potential encores or separation issues.
  - [x] **Set 1 Analysis Script:** Created script (`find_set1_encore.py`) to find single-set shows with >12 tracks.
    - [x] Categorized matches into: (1) "Encore" in title, (2) "Tuning" in middle, (3) Neither.
    - [x] Generated detailed report `report_set1_enc.md` including full track lists and set names.
    - [x] Generated single minified JSON output `set1_matches.json`.
  - [ ] **Review Set 1 Candidates:** Manually review `set1_matches.json` and split sets where appropriate.
- [x] **Refined Usage Instructions:**
  - [x] Improved line breaking (no widows/orphans).
  - [x] Enhanced typography (bold keywords).
  - [ ] Ensure "Long-press" starts on a new line in usage instructions.
- [ ] **Rated Shows Export/Import:** Allow exporting/importing the library of rated shows (dates, shnids, played status, star ratings), possibly via a calendar format or JSON file.
- [ ] **Storage Mechanism Investigation:** Investigate possible better ways to store settings and rated shows (e.g., Hive, drift/SQLite) instead of SharedPreferences/JSON files for scalability.
  - [ ] **Pre-populated Database:** converting `shows.json` to a pre-built database (Hive/Drift) shipped in assets to eliminate first-run JSON parsing lag.
- [x] **Venue Name Cleaning:** Trim venue name by "," or " - ", keeping the name as `venue` and moving the trimmed part to a new `location` attribute.
- [x] **"Grateful Dead at" Cleanup:** Create a script to report shows starting with "Grateful Dead at", then investigate trimming this prefix in the database.
- [x] **Duplicate Track Cleanup:**
  - [x] Created `fix_duplicate_tracks.py` to identify and remove highly redundant tracks (1.5x ratio).
  - [x] Refined logic to check **Name + Duration** for accuracy.
  - [x] Implemented robust normalization (unescaping, stripping transition markers like `-`, `\`, `;`).
  - [x] Automated exclusion of **VBR tracks** from fixed sources.
  - [x] Generated detailed audit reports (`dup_fix_report.md`).
- [x] **VBR Track Audit:**
  - [x] Created `find_vbr_tracks.py` to globally report on remaining `_vbr.mp3` usage.
  - [x] Generated `vbr_report.md` for baseline analysis.
- [x] **Mixed VBR Cleanup:**
  - [x] Created `clean_mixed_vbr_sources.py` to strip VBR tracks from 128 "mixed quality" sources.
  - [x] Removed 2,388 VBR tracks and saved to `output.optimized_src_vbr_cleaned.json`.
  - [x] Generated `vbr_cleaning_report.md` with detailed counts.

