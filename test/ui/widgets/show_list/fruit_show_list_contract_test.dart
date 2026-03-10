import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/ui/widgets/show_list/show_list_app_bar.dart';
import 'package:shakedown/ui/widgets/show_list/show_list_search_bar.dart';
import 'package:shakedown/ui/widgets/theme/fruit_ui.dart';

class _FakeThemeProvider extends ChangeNotifier implements ThemeProvider {
  ThemeStyle _themeStyle = ThemeStyle.fruit;
  bool _darkMode = false;

  @override
  ThemeStyle get themeStyle => _themeStyle;

  @override
  ThemeMode get currentThemeMode =>
      _darkMode ? ThemeMode.dark : ThemeMode.light;

  @override
  bool get isDarkMode => _darkMode;

  @override
  bool get isFruitAllowed => true;

  @override
  void toggleTheme() {
    _darkMode = !_darkMode;
    notifyListeners();
  }

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
  bool get performanceMode => false;

  @override
  bool get uiScale => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeShowListProvider extends ChangeNotifier implements ShowListProvider {
  bool _isSearchVisible = true;

  @override
  bool get isSearchVisible => _isSearchVisible;

  @override
  void setSearchVisible(bool visible) {
    _isSearchVisible = visible;
    notifyListeners();
  }

  @override
  void toggleSearchVisible() {
    _isSearchVisible = !_isSearchVisible;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDeviceService extends ChangeNotifier implements DeviceService {
  @override
  bool get isTv => false;

  @override
  bool get isMobile => false;

  @override
  bool get isDesktop => true;

  @override
  bool get isSafari => false;

  @override
  bool get isPwa => false;

  @override
  String? get deviceName => 'test-device';

  @override
  Future<void> refresh() async {}
}

void main() {
  late _FakeThemeProvider themeProvider;
  late _FakeSettingsProvider settingsProvider;
  late _FakeShowListProvider showListProvider;
  late _FakeDeviceService deviceService;

  setUp(() {
    themeProvider = _FakeThemeProvider();
    settingsProvider = _FakeSettingsProvider();
    showListProvider = _FakeShowListProvider();
    deviceService = _FakeDeviceService();
  });

  Widget _wrap(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<ShowListProvider>.value(value: showListProvider),
        ChangeNotifierProvider<DeviceService>.value(value: deviceService),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  testWidgets('Fruit search uses custom controls and no Material SearchBar',
      (tester) async {
    final controller = TextEditingController(text: 'gd');
    final focusNode = FocusNode();

    await tester.pumpWidget(
      _wrap(
        ShowListSearchBar(
          controller: controller,
          focusNode: focusNode,
          onSubmitted: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SearchBar), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(FruitActionButton), findsWidgets);
  });

  testWidgets('Fruit app bar does not render M3 text/search widgets',
      (tester) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<SettingsProvider>.value(
              value: settingsProvider),
          ChangeNotifierProvider<ShowListProvider>.value(
              value: showListProvider),
          ChangeNotifierProvider<DeviceService>.value(value: deviceService),
        ],
        child: MaterialApp(
          home: Scaffold(
            appBar: ShowListAppBar(
              randomPulseAnimation: const AlwaysStoppedAnimation<double>(1.0),
              searchPulseAnimation: const AlwaysStoppedAnimation<double>(1.0),
              isRandomShowLoading: false,
              onRandomPlay: () {},
              onToggleSearch: () {},
              onTitleTap: () {},
              searchController: controller,
              searchFocusNode: focusNode,
              onSearchSubmitted: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(SearchBar), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(FruitActionButton), findsOneWidget);
    expect(find.byType(FruitTextAction), findsOneWidget);
  });
}
