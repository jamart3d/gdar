# Verification Script Detail: `verify_fonts.py`

This document details the automated testing coverage provided by `scripts/verify_fonts.py`. The script uses ADB and Deep Links to drive the application through various states, capturing screenshots for visual verification of layout, font scaling, and functionality.

## Test Matrix
The script iterates through the following combinations:
1.  **Fonts**: `Default` (Roboto), `Rock Salt`
2.  **UI Scales**: `1.0x` (Standard), `1.2x` (Large Text/Display)

Total permutations: 4 (Default/1x, Default/1.2x, Rock Salt/1x, Rock Salt/1.2x).

## Execution Flow

### Phase 1: Setup & Environment (Per Permutation)
The script iterates through each Font and Scale combination, resetting the app state each time.

1.  **Reset Application**: Clears all user preferences to ensure a clean state.
    *   Command: `shakedown://debug?action=reset_prefs`

2.  **Onboarding (Pages 1-3)**
    *   Action: Navigate explicitly to Onboarding screen (simulating fresh install).
    *   Deep Link: `shakedown://navigate?screen=onboarding`
    *   **Screenshots**: 
        *   `onboarding_p1_{font}_{scale}.png` (Welcome)
        *   `onboarding_p2_{font}_{scale}.png` (Tips - via swipe)
        *   `onboarding_p3_{font}_{scale}.png` (Setup - via swipe)

3.  **Splash Screen**
    *   Action: Navigate to Splash screen.
    *   Deep Link: `shakedown://navigate?screen=splash`
    *   **Screenshot**: `splash_{font}_{scale}.png`

4.  **Complete Onboarding**: Bypasses the onboarding screen to reach the main UI for the rest of the tests.
    *   Command: `shakedown://debug?action=complete_onboarding`

5.  **Start Playback**: Initiates random playback to ensure the MiniPlayer and Sliding Panel are active during all tests.
    *   Command: `shakedown://play-random`

### Phase 2: Scenario Verification

#### A. Home & Search
1.  **Home Screen (Initial)**
    *   Action: Home screen verification before playback/mini-player is active.
    *   Deep Link: `shakedown://navigate?screen=home`
    *   **Screenshot**: `home_initial_{font}_{scale}.png`
2.  **Home Screen (Standard)**
    *   Action: Navigate to Home (with Mini-Player active).
    *   Deep Link: `shakedown://navigate?screen=home`
    *   **Screenshot**: `home_{font}_{scale}.png`
2.  **Search Field (Open)**
    *   Action: Trigger search field visibility.
    *   Deep Link: `shakedown://navigate?screen=home&action=search`
    *   **Screenshot**: `home_search_open_{font}_{scale}.png`
3.  **Track List**
    *   Action: Open a specific show (Index 10) to verify accurate track listing layouts.
    *   Deep Link: `shakedown://navigate?screen=track_list&index=10`
    *   **Screenshot**: `track_list_{font}_{scale}.png`

#### B. Settings Expansion
Tests the scalability and layout of expandable settings cards. For each section, the app is first reset to the Home screen to ensure a fresh navigation stack.

1.  **Usage Instructions**
    *   Deep Link: `shakedown://navigate?screen=settings&highlight=usage_instructions`
    *   **Screenshot**: `settings_usage_instructions_{font}_{scale}.png`
2.  **Appearance**
    *   Deep Link: `shakedown://navigate?screen=settings&highlight=appearance`
    *   **Screenshot**: `settings_appearance_{font}_{scale}.png`
3.  **Interface**
    *   Deep Link: `shakedown://navigate?screen=settings&highlight=interface`
    *   **Screenshot**: `settings_interface_{font}_{scale}.png`
4.  **Random Playback**
    *   Deep Link: `shakedown://navigate?screen=settings&highlight=random_playback`
    *   **Screenshot**: `settings_random_playback_{font}_{scale}.png`
5.  **Playback**
    *   Deep Link: `shakedown://navigate?screen=settings&highlight=playback`
    *   **Screenshot**: `settings_playback_{font}_{scale}.png`
6.  **Collection Statistics**
    *   Deep Link: `shakedown://navigate?screen=settings&highlight=collection_statistics`
    *   **Screenshot**: `settings_collection_statistics_{font}_{scale}.png`

#### C. Player & Controls
Tests the full-screen player states.

1.  **Playback Messages (ON)**
    *   Action: Enable Messages, Launch Player with **Panel Open**.
    *   Deep Link 1: `shakedown://settings?key=show_playback_messages&value=true`
    *   Deep Link 2: `shakedown://navigate?screen=player&panel=open`
    *   **Screenshot**: `player_msg_on_{font}_{scale}.png`

2.  **Player Panel (OPEN)**
    *   Action: Launch Player with Show List/Queue Panel Expanded (Baseline).
    *   Deep Link: `shakedown://navigate?screen=player&panel=open`
    *   **Screenshot**: `player_panel_open_{font}_{scale}.png`

## Deep Link Reference
New deep links added to support this verification plan:
- `shakedown://navigate?screen=onboarding`: Explicitly launches the Onboarding screen.
- `shakedown://navigate?screen=home&action=close_search`: Programmatically closes the search bar.
- `shakedown://settings?key={key}&value={bool}`: Toggles boolean settings instantly.
- `shakedown://player?action={pause|play|stop}`: Controls audio playback state. `stop` simulates a long-press on play/pause (Stop & Clear).

## Output Artifacts (Screenshot Manifest)

The script generates the following screenshots for each Font/Scale permutation:

1.  `onboarding_p1_{font}_{scale}.png`
2.  `onboarding_p2_{font}_{scale}.png`
3.  `onboarding_p3_{font}_{scale}.png`
4.  `splash_{font}_{scale}.png`
5.  `home_{font}_{scale}.png`
6.  `home_search_open_{font}_{scale}.png`
7.  `track_list_{font}_{scale}.png`
8.  `settings_usage_instructions_{font}_{scale}.png`
9.  `settings_appearance_{font}_{scale}.png`
10. `settings_interface_{font}_{scale}.png`
11. `settings_random_playback_{font}_{scale}.png`
12. `settings_playback_{font}_{scale}.png`
13. `settings_collection_statistics_{font}_{scale}.png`
14. `player_msg_on_{font}_{scale}.png`
15. `player_panel_open_{font}_{scale}.png`

