import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/widgets/settings/interface_section.dart';
import 'package:shakedown_core/ui/widgets/theme/fruit_settings_group_header.dart';
import 'package:shakedown_core/ui/widgets/theme/fruit_switch.dart';

import '../../../helpers/test_helpers.dart';

class _FakeFruitThemeProvider extends ChangeNotifier implements ThemeProvider {
  @override
  ThemeStyle get themeStyle => ThemeStyle.fruit;

  @override
  bool get isFruitAllowed => true;

  @override
  Future<void> get initializationComplete => Future.value();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SettingsProvider> createSettingsProvider() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return SettingsProvider(prefs);
  }

  Widget buildSubject({
    required SettingsProvider settingsProvider,
    required ThemeProvider themeProvider,
    required DeviceService deviceService,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<DeviceService>.value(value: deviceService),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: InterfaceSection(scaleFactor: 1, initiallyExpanded: true),
          ),
        ),
      ),
    );
  }

  testWidgets('Fruit interface section exposes grouped spacing labels', (
    tester,
  ) async {
    final settingsProvider = await createSettingsProvider();

    await tester.pumpWidget(
      buildSubject(
        settingsProvider: settingsProvider,
        themeProvider: _FakeFruitThemeProvider(),
        deviceService: MockDeviceService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('GENERAL'), findsOneWidget);
    expect(find.text('DATE & TIME'), findsOneWidget);
    expect(find.text('LIBRARY CARDS'), findsOneWidget);
    expect(find.text('TRACK LIST'), findsOneWidget);
    expect(find.text('NAVIGATION'), findsOneWidget);
    expect(find.byType(FruitSettingsGroupHeader), findsNWidgets(5));
    expect(find.byType(FruitSwitch), findsWidgets);
    expect(find.byType(SwitchListTile), findsNothing);
  });
}
