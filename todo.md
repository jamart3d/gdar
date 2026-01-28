# gdar - To-Do List

This file tracks planned features, enhancements, and bug fixes for the gdar application.

## High Priority

- [ ] **UI Scale & Layout Consistency:**
  - **Requirement:** Ensure font size and scaling behavior matches the verified Settings screen.
  - **Status:** Settings screen verified. Logic needs to be applied/verified in:
    - [x] **Show List Screen:** `ShowListCard` (in progress).
    - [x] **Playback Screen:** Ensure title/headers respect the toggle.
    - [x] **Sliding Panel (Expanded):** When panel creates the full player view.
    - [x] **Rated Shows Library Screen:** Ensure list items respect the toggle.
  - **Note:** Four fonts and UI scale are verified good in Settings.

- [x] **Unit Tests:** Write unit tests for providers (`AudioProvider`, `ShowListProvider`) to ensure business logic is correct.
  - [x] **Test Architecture Refactor:** Extract SHNID/track parsing logic from `AudioProvider.playFromShareString` into pure functions (`ShareLinkParser`) for easier unit testing.
- [x] **Widget Tests:** Write widget tests for critical UI components like `ShowListCard` and `PlaybackScreen`.
- [x] **Error Handling:** Implement more robust error handling for audio playback (e.g., show a snackbar if a track URL is invalid or network fails).
- [x] **App Startup:** Refactor startup to be synchronous, remove initial loading screen, and respect splash screen setting immediately.
- [x] **Random Show:** Ensure app scrolls to and expands the random show when "Play Random Show on Startup" is enabled.
- [x] **App Icon:** Update application icon.
- [x] **Bug Investigation:** Check into why RGB border is not visible on Android 16 vs 15.
- [x] **Album Art:** Update default album art to `assets/images/t_steal.webp`.
- [x] **Deep Sleep Buffering:** Investigate "track buffers and does not play" issue during deep sleep.
  - **Goal:** Ensure the next track is fully buffered before playback starts to prevent stalling when the OS restricts network/CPU in deep sleep.
  - **Solution:** Implemented `LockCachingAudioSource` as a toggleable "Offline Buffering" setting.
  - **Status:** Completed. Toggle added to Settings -> Playback. Cache clears on startup.
  - [ ] **Enhancement:** Add periodic timer to update cache count in real-time as tracks are cached (currently only updates on cleanup/source change).

- [ ] **Shakedown Animation:**
  - **Requirement:** Implement an expressive "shake" animation for the `ShakedownTitle` when it reaches the AppBar (after splash transition).
  - **Style:** Material 3 expressive, dampened spring/sine wave.


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

- [x] **Clipboard Playback Feedback:** Replaced countdown with immediate playback and a SnackBar notification for a faster, "snappier" user experience.

- [x] **Quick Block:** Left swipe on a Show Card (for single source shows) or an individual Source Item (for multi-source shows) to instantly mark it as "Red Star" (Blocked). Handles stopping playback and provides undo options.

- [ ] **Smart Clipboard Integration:**
  - **Feature:** Automatically detect Archive.org share links in clipboard on app resume.
  - **Behavior:** Show a SnackBar or Dialog: "Found show [Show Name]. Play?".
  - **Feasibility:** Implement `WidgetsBindingObserver` to detect `AppLifecycleState.resumed`, then access `Clipboard.getData` to parsing URL.

- [x] **Clipboard Playback:** Feature to parse a shared show/track string from the clipboard and instantly play that specific track/position.

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
    - [ ] **Confirmation for Red Star:** Always ask for confirmation when selecting "Block (Red Star)", even if unrated.
    - [x] **Rated Shows Library**: Added dynamic counts to each tab label (e.g., "Played (5)").
    - [ ] **Data Sharding:** Split the monolithic JSON data by year (e.g., `years/1972.json`) and use a lightweight master index to improve app startup performance and reduce memory usage.
 

- [x] **Smart Random Playback**:
  - Manual Random (Button) respects search filter.
  - Automated Random (Continuous Play) ignores search filter to pick from full library.

