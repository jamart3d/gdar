import 'package:flutter/widgets.dart';

mixin ScreensaverActiveStateMixin<T extends StatefulWidget> on State<T> {
  bool isScreensaverActive = false;

  void setScreensaverActive(bool active) {
    if (!mounted) {
      isScreensaverActive = active;
      return;
    }
    setState(() {
      isScreensaverActive = active;
    });
  }
}
