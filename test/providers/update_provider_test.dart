import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown/providers/update_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UpdateProvider', () {
    late UpdateProvider updateProvider;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      updateProvider = UpdateProvider(prefs);
    });

    test('initial state is correct', () {
      expect(updateProvider.updateInfo, isNull);
      expect(updateProvider.isDownloading, isFalse);
      expect(updateProvider.isSimulated, isFalse);
    });

    test('simulateUpdate() updates state correctly', () {
      updateProvider.simulateUpdate();

      expect(updateProvider.isSimulated, isTrue);
      expect(updateProvider.isDownloading, isFalse);
      // Since we defined simulateUpdate to set updateInfo to null (for now), check that
      expect(updateProvider.updateInfo, isNull);
    });

    test('startUpdate() in simulation mode sets isDownloading to true',
        () async {
      updateProvider.simulateUpdate();
      await updateProvider.startUpdate();

      expect(updateProvider.isDownloading, isTrue);
    });
  });
}
