# Pending Release Notes
[Unreleased] entries will be moved to CHANGELOG.md during the next /shipit run.

## [Unreleased]
- Web Fruit settings header: added dedicated `Keep Screen On` button to the left
  of Car Mode in the custom Fruit header actions.
- Decoupled Fruit settings header Car Mode toggle from `Prevent Sleep` so each
  control is independent.
- Fruit playback inline card (`fruit_now_playing_card.dart`) updates:
  - Non-car mode: transport layout changed to `prev | play/pause | next` on the
    left, duration stays right-aligned, long track titles now marquee when
    enabled.
  - Audio HUD mode: applied the same `prev | play/pause | next` transport
    cluster behavior.
- Fruit stacked/mobile show-list current card tuning:
  - Reduced excess height for car-mode current cards when footer content is not
    visible (`fruit_car_mode/fruit_card_layout.dart`).
  - Adjusted stacked non-car current-card inline player lane width/right inset
    for better left/right visual balance (`show_list_card_fruit_mobile.dart`).
- Show-list embedded inline mini-player title now uses `ConditionalMarquee` so
  long track names scroll instead of truncating (`embedded_mini_player.dart`).
