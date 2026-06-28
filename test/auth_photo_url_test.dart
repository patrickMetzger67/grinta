import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/player_photo_resolver.dart';

void main() {
  group('normalizeAuthPhotoDisplayUrl', () {
    test('appends Google size suffix when missing', () {
      const url = 'https://lh3.googleusercontent.com/a/abc123';
      expect(
        normalizeAuthPhotoDisplayUrl(url),
        '$url=s96-c',
      );
    });

    test('leaves URL unchanged when size suffix already present', () {
      const url = 'https://lh3.googleusercontent.com/a/abc123=s96-c';
      expect(normalizeAuthPhotoDisplayUrl(url), url);
    });

    test('leaves non-Google URLs unchanged', () {
      const url = 'https://firebasestorage.googleapis.com/v0/b/x/o/y.jpg';
      expect(normalizeAuthPhotoDisplayUrl(url), url);
    });
  });
}