- [ ] **UI Polish:** Refine animations and transitions for an even smoother feel.
- [ ] **3D Rotating Stars:** Animate rating stars by rotating them around their Y-axis to give a 3D effect.
- [x] **Font Selection:** Add setting to choose the handwriting font. Options: Caveat, Permanent Marker, Rock Salt.
- [x] **Fix highlight:** With Dark Mode + Dynamic Color + Glow Border: Fix issue where glow is uniform on all shows, and missing when expanded. Implement "half glow" for all, and "regular glow" for current show/shnid.
- [x] **RGB Animation Persistence:** Investigate options to prevent the RGB border animation from resetting/restarting when navigating between screens (e.g. Playback -> Settings -> Playback).
  - **Root Cause:** `AnimatedGradientBorder` manages its own `AnimationController` locally. Navigation rebuilds the widget, resetting rotation to 0. Additionally, navigating between `PlaybackScreen` via `MaterialPageRoute` caused a "pop" due to default transitions not matching the `ShowListScreen`'s instant transition.
  - **Solution:**
    - **Global Animation:** Lifted animation state to `RgbClockWrapper` (Provider) so all borders sync to a single continuous `AnimationController`.
    - **Targeted Pause/Resume:** Explicitly pause the global controller (`.stop()`) *before* pushing `SettingsScreen` and resume (`.repeat()`) *after* returning to ensure seamless continuity without visual resets.
    - **Independent Preview:** Updated `SettingsScreen` preview to use a local controller (`ignoreGlobalClock: true`) so it animates while the global clock is paused.
    - **Consistent Navigation:** Switched `PlaybackScreen` -> `SettingsScreen` navigation to `PageRouteBuilder` with `Duration.zero` (instant) to match `ShowListScreen` behavior, eliminating the visual "pop".
  - **Verification:** Manually verified seamless transitions and animation continuity between Show List, Playback, and Settings screens. Unit testing full navigation proved complex due to layout dependencies, but the logic is covered by the manual verification plan.

- [ ] **Settings UX Enhancement:**
  - [ ] When user enables "Play Random Show on Completion" in Settings → Random Playback, suggest also enabling "Advanced Cache" (Settings → Playback) to improve playback reliability while device sleeps.
  - **Implementation:** Show a SnackBar or Dialog with message: "For best results during deep sleep, consider enabling Advanced Cache in Playback settings."
  - **Benefit:** Proactively guides users to optimal configuration for continuous random playback.

- [ ] **Improve Playback Controls:** Enhance the layout and interactivity of controls in the Playback Screen.
  - [ ] **Venue Name Positioning:**
    - [ ] Add setting to display venue name under the date in Playback Screen appbar.
    - [ ] Move venue name in Playback Controls (expanded) to just above the date.
    - [ ] Hide venue name in Playback Controls when collapsed.
  - [x] **Buffering Indicator:** Ensure the buffering indicator on the open sliding panel (Play/Pause button) matches the style of the miniplayer's indicator.
  - [x] **Playback Controls:** Refactor `PlaybackControls` to use a filled-circle container design matching `MiniPlayer`, ensuring consistent buffering indicators and increasing the button size.
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

- [ ] **Staggered List Motion:** Animate ShowListCards sliding/fading in when the list loads or search results update for a fluid, premium feel.

- [ ] **Random Icon Animation:** When going from splash screen to show list screen, make the select random button (question mark) pulse in a Material 3 design way until it's been used once (per app start).

- [ ] **Miniplayer Fix:** Fix miniplayer rebuild when navigating between shows screen and track list screen, or integrate it better with the playback controls from the playback screen.

- [ ] **Miniplayer Visibility:** Ensure miniplayer remains visible when search bar is active (expanded) but the keyboard is dismissed, provided there is an active track.

- [ ] **Volume Control:**
  - Add volume slider/control to Playback Screen controls.
  - Add setting in Playback Settings to toggle visibility of volume control.

- [x] **Gapless Playback:** Refactor to use `AudioPlayer.setAudioSources` (fixing `ConcatenatingAudioSource` deprecation) to ensure true gapless playback by default for all shows.
- [ ] **Smart Random Setting**: Add a setting to toggle whether "Automated Random (Continuous Play) ignores search filter to pick from full library" (currently enabled by default).

