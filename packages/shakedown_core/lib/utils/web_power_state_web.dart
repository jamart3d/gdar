import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

@JS('_gdarPowerState')
external _GdarPowerState? get _powerState;

@JS()
@anonymous
extension type _GdarPowerState(JSObject _) {
  external JSBoolean? getCharging();
  external JSPromise<JSAny?>? whenReady();
}

@JS()
@anonymous
extension type _PowerEvent(JSObject _) implements JSObject {
  external JSObject? get detail;
}

@JS()
@anonymous
extension type _PowerEventDetail(JSObject _) implements JSObject {
  external JSBoolean? get charging;
}

Future<bool?> getInitialWebChargingState() async {
  try {
    final powerState = _powerState;
    if (powerState == null) {
      return null;
    }

    final ready = powerState.whenReady();
    if (ready != null) {
      await ready.toDart;
    }

    return powerState.getCharging()?.toDart;
  } catch (_) {
    return null;
  }
}

StreamController<bool?>? _webChargingController;
JSFunction? _webChargingListener;

Stream<bool?> get onWebChargingStateChanged {
  final existing = _webChargingController;
  if (existing != null) {
    return existing.stream;
  }

  late final StreamController<bool?> controller;
  controller = StreamController<bool?>.broadcast(
    onListen: () {
      _webChargingListener ??= ((JSObject raw) {
        try {
          final detail = _PowerEvent(raw).detail;
          if (detail == null) {
            controller.add(null);
            return;
          }
          controller.add(_PowerEventDetail(detail).charging?.toDart);
        } catch (_) {
          controller.add(null);
        }
      }).toJS;

      web.window.addEventListener(
        'gdar-power-state-change',
        _webChargingListener!,
      );
    },
    onCancel: () {
      if (controller.hasListener) {
        return;
      }

      final listener = _webChargingListener;
      if (listener != null) {
        web.window.removeEventListener('gdar-power-state-change', listener);
        _webChargingListener = null;
      }
      _webChargingController = null;
    },
  );

  _webChargingController = controller;
  return controller.stream;
}
