# TODO: Fix Google TV White Background Issues

## Completed Investigation
- [x] Trace why screensaver is white in Google TV UI
    - [x] Investigate screensaver implementation files
    - [x] Check shader files for background color logic
    - [x] Check TV-specific logic in `DeviceService` or elsewhere
    - [x] Identify cause: `SplashScreen` hardcoded background & `ThemeProvider` defaulting to Light.

## Pending Tasks
- [ ] Review implementation plan
- [x] Fix Deprecated Color Getters in `lib/steal_screensaver/steal_background.dart`
- [ ] Implement Changes:
    - [ ] Update `lib/ui/screens/splash_screen.dart` to use theme background color.
    - [ ] Update `lib/ui/widgets/tv/tv_dual_pane_layout.dart` to force `Colors.black` scaffold background.
    - [ ] Update `lib/providers/theme_provider.dart` to default to Dark mode on TV.
    - [ ] Update `lib/main.dart` to pass `isTv` to `ThemeProvider`.
- [ ] Verify the fix
    - [ ] Run automated tests.
    - [ ] Manual verification on Google TV.