- [x] **Native Pre-Queueing (Deep Sleep Fix):** Implement Option 1 (pre-queueing the next show).
    - [x] **Trigger:** Queueing the next show at the **START** of the last track to guarantee ample processing time.
    - [x] **Benefit:** Eliminates the silence gap and prevents Android 14+ from killing the app.
    - *Synergy:* This naturally builds a historical playlist in the native player.

- [ ] **Playback Undo / History:**
    - **Concept:** Since we are continually appending items to the playlist (Native Pre-Queueing), we effectively have a history trail.
    - **Feature:** "Undo" button (Snackbar/UI) jumps back to the previous track/show in the playlist sequence.
    - **History View:** A setting/screen to list the sequence of played shows, leveraging this underlying playlist history.
    - **Constraint:** Requires app visibility for the UI, but the underlying data is already there.

- [ ] **Hide Forward/Reverse Controls:** Add setting to hide Next/Previous track buttons in the player interfaces for a minimalist look.

- [x] **Android Caching:** Implement `LockCachingAudioSource` for Android platform to enable full-file buffering.

- [ ] **Restrict Playback Navigation:** Ensure Next/Previous buttons in `MiniPlayer` and `PlaybackControls` only navigate within the current source/show.
  - **Feature:** Add a **Setting** to toggle this behavior (Default: TBD).
  - **Behavior (Enabled):** The "Previous" button is grey/inactive at the first track; "Next" button is grey/inactive at the last track of the *current show*.
  - **Behavior (Disabled):** Buttons allow seamless navigation into the pre-queued/history tracks (crossing show boundaries).

## Low Priority / Ideas

- [ ] **Google TV Support:** Create a dedicated screen/layout optimized for Google TV and Android TV.

- [x] **Google Assistant Integration:** Add support for voice commands (e.g., "Hey Google, play a random show on gdar") using App Actions.
  - [x] **Deep Link Consistency:** Ensured deep link actions wait for show list data initialization to resolve playback race conditions during cold start.
  - [ ] **User Instructions:** Add a section in Settings (or a Help dialog) explaining available voice commands ("Play random show") and deep link capabilities.
  - [ ] **Gemini Listing:** Investigate requirements for getting the app listed in "Gemini Connected Apps" (or equivalent discovery surfaces).
  - [ ] **Deep Link Intent Audit:** Create a report of all deep link intents in the app, separating testing intents from production ones.

- [ ] **Calendar Feature:** View shows by date on a calendar interface (e.g., "On This Day").

- [x] **Play Count & History**: Track how many times a show has been played.
    - *Synergy:* Can play off the "History View" logic from Native Pre-Queueing.
    - Display only in Rate Dialog or Rated Shows Library (not in Playback Controls).

- [x] **Search Help**: Add functionality to help users enter month names in the search field (e.g., autocomplete or chips). Updated to search location as well.

- [ ] **Compact Player Mode:** Move the play/pause control to an icon on the currently playing track in the list. When enabled and expanded, do not show any playback controls.
- [ ] **Track Progress Indicator:** Add setting to show a progress indicator on the currently playing track list item. Should not show time labels and must respect the "Hide Track Duration" setting.
- [ ] **Marquee Control:** In playback screen, when "Show Track Number" is enabled and a track title marquees, the track number itself should NOT marquee (stay fixed).

- [ ] **Swipe to Block Follow-up:** When using "Swipe to Block" to remove a show, provide an option (or setting) to immediately trigger a new random selection.
- [ ] **Swipe to Block Undo Animation:** When undoing a block (restoring the show), animate the "opposite" of the block action slowly for clear feedback.

- [x] **RGB Glow Setting:** Add a setting to control/boost the "glow" intensity of the RGB border effect.


- [ ] **User Data Backup & Restore:**
  - **Feature:** Export and import all user data (ratings, played status, play counts, listening history) to/from a JSON file.
  - **Data Source:** Serialize all Hive boxes (`ratings`, `play_counts`, `user_history`) into a single backup file.
  - **UI Location:** Settings → rated shows library, in appbar  export / import button.
  - ** modal ui for export / import** file picker, , option to save out as a calendar
  - **Export:** Generate timestamped JSON file (e.g., `shakedown_backup_2026-01-22.json`) saved to Downloads.
  - **Import:** Allow users to select a backup file and restore their data, with confirmation dialog showing what will be overwritten.
  - **Benefit:** Enables users to backup their listening history and restore it on new devices or after app reinstall.

