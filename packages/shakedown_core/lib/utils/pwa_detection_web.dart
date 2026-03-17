import 'package:web/web.dart' as web;

bool isPwa() {
  try {
    return web.window.matchMedia('(display-mode: standalone)').matches;
  } catch (_) {
    return false;
  }
}
