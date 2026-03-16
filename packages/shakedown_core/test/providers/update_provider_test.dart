import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shakedown_core/providers/update_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UpdateProvider', () {
    late UpdateProvider updateProvider;

    setUp(() async {
      PackageInfo.setMockInitialValues(
        appName: 'Shakedown',
        packageName: 'com.gdar.shakedown',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/url_launcher'),
            (MethodCall methodCall) async {
              if (methodCall.method == 'canLaunch') {
                return true;
              } else if (methodCall.method == 'launch') {
                return true;
              }
              return null;
            },
          );

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
