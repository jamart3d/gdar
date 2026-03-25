import 'web_perf_hint_noop.dart'
    if (dart.library.js_interop) 'web_perf_hint_web.dart'
    as impl;

bool isLikelyLowPowerWebDevice() => impl.isLikelyLowPowerWebDevice();
bool isSafariWeb() => impl.isSafariWeb();
bool isMobileWeb() => impl.isMobileWeb();
