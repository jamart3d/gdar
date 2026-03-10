import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown/ui/widgets/theme/fruit_icon_button.dart';
import 'package:shakedown/ui/widgets/theme/fruit_segmented_control.dart';
import 'package:shakedown/ui/widgets/theme/fruit_switch.dart';
import 'package:shakedown/ui/widgets/theme/fruit_ui.dart';

void main() {
  testWidgets('FruitIconButton exposes button semantics and label',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FruitIconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Open settings',
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Open settings'), findsOneWidget);

    final semantics = tester.getSemantics(find.byType(FruitIconButton));
    expect(semantics.flagsCollection.isButton, isTrue);
    expect(semantics.flagsCollection.hasEnabledState, isTrue);
    expect(semantics.flagsCollection.isEnabled, isTrue);
  });

  testWidgets('FruitSwitch exposes toggle semantics', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FruitSwitch(
            value: true,
            semanticLabel: 'Liquid glass',
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Liquid glass'), findsOneWidget);

    final semantics = tester.getSemantics(find.byType(FruitSwitch));
    expect(semantics.flagsCollection.isButton, isTrue);
    expect(semantics.flagsCollection.hasToggledState, isTrue);
    expect(semantics.flagsCollection.isToggled, isTrue);
  });

  testWidgets('FruitTextAction exposes button semantics and label',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FruitTextAction(
            label: 'Cancel',
            onPressed: _noop,
          ),
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
      MaterialApp(
        home: Scaffold(
          body: FruitSegmentedControl<String>(
            values: const ['Library', 'Play'],
            selectedValue: 'Library',
            onSelectionChanged: (_) {},
            semanticLabelBuilder: (value) => '$value view',
            labelBuilder: (value) => Text(value),
          ),
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
    expect(selectedSemantics.flagsCollection.isSelected, isTrue);
    expect(unselectedSemantics.flagsCollection.isButton, isTrue);
    expect(unselectedSemantics.flagsCollection.isSelected, isFalse);
  });
}

void _noop() {}
