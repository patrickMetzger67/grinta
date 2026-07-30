import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/screen/tips_screen.dart';
import 'package:grinta/services/youtube_config_service.dart';

void main() {
  group('TipsScreen.filterVideos', () {
    const videos = <YoutubeVideoEntry>[
      YoutubeVideoEntry(
        id: 'aaa11111111',
        title: 'Heatmap GPS terrain',
        description: 'Comment géolocaliser un stade',
      ),
      YoutubeVideoEntry(
        id: 'bbb22222222',
        title: 'Sync USB ASI',
        description: 'Importer les données capteur',
      ),
      YoutubeVideoEntry(
        id: 'ccc33333333',
        title: 'Astuce live Intense',
        description: null,
      ),
    ];

    test('returns all videos when query is empty', () {
      expect(TipsScreen.filterVideos(videos, ''), videos);
      expect(TipsScreen.filterVideos(videos, '   '), videos);
    });

    test('matches title case-insensitively', () {
      final result = TipsScreen.filterVideos(videos, 'heatmap');
      expect(result.map((v) => v.id), ['aaa11111111']);
    });

    test('matches description', () {
      final result = TipsScreen.filterVideos(videos, 'capteur');
      expect(result.map((v) => v.id), ['bbb22222222']);
    });

    test('requires all tokens', () {
      final result = TipsScreen.filterVideos(videos, 'astuce live');
      expect(result.map((v) => v.id), ['ccc33333333']);
      expect(TipsScreen.filterVideos(videos, 'astuce usb'), isEmpty);
    });
  });
}
