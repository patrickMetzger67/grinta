import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/services/youtube_config_service.dart';
import 'package:grinta/services/youtube_playlist_service.dart';

void main() {
  group('YoutubePlaylistService.normalizePlaylistId', () {
    test('keeps bare playlist ids', () {
      expect(
        YoutubePlaylistService.normalizePlaylistId('PLBCF2DAC6FFB574DE'),
        'PLBCF2DAC6FFB574DE',
      );
    });

    test('extracts list from watch / playlist URLs', () {
      expect(
        YoutubePlaylistService.normalizePlaylistId(
          'https://www.youtube.com/playlist?list=PLBCF2DAC6FFB574DE',
        ),
        'PLBCF2DAC6FFB574DE',
      );
      expect(
        YoutubePlaylistService.normalizePlaylistId(
          'https://www.youtube.com/watch?v=GvgqDSnpRQM&list=PLBCF2DAC6FFB574DE',
        ),
        'PLBCF2DAC6FFB574DE',
      );
    });

    test('returns null for empty / invalid', () {
      expect(YoutubePlaylistService.normalizePlaylistId(''), isNull);
      expect(YoutubePlaylistService.normalizePlaylistId('not a id'), isNull);
    });
  });

  group('YoutubePlaylistService.playlistAtomUri', () {
    test('uses videos.xml?playlist_id=', () {
      final uri = YoutubePlaylistService.playlistAtomUri('PLBCF2DAC6FFB574DE');
      expect(uri.host, 'www.youtube.com');
      expect(uri.path, '/feeds/videos.xml');
      expect(uri.queryParameters['playlist_id'], 'PLBCF2DAC6FFB574DE');
    });
  });

  group('YoutubePlaylistService.parsePlaylistAtomFeed', () {
    test('parses video id, title, description and thumbnail', () {
      const xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns:yt="http://www.youtube.com/xml/schemas/2015"
      xmlns:media="http://search.yahoo.com/mrss/"
      xmlns="http://www.w3.org/2005/Atom">
  <entry>
    <id>yt:video:dQw4w9WgXcQ</id>
    <yt:videoId>dQw4w9WgXcQ</yt:videoId>
    <title>Astuce #1 &amp; GPS</title>
    <link rel="alternate" href="https://www.youtube.com/watch?v=dQw4w9WgXcQ"/>
    <media:group>
      <media:thumbnail url="https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg"
                      width="480" height="360"/>
      <media:description>Description de l&apos;astuce</media:description>
    </media:group>
  </entry>
  <entry>
    <id>yt:video:abcdefghijk</id>
    <yt:videoId>abcdefghijk</yt:videoId>
    <title>Astuce #2</title>
    <media:group>
      <media:thumbnail url="https://i.ytimg.com/vi/abcdefghijk/hqdefault.jpg"/>
      <media:description></media:description>
    </media:group>
  </entry>
</feed>
''';

      final videos = YoutubePlaylistService.parsePlaylistAtomFeed(xml);
      expect(videos, hasLength(2));
      expect(videos[0].id, 'dQw4w9WgXcQ');
      expect(videos[0].title, 'Astuce #1 & GPS');
      expect(videos[0].description, "Description de l'astuce");
      expect(
        videos[0].thumbnailUrl,
        'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
      );
      expect(videos[1].id, 'abcdefghijk');
      expect(videos[1].title, 'Astuce #2');
    });

    test('deduplicates repeated video ids', () {
      const xml = '''
<feed>
  <entry>
    <yt:videoId>aaaaaaaaaaa</yt:videoId>
    <title>One</title>
  </entry>
  <entry>
    <yt:videoId>aaaaaaaaaaa</yt:videoId>
    <title>Dup</title>
  </entry>
</feed>
''';
      final videos = YoutubePlaylistService.parsePlaylistAtomFeed(xml);
      expect(videos, hasLength(1));
      expect(videos.first.title, 'One');
    });

    test('returns empty for malformed feed', () {
      expect(
        YoutubePlaylistService.parsePlaylistAtomFeed('<html></html>'),
        isEmpty,
      );
      expect(YoutubePlaylistService.parsePlaylistAtomFeed(''), isEmpty);
    });
  });

  group('YoutubePlaylistService.mergeVideos', () {
    test('keeps playlist order then curated-only ids', () {
      const playlist = <YoutubeVideoEntry>[
        YoutubeVideoEntry(id: 'aaa11111111', title: 'A'),
        YoutubeVideoEntry(id: 'bbb22222222', title: 'B'),
      ];
      const curated = <YoutubeVideoEntry>[
        YoutubeVideoEntry(id: 'bbb22222222', title: 'B curated'),
        YoutubeVideoEntry(id: 'ccc33333333', title: 'C'),
      ];

      final merged = YoutubePlaylistService.mergeVideos(playlist, curated);
      expect(merged.map((v) => v.id).toList(), <String>[
        'aaa11111111',
        'bbb22222222',
        'ccc33333333',
      ]);
      expect(merged[1].title, 'B');
    });
  });
}
