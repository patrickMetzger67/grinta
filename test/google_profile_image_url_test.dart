import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/google_profile_image_url.dart';

void main() {
  group('expandGoogleProfileImageUrls', () {
    test('includes original and stripped Google variants', () {
      const url =
          'https://lh3.googleusercontent.com/a/ACg8ocI6HnB1RfQI2sVGcyhKjglXBBLbi8zTD6ZZobucQhv9sLk3QWfO=s96-c';
      final variants = expandGoogleProfileImageUrls(url);

      expect(variants.first, url);
      expect(
        variants,
        contains(
          'https://lh3.googleusercontent.com/a/ACg8ocI6HnB1RfQI2sVGcyhKjglXBBLbi8zTD6ZZobucQhv9sLk3QWfO',
        ),
      );
      expect(
        variants,
        contains(
          'https://lh3.googleusercontent.com/a/ACg8ocI6HnB1RfQI2sVGcyhKjglXBBLbi8zTD6ZZobucQhv9sLk3QWfO?sz=96',
        ),
      );
    });

    test('returns single entry for non-Google URLs', () {
      const url = 'https://example.com/avatar.jpg';
      expect(expandGoogleProfileImageUrls(url), [url]);
    });
  });
}