- [ ] **Show List Card Scaling Verification & Fixes:**
  - **Problem:** "Too Big" text collisions and inconsistent spacing when UI Scale is enabled with various legacy fonts.
  - **Plan:**
    1. **Infrastructure (The "ADB Bridge")**
       - [x] **Implement MethodChannel:** Create a listener in `MainActivity.kt` for the ADB broadcast `com.jamart3d.shakedown.SET_UI_SCALE` to toggle `settingsProvider.uiScale` instantly without restarting the app.
       - [x] **Connect Flutter State:** Ensure the `settingsProvider` notifies listeners so the `ShowListCard` rebuilds immediately when the ADB command is sent.

    2. **Font Consistency Audit & Fixes (In Progress)**
       - [x] **Standardize Onboarding Base Sizes:** Bump Onboarding body text (9.5 -> 14.0) and headers (10.5 -> 16.0) to match app standards.
       - [x] **Splash Screen Scaling:** Apply `FontLayoutConfig` scale factor to Splash Screen checklist items so they respect the UI Scale setting.
    - [x] **Splash Screen Optimization:** Reduce font size of checklist items when UI Scale is enabled to prevent overflow/clipping.
    - [x] **Settings Screen Optimization:** Reduce font size for "Rock Salt" font in Settings screen when UI Scale is enabled (it's currently a bit too large).
    - [x] **Playback & Sliding Panel Audit:**
      - [x] Audit font and control sizes for "Caveat" font in `PlaybackScreen` and sliding panel (open/close).
      - [x] Fix: Reduce control sizes when sliding panel is open (currently too large).
      - [x] **Roboto Font Audit:** Reduced control sizes by ~25% in `PlaybackScreen` when sliding panel is open for Default (Roboto) font.
      - [x] **Caveat & Messages Audit:** Reduced control sizes by ~25% for Caveat and optimized playback status messages font size when `UI Scale` is ON.
       - [x] **Settings Screen Normalization:** Bump base font sizes (10.0->15.0, 8.5->12.0) to matched Material standards.
       - [x] **Font Preview Fix:** Ensure font selection dialog respects the current UI scale factor.
       - [x] **Density Tuning:** Relax extreme visual density (`vertical: -4`) to accommodate larger fonts without cramping.
       - [x] **Centralized Typography:** Create `AppTextStyles` helper to unify font scaling logic and eliminate ad-hoc `fontSize * scale` calculations.

    3. **Layout Logic (Fixing "Too Big" Collisions)**
        - [ ] **FittedBox Candidate 1 (Playback Screen Track List):** Move track title to FittedBox(ConditionalMarquee) to match header scaling logic.
        - [ ] **FittedBox Candidate 2 (Source List Item):** Use FittedBox for Source ID text to prevent wrapping and maintain valid list item height.
        - [ ] **FittedBox Candidate 3 (Show List Card Header):** Use FittedBox for Venue/Date header text to prevent wrapping and maintain valid card height.
       - [ ] **Kill the "Double-Scaling" Bug:**
         - Wrap the Venue and Date text widgets in a `SizedBox` with a fixed height (e.g., `height: 32.0 * scaleFactor`).
         - **Crucial:** Set `textScaleFactor: 1.0` inside these widgets. This ensures that the system font size doesn't multiply with your 1.5x factor, which is currently causing the "Too Big" vertical overlap.
       - [ ] **Enforce Vertical "Lanes":**
         - Use a `Column` with `MainAxisSize.min`.
         - Place a `SizedBox(height: 2.0 * scaleFactor)` between the two rows to guarantee the gap remains regardless of font size.
       - [ ] **Refine Marquee Triggers:**
         - Ensure the horizontal Marquee is wrapped in a `ClipRect` so that if the text expands vertically (due to descenders like 'g' or 'y'), it doesn't bleed into the other row's space.

    3. **Systematic Testing (The ADB Audit)**
       - [x] **Create "8-Look" Audit Script:** Script created at `tool/adb_ui_scale_test.py` to generate screenshots for 4 standard system font sizes (0.85, 1.0, 1.15, 1.3) crossed with `uiScale` (True/False).
       - [x] **Create "Trigger Point" Script:** Script created at `tool/adb_trigger_point_test.py` using fine-grained font increments (1.0 to 1.5, step 0.05) to find exactly when the text becomes "too big" and triggers the Marquee.
       - [ ] **Run Scripts and Generate Screenshots:** Execute both scripts with device connected to capture test screenshots.
       - [ ] **Visual Verification:** Check that the Marquee only activates horizontally and that the vertical gap between "Venue" and "Date" never shrinks to 0px.

    4. **Final Goal:**
       - [ ] **Achieve "Fluid Scaling":**
         - **Case A (Small):** Text is static, gap is clear.
         - **Case B (Medium):** Text fills width, gap is clear.
         - **Case C (Too Big):** Marquee activates horizontally, vertical height is locked to the card's `82.0 * scaleFactor`, gap is strictly preserved.
       - [ ] **Smart Abbreviation:** When checking "UI Scale" on, automatically enable "Abbreviate Day & Month" (if not already handled) to save space.

    5. **Normalization of Font Logic (Refactoring)**
       - **Problem:** Currently, font-specific adjustments (e.g., "reduce Caveat by 15% in panel") are scattered across multiple files (`playback_controls.dart`, `playback_screen.dart`, `onboarding_screen.dart`).
       - **Plan:** Centralize this logic into `FontLayoutConfig` or `AppTypography`.
       - **Action Items:**
         - [ ] Move "Open Panel" font scaling factors (0.75 for Caveat/Default, 0.85 for others) into `FontLayoutConfig`.
         - [ ] Move "Status Message" sizing logic into a shared helper or style definition.
         - [ ] Create a specific `onboarding` font configuration in `FontLayoutConfig` to handle the Caveat reduction systematically rather than with ad-hoc `if` statements in the view.
         - [ ] Ensure `AppTypography.responsiveFontSize` accepts a `context` (screen type) argument to apply these context-aware rules automatically.
         - [ ] **Normalize Line Height:** Centralize `height` property logic (currently hardcoded as `1.2`, `1.4` etc. in various places) into `AppTypography` to ensure consistent vertical rhythm across fonts.
         - [ ] **Handle "Optical" Weight:** Adjust `FontWeight` per font (e.g. `FontWeight.w400` vs `w500`) to ensure they visually match in "heaviness", especially when scaled.
         - [ ] **Implement a "Cap" on Text Scaling:** Ensure that critical UI elements (like headers or navigation bars) have a maximum font size multiplier (e.g., max 1.5x) to prevent them from breaking layout even if the system scale is set very high (e.g. 2.0x).
         - [ ] **Test `auto_size_text`:** Evaluate using the `auto_size_text` package for fixed-size containers (like buttons) where text *must* fit without overflowing, rather than scaling up indefinitely.
         - [ ] **Use `TextTheme.apply()`:** Instead of manually creating new `TextStyle` objects everywhere, use `TextTheme.apply(fontFamily: ...)` to propagate font changes cleanly through the widget tree.

- [x] **Onboarding Page:**
  - **Feature:** Display an onboarding/welcome screen on first app launch.
  - **Content:**
    - **App Description:**
      - "Shakedown - Stream thousands of Grateful Dead concerts from the Internet Archive"
      - Key features: Browse by date, rate shows, track listening history, gapless playback
      - Customize with fonts and UI scale
    - **Usage Instructions:**
      - **Browse**: Explore concerts by date in the main list
      - **Search**: Find shows by date, month, venue, or location
      - **Random**: Tap the ? icon in app bar for random show
      - **Rating**: Tap stars (1-3), red star = blocked, grey = played/unrated
      - **Playback**: Long-press source for quick play, single tap to browse tracks
      - **Collection**: Access rated shows from Settings → Rated Shows Library
      - **Tips**: Enable UI Scale for larger text, choose preferred font
    - **Font Selection:**
      - Display list of all available fonts with preview text
      - Allow user to select preferred font
      - Set default font if none selected
      - Apply selection immediately to preview
    - **UI Scale Option:**
      - Show UI scale toggle/slider
      - Preview the scale change in real-time
    - **Thanks for Testing Message:**
      - "Thanks for testing Shakedown! Your feedback helps improve the app."
  - **Behavior:**
    - Show on first launch
    - Include "Don't show again" option
    - Re-show if onboarding content is updated (version tracking)
  - **Storage:** Store onboarding version/completion status in Hive or SharedPreferences.
  - **UI:** Use a multi-page carousel or single scrollable page with dismiss button.



## Footprint Reduction

- [ ] **Font Optimization:** Verify `google_fonts` usage. Bundling frequently used weights (Inter/Roboto) as assets can rely less on runtime caching and network calls.
- [ ]  Ensure `flutter build --release` effectively tree-shakes unused icon code points (SettingsProvider uses simple booleans, but large icon sets can bloat).



## Data & Persistence Architecture (Completed)

**Implemented: Hybrid Data Architecture**
Balanced app size with performance and robust user data storage.

- [x] **Show Catalog (JSON):** Kept the generic compressed JSON (`assets/data/output.optimized_src.json`) as the source of truth to avoid doubling app size.
- [x] **User Data (Hive):** Added Hive for efficient, persistent storage of user-generated content:
  - Ratings (0-3 stars, Blocked)
  - Date & Source IDs
- [x] **CatalogService:** Created a unified service that:
  - Loads JSON in a background isolate (`compute`) to prevent UI jank.
  - Manages the Hive `ratings` box.
  - Provides a single source of truth for the app's data.
- [x] **Provider Refactor:** Updated `ShowListProvider` to consume `CatalogService` instead of the legacy single-file service.
- [x] **Unit Tests:** Added specific tests for `CatalogService` parsing logic (venue unification, source merging).

### Audio Buffering Behavior Analysis (Documentation)
*   **Start of Playback**:
    *   `AudioProvider` calls `setAudioSource(preload: true)`.
    *   Player state: `idle` → `loading` → `buffering`.
    *   Playback begins when buffer reaches `initialPlaybackStartTimeMs` (2500ms).
*   **Mid-Playback**:
    *   Buffer depletion triggers `buffering` state (pauses playback).
    *   Resumes automatically when rebuffer threshold is met.
*   **Foreground vs. Background**:
    *   Execution is identical (`Foreground Service`).
    *   Background may experience OS throttling (Data Saver/Battery), potentially causing more frequent stalls.




## Maintenance & Technical Debt

- [ ] Refactor `AudioPlayer` state management logic
- [ ] **Deprecation Cleanup:** `ConcatenatingAudioSource` is deprecated in `just_audio` 0.10.0+. Use `AudioPlayer.setAudioSources(List<AudioSource>)` instead. Ensure no new code uses the deprecated class.

### Storage Architecture Enhancements (Post-Hive Migration)



- [x] **Code Cleanup:** Removed commented-out legacy getters/fields in `SettingsProvider` after migration to `CatalogService`.


## Design Audit: Expressive Material 3 (Settings Screen)

- [ ] **SectionCard Refinement:**
  - [ ] Increase corner radius to 28 (M3 Extra Large).
  - [ ] Update title typography to `titleLarge` for better hierarchy.

- [ ] **Collection Statistics Dashboard:**
  - [ ] Convert linear list to a 2-column Grid Layout for key stats (Shows, Songs, Runtime).
  - [ ] "Stat Cards": Container with large number, small label.

- [ ] **Expressive Interactive Elements:**
  - [ ] **Glow Slider:** Add dynamic label or discrete tick marks.
  - [ ] **Source Badges:** Add tactile feel / scale animation on press.
  - [ ] **Navigation:** Use `OpenContainer` or M3 transitions for sub-screens ("Manage Rated Shows", "About").

- [ ] **Typography Alignment:** Map headers/labels to M3 Type Scale (`labelSmall`, `bodyMedium`, `titleLarge`) while respecting `scaleFactor`.


