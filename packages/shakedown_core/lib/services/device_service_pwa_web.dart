import 'package:web/web.dart' as web;

bool checkIsPwa() {
  try {
    return web.window.matchMedia('(display-mode: standalone)').matches;
  } catch (e) {
    return false;
  }
}
