import 'web_power_state_stub.dart'
    if (dart.library.js_interop) 'web_power_state_web.dart'
    as impl;

Future<bool?> getInitialWebChargingState() => impl.getInitialWebChargingState();

Stream<bool?> get onWebChargingStateChanged => impl.onWebChargingStateChanged;
