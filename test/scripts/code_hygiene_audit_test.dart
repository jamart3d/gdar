import 'package:flutter_test/flutter_test.dart';

import '../../scripts/code_hygiene_audit.dart';

void main() {
  group('sanitizeForIdentifierScan', () {
    test('removes private-like identifiers inside string literals', () {
      const content = '''
final payload = {'_d': 'abc'};
const label = "_web_stub";
final keep = _actualSymbol;
''';

      final sanitized = sanitizeForIdentifierScan(content);

      expect(sanitized.contains('_d'), isFalse);
      expect(sanitized.contains('_web_stub'), isFalse);
      expect(sanitized.contains('_actualSymbol'), isTrue);
    });

    test('removes private-like identifiers in @JS annotation strings', () {
      const content = '''
@JS('window._gdarMediaSession.updatePlaybackState')
external void _jsUpdatePlaybackState(bool playing);
''';

      final sanitized = sanitizeForIdentifierScan(content);

      expect(sanitized.contains('_gdarMediaSession'), isFalse);
      expect(sanitized.contains('_jsUpdatePlaybackState'), isTrue);
    });
  });

  group('isPrivateTypeDeclaration', () {
    test('detects class private type declaration', () {
      expect(
        isPrivateTypeDeclaration(
          'class _PlaybackScreenHelpers extends StatelessWidget {',
          '_PlaybackScreenHelpers',
        ),
        isTrue,
      );
    });

    test('detects extension private type declaration', () {
      expect(
        isPrivateTypeDeclaration(
          'extension _PlaybackScreenHelpers on PlaybackScreenState {',
          '_PlaybackScreenHelpers',
        ),
        isTrue,
      );
    });

    test(
      'does not flag executable member declarations as type declarations',
      () {
        expect(
          isPrivateTypeDeclaration(
            'Future<void> _launchUrl(BuildContext context, String url) async {',
            '_launchUrl',
          ),
          isFalse,
        );
      },
    );
  });

  group('isInteropExternalDeclaration', () {
    test('flags external top-level function', () {
      expect(
        isInteropExternalDeclaration('external void _reloadPage();'),
        isTrue,
      );
    });

    test('flags external getter', () {
      expect(
        isInteropExternalDeclaration(
          '  external _PassiveAudioEngine get _engine;',
        ),
        isTrue,
      );
    });

    test('flags external factory inside extension type', () {
      expect(
        isInteropExternalDeclaration('  external factory _JsTrack({'),
        isTrue,
      );
    });

    test('does not flag normal private method declaration', () {
      expect(
        isInteropExternalDeclaration(
          'Future<void> _launchUrl(BuildContext context, String url) async {',
        ),
        isFalse,
      );
    });

    test('does not match `external` substring inside an identifier', () {
      expect(isInteropExternalDeclaration('void _externalize() {'), isFalse);
    });
  });
}
