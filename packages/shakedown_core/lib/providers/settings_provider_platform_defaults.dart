part of 'settings_provider.dart';

mixin _SettingsProviderPlatformDefaultsExtension
    on ChangeNotifier, _SettingsProviderCoreFields {
  bool get isTv;

  bool _dBool(bool webVal, bool tvVal, bool phoneVal) {
    if (isTv) return tvVal;
    if (kIsWeb) return webVal;
    return phoneVal;
  }

  String _dStr(String webVal, String tvVal, String phoneVal) {
    if (isTv) return tvVal;
    if (kIsWeb) return webVal;
    return phoneVal;
  }
}
