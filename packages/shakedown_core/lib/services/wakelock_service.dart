import 'package:wakelock_plus/wakelock_plus.dart';

class WakelockService {
  Future<bool> get enabled => WakelockPlus.enabled;
  Future<void> enable() => WakelockPlus.enable();
  Future<void> disable() => WakelockPlus.disable();
  Future<void> toggle({required bool enable}) =>
      WakelockPlus.toggle(enable: enable);
}
