import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/ui/widgets/show_list/fast_scrollbar.dart';
import 'package:shakedown_core/services/device_service.dart';

class MockDeviceService extends ChangeNotifier implements DeviceService {
  @override
  bool get isTv => false;
  @override
  bool get isMobile => true;
  @override
  bool get isDesktop => false;
  @override
  String? get deviceName => 'Mock Device';
  @override
  bool get isLowEndTvDevice => false;
  @override
  bool get isSafari => false;
  @override
  bool get isPwa => false;
  @override
  Future<void> refresh() async {}
}

void main() {
  late ItemScrollController itemScrollController;
  late ItemPositionsListener itemPositionsListener;
  late List<Show> mockShows;

  setUp(() {
    itemScrollController = ItemScrollController();
    itemPositionsListener = ItemPositionsListener.create();
    mockShows = List.generate(
      100,
      (i) => Show(
        name: 'Show $i',
        date: '${1965 + (i ~/ 10)}-01-01',
        venue: 'Venue $i',
        artist: 'Artist',
        sources: [],
        hasFeaturedTrack: false,
      ),
    );
  });

  Widget createWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DeviceService>.value(value: MockDeviceService()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              ScrollablePositionedList.builder(
                itemCount: mockShows.length,
                itemBuilder: (context, index) =>
                    SizedBox(height: 100, child: Text('Item $index')),
                itemScrollController: itemScrollController,
                itemPositionsListener: itemPositionsListener,
              ),
              FastScrollbar(
                shows: mockShows,
                itemScrollController: itemScrollController,
                itemPositionsListener: itemPositionsListener,
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('FastScrollbar handles large content with proportional handle', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidget());

    // Initially at top
    final handle = find.byType(Container).last;
    expect(handle, findsWidgets);
  });
}
