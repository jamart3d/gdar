import 'dart:ui' show Tristate;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/ui/widgets/theme/fruit_icon_button.dart';
import 'package:shakedown_core/ui/widgets/theme/fruit_segmented_control.dart';
import 'package:shakedown_core/ui/widgets/theme/fruit_switch.dart';
import 'package:shakedown_core/ui/widgets/theme/fruit_ui.dart';

class _FakeThemeProvider extends ChangeNotifier implements ThemeProvider {
  @override
  ThemeStyle get themeStyle => ThemeStyle.fruit;
  @override
  bool get isDarkMode => false;
  @override
  bool get isFruitAllowed => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSettingsProvider extends ChangeNotifier implements SettingsProvider {
  @override
  bool get fruitEnableLiquidGlass => true;
  @override
  bool get useNeumorphism => true;
  @override
  bool get useTrueBlack => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget wrapWithProviders(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(
            value: _FakeThemeProvider()),
        ChangeNotifierProvider<SettingsProvider>.value(
            value: _FakeSettingsProvider()),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  testWidgets('FruitIconButton exposes button semantics and label',
      (tester) async {
    await tester.pumpWidget(
      wrapWithProviders(
        FruitIconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Open settings',
          onPressed: () {},
        ),
      ),
    );

    expect(find.bySemanticsLabel('Open settings'), findsOneWidget);

    final semantics = tester.getSemantics(find.byType(FruitIconButton));
    expect(semantics.flagsCollection.isButton, isTrue);
    expect(semantics.flagsCollection.isEnabled != Tristate.none, isTrue);
    expect(semantics.flagsCollection.isEnabled == Tristate.isTrue, isTrue);
  });

  testWidgets('FruitSwitch exposes toggle semantics', (tester) async {
    await tester.pumpWidget(
      wrapWithProviders(
        FruitSwitch(
          value: true,
          semanticLabel: 'Liquid glass',
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.bySemanticsLabel('Liquid glass'), findsOneWidget);

    final semantics = tester.getSemantics(find.byType(FruitSwitch));
    expect(semantics.flagsCollection.isButton, isTrue);
    expect(semantics.flagsCollection.isToggled != Tristate.none, isTrue);
    expect(semantics.flagsCollection.isToggled == Tristate.isTrue, isTrue);
  });

  testWidgets('FruitTextAction exposes button semantics and label',
      (tester) async {
    await tester.pumpWidget(
      wrapWithProviders(
        const FruitTextAction(
          label: 'Cancel',
          onPressed: _noop,
        ),
      ),
    );

    expect(find.bySemanticsLabel('Cancel'), findsOneWidget);

    final semantics = tester.getSemantics(find.byType(FruitTextAction));
    expect(semantics.flagsCollection.isButton, isTrue);
  });

  testWidgets('FruitSegmentedControl exposes segment button semantics',
      (tester) async {
    await tester.pumpWidget(
      wrapWithProviders(
        FruitSegmentedControl<String>(
          values: const ['Library', 'Play'],
          selectedValue: 'Library',
          onSelectionChanged: (_) {},
          semanticLabelBuilder: (value) => '$value view',
          labelBuilder: (value) => Text(value),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Library view'), findsOneWidget);
    expect(find.bySemanticsLabel('Play view'), findsOneWidget);

    final selectedSemantics = tester.getSemantics(
      find.bySemanticsLabel('Library view'),
    );
    final unselectedSemantics = tester.getSemantics(
      find.bySemanticsLabel('Play view'),
    );

    expect(selectedSemantics.flagsCollection.isButton, isTrue);
    expect(selectedSemantics.flagsCollection.isSelected == Tristate.isTrue,
        isTrue);
    expect(unselectedSemantics.flagsCollection.isButton, isTrue);
    expect(unselectedSemantics.flagsCollection.isSelected == Tristate.isFalse,
        isTrue);
  });
}

void _noop() {}
