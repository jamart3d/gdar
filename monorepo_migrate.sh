#!/bin/bash
set -e

# Setup dirs
mkdir -p packages/shakedown_core/lib/ui
mkdir -p apps/gdar_mobile/lib/ui
mkdir -p apps/gdar_fruit/lib/ui
mkdir -p apps/gdar_tv/lib/ui

# Move core logic to shakedown_core
for dir in audio config providers services steal_screensaver utils visualizer; do
    if [ -d "lib/$dir" ]; then
        cp -r "lib/$dir" "packages/shakedown_core/lib/"
    fi
done
cp lib/hive_registrar.g.dart packages/shakedown_core/lib/ || true

# Specifics
M3="widgets/show_list/fast_scrollbar.dart widgets/onboarding/update_banner.dart"
FRUIT="widgets/theme/fruit_activity_indicator.dart widgets/theme/fruit_icon_button.dart widgets/theme/fruit_segmented_control.dart widgets/theme/fruit_switch.dart widgets/theme/fruit_tooltip.dart widgets/theme/fruit_ui.dart widgets/theme/liquid_glass_wrapper.dart screens/fruit_tab_host_screen.dart widgets/fruit_tab_bar.dart widgets/playback/fruit_now_playing_card.dart widgets/playback/fruit_track_list.dart"
TV="widgets/tv screens/tv_settings_screen.dart"
SCREENS="screens/show_list_screen.dart screens/playback_screen.dart screens/settings_screen.dart screens/track_list_screen.dart screens/onboarding_screen.dart screens/splash_screen.dart screens/about_screen.dart widgets/show_list/show_list_body.dart widgets/show_list/show_list_shell.dart widgets/show_list/show_list_card.dart widgets/show_list/show_list_item.dart widgets/source_list_item.dart widgets/show_list_item_details.dart"

for f in $M3; do
    if [ -f "lib/ui/$f" ]; then
        mkdir -p "$(dirname "apps/gdar_mobile/lib/ui/$f")"
        mv "lib/ui/$f" "apps/gdar_mobile/lib/ui/$f"
    fi
done

for f in $FRUIT; do
    if [ -f "lib/ui/$f" ]; then
        mkdir -p "$(dirname "apps/gdar_fruit/lib/ui/$f")"
        mv "lib/ui/$f" "apps/gdar_fruit/lib/ui/$f"
    fi
done

for f in $TV; do
    if [ -e "lib/ui/$f" ]; then
        mkdir -p "$(dirname "apps/gdar_tv/lib/ui/$f")"
        mv "lib/ui/$f" "apps/gdar_tv/lib/ui/$f"
    fi
done

# The screens that use both must go to ALL THREE apps so they can point to their respective specific widgets.
for f in $SCREENS; do
    if [ -e "lib/ui/$f" ]; then
        mkdir -p "$(dirname "apps/gdar_mobile/lib/ui/$f")"
        mkdir -p "$(dirname "apps/gdar_fruit/lib/ui/$f")"
        mkdir -p "$(dirname "apps/gdar_tv/lib/ui/$f")"
        cp "lib/ui/$f" "apps/gdar_mobile/lib/ui/$f"
        cp "lib/ui/$f" "apps/gdar_fruit/lib/ui/$f"
        mv "lib/ui/$f" "apps/gdar_tv/lib/ui/$f"
    fi
done

# Remaining UI goes to core
cp -rn lib/ui/* "packages/shakedown_core/lib/ui/" || true

# Now fix the dependencies that we moved that are required in other screens
# We don't want to overcomplicate. If they need something from `gdar_mobile`, they must be in `gdar_mobile`.
