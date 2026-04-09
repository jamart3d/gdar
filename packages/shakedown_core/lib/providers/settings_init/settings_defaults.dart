bool resolveBoolDefault({
  required bool webVal,
  required bool tvVal,
  required bool phoneVal,
  required bool isTv,
  required bool isWeb,
}) {
  if (isTv) {
    return tvVal;
  }
  if (isWeb) {
    return webVal;
  }
  return phoneVal;
}

String resolveStringDefault({
  required String webVal,
  required String tvVal,
  required String phoneVal,
  required bool isTv,
  required bool isWeb,
}) {
  if (isTv) {
    return tvVal;
  }
  if (isWeb) {
    return webVal;
  }
  return phoneVal;
}

int resolveIntDefault({
  required int webVal,
  required int tvVal,
  required int phoneVal,
  required bool isTv,
  required bool isWeb,
}) {
  if (isTv) {
    return tvVal;
  }
  if (isWeb) {
    return webVal;
  }
  return phoneVal;
}
