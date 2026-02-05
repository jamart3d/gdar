import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown/providers/update_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UpdateProvider', () {
    late UpdateProvider updateProvider;

    setUp(() async {
      updateProvider = UpdateProvider();
    });

    test('initial state is correct', () {
      expect(updateProvider.updateInfo, isNull);
      expect(updateProvider.isSimulated, isFalse);
    });

    test('simulateUpdate() updates state correctly', () {
      updateProvider.simulateUpdate();

      expect(updateProvider.isSimulated, isTrue);
      expect(updateProvider.updateInfo, isNull);
    });

    test('startUpdate() in simulation mode completes successfully', () async {
      updateProvider.simulateUpdate();
      await updateProvider.startUpdate();
      // No exception thrown means success for now as it just calls openStore
    });
  });
}
