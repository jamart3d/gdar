# Phase 0 — Screensaver Selection + Settings Screen

**Project:** gdar_tv — Sheep screensaver  
**Goal:** Add screensaver selection to settings screen, persist choice, route to correct screensaver on idle. SYF stays default and untouched.

---

## Architecture summary

- No DreamService — screensavers are full-screen Flutter widgets launched from MainActivity
- Selection persisted via SharedPreferences
- SYF = default (index 0), Sheep = new option (index 1)
- Sheep has one sub-setting: quality level (Safe / Balanced / Full / Auto)

---

## Step 1 — Add dependency

In `pubspec.yaml`:

```yaml
dependencies:
  shared_preferences: ^2.2.0
```

---

## Step 2 — ScreensaverSettings class

Create `lib/screensaver/screensaver_settings.dart`:

```dart
import 'package:shared_preferences/shared_preferences.dart';

enum ScreensaverType { stealYourFace, sheep }
enum QualityLevel    { safe, balanced, full, auto }

class ScreensaverSettings {
  static const _keySelected = 'screensaver_selected';
  static const _keyQuality  = 'screensaver_quality';

  ScreensaverType selected;
  QualityLevel    quality;

  ScreensaverSettings({
    this.selected = ScreensaverType.stealYourFace, // SYF stays default
    this.quality  = QualityLevel.balanced,
  });

  static Future<ScreensaverSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ScreensaverSettings(
      selected: ScreensaverType.values[prefs.getInt(_keySelected) ?? 0],
      quality:  QualityLevel.values   [prefs.getInt(_keyQuality)  ?? 1],
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySelected, selected.index);
    await prefs.setInt(_keyQuality,  quality.index);
  }
}
```

---

## Step 3 — Screensaver router

Create `lib/screensaver/screensaver_router.dart`:

```dart
import 'package:flutter/material.dart';
import 'screensaver_settings.dart';
import '../syf/steal_your_face_screensaver.dart'; // existing
import 'sheep/sheep_screensaver.dart';             // new (stub for now)

class ScreensaverRouter {
  static Future<void> launch(BuildContext context) async {
    final settings = await ScreensaverSettings.load();

    if (!context.mounted) return;

    switch (settings.selected) {
      case ScreensaverType.stealYourFace:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StealYourFaceScreensaver()),
        );
      case ScreensaverType.sheep:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SheepScreensaver(quality: settings.quality),
          ),
        );
    }
  }
}
```

Replace any existing direct navigation to SYF with `ScreensaverRouter.launch(context)`.

---

## Step 4 — SheepScreensaver stub

Create `lib/screensaver/sheep/sheep_screensaver.dart`:

```dart
import 'package:flutter/material.dart';
import '../screensaver_settings.dart';

class SheepScreensaver extends StatelessWidget {
  final QualityLevel quality;
  const SheepScreensaver({super.key, required this.quality});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'Sheep — quality: ${quality.name}',
          style: const TextStyle(color: Colors.white, fontSize: 32),
        ),
      ),
    );
  }
}
```

This is a placeholder. Replace contents in Phase 3 when the real screensaver is built.

---

## Step 5 — Settings screen UI

Add a screensaver section to your existing settings screen.  
TV-friendly: D-pad navigable, large touch targets, clear selection state.

```dart
import 'package:flutter/material.dart';
import '../screensaver/screensaver_settings.dart';

class ScreensaverSettingsSection extends StatefulWidget {
  const ScreensaverSettingsSection({super.key});

  @override
  State<ScreensaverSettingsSection> createState() =>
      _ScreensaverSettingsSectionState();
}

class _ScreensaverSettingsSectionState
    extends State<ScreensaverSettingsSection> {
  late ScreensaverSettings _settings;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    ScreensaverSettings.load().then((s) {
      setState(() {
        _settings = s;
        _loaded   = true;
      });
    });
  }

  void _selectSaver(ScreensaverType type) {
    setState(() => _settings.selected = type);
    _settings.save();
  }

  void _selectQuality(QualityLevel level) {
    setState(() => _settings.quality = level);
    _settings.save();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Screensaver', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
        const SizedBox(height: 16),

        // Screensaver selector
        _OptionRow(
          label: 'Steal Your Face',
          selected: _settings.selected == ScreensaverType.stealYourFace,
          onSelect: () => _selectSaver(ScreensaverType.stealYourFace),
        ),
        _OptionRow(
          label: 'Sheep',
          selected: _settings.selected == ScreensaverType.sheep,
          onSelect: () => _selectSaver(ScreensaverType.sheep),
        ),

        // Quality sub-setting — only visible when Sheep is selected
        if (_settings.selected == ScreensaverType.sheep) ...[
          const SizedBox(height: 24),
          const Text('Sheep quality', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Row(
            children: QualityLevel.values.map((level) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _OptionRow(
                  label: level.name[0].toUpperCase() + level.name.substring(1),
                  selected: _settings.quality == level,
                  onSelect: () => _selectQuality(level),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String label;
  final bool   selected;
  final VoidCallback onSelect;

  const _OptionRow({
    required this.label,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      child: Builder(builder: (ctx) {
        final focused = Focus.of(ctx).hasFocus;
        return GestureDetector(
          onTap: onSelect,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: focused  ? Colors.white :
                       selected ? Colors.white54 : Colors.white12,
                width: focused ? 2 : 1,
              ),
              color: selected ? Colors.white12 : Colors.transparent,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selected ? Colors.white : Colors.white54,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(label, style: const TextStyle(fontSize: 18, color: Colors.white)),
              ],
            ),
          ),
        );
      }),
    );
  }
}
```

---

## File structure after Phase 0

```
lib/
  screensaver/
    screensaver_settings.dart   ← new
    screensaver_router.dart     ← new
    sheep/
      sheep_screensaver.dart    ← new (stub)
  syf/
    steal_your_face_screensaver.dart  ← existing, untouched
  settings/
    screensaver_settings_section.dart ← new, added to existing settings screen
```

---

## Done when

- [ ] Settings screen shows Steal Your Face / Sheep selector
- [ ] Quality row appears only when Sheep is selected
- [ ] Selection persists across app restarts
- [ ] SYF still launches by default (fresh install)
- [ ] Sheep stub launches and shows quality level name on screen
- [ ] D-pad navigation works correctly on Google TV hardware
