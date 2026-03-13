import 'dart:async';
import 'package:app_links/app_links.dart';

class DeepLinkService {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  // We expose a stream of URIs instead of hardcoding the navigation
  // logic here, since navigation belongs in the app layer.
  final _uriController = StreamController<Uri>.broadcast();
  Stream<Uri> get uriStream => _uriController.stream;

  void init() {
    _appLinks = AppLinks();

    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _uriController.add(uri);
      }
    });

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _uriController.add(uri);
    });
  }

  void dispose() {
    _linkSubscription?.cancel();
    _uriController.close();
  }
}
