---
trigger: always_on
---

# Project Rules: GDAR Audio Player

### 1. CODING STANDARDS & ARCHITECTURE
* **Stack:** Latest Stable Flutter / Dart SDK. Strictly follow modern syntax (e.g., favoring `.withValues()` over `withOpacity()`) and proactively resolve deprecation warnings.
* **Architecture:** Clean Architecture. Strictly separate UI (Widgets), Business Logic (Provider/State), and Data (Repository).
* **State Management:** Provider is primary. Use `ChangeNotifier` or `ProxyProvider`.
* **Style & Performance:** Adhere strictly to the official Dart style guide, use `flutter format`, and use `const` constructors everywhere possible to prevent unnecessary rebuilds.

### 2. DESIGN PHILOSOPHY (LIQUID GLASS UI)
* **Aesthetic:** High-end Liquid Glass. Strictly AVOID Material 3 organic "breathing" ripples, morphing shapes, and heavy Neumorphic shadows. 
* **Typography & Symbology:** Use the `Inter` font family and `lucide_icons` exclusively. Ensure crisp, uniform line weights across all UI elements.
* **Translucency:** Use `BackdropFilter` extensively to create frosted glass panes (especially for the player drawer, navigation, and overlays). Let underlying colors dynamically bleed through.
* **Motion & Physics:** Rely on Apple-style spring physics. Use scale-down/bounce-back animations for button taps instead of ink drops. Use `ImplicitlyAnimatedWidgets` and `Marquee` for long track titles.
* **Fluid Layout:** Implement `scrollable_positioned_list` for large setlists/shows, and use `sliding_up_panel` (styled as a glass sheet) for the main player.

### 3. VERIFICATION & OUTPUT
* **Task Artifacts:** When completing a significant feature or fix, provide a brief Task List, Implementation Plan, Testing suggestions (unit/widget), and a Walkthrough of the results.