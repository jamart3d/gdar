# Pending Release Notes
[Unreleased] entries will be moved to CHANGELOG.md during the next /shipit run.

## [Unreleased]
- Web/Fruit PWA settings: turning car mode on now enables abbreviated month
  labels and disables day-of-week display, and the same compact date
  preferences are restored on startup when car mode is already persisted.
- Web/Fruit car mode: removed embedded player controls and duration text from
  the current show card in the PWA show list, keeping the footer focused on the
  now-playing track title.
- Web/Fruit car mode: added a compact real playback progress strip with a pulse
  indicator below the current track title on the active show card, with tighter
  spacing between the date/meta block and now-playing track details.
- Web/Fruit car mode: tightened non-current show cards in the PWA show list by
  reducing idle card height, vertical padding, and excess internal gap.
- Web/Fruit car mode: allow the current show card to grow when needed so long
  venue text can wrap without squeezing the rest of the active-card layout.
- Web tests: expanded `packages/shakedown_core/test/widgets/show_list_card_test.dart`
  to cover the Fruit car mode current-card footer, compact progress/pulse,
  tighter idle-card sizing, and venue-wrap growth behavior.
- Web/Fruit: added a visible-playback stall watchdog to the HTML5 engine so
  progress and duration updates recover even when the normal RAF-driven state
  emission loop stalls while the tab remains visible.
- Web/Hybrid: mirrored the same visible-stall watchdog in the hybrid HTML5
  background engine path to keep hybrid playback state updates resilient.
- Web tests: added `apps/gdar_web/web/tests/visible_stalled_progress_regression.js`
  to cover the visible-stall case that was not previously verified.
- Web tests: repaired `apps/gdar_web/web/tests/run_tests.js` so the browser
  regression harness now runs cleanly, executes both stalled-progress
  regressions, and exits with a real success/failure status.
