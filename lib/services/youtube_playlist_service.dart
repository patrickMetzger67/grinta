import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'youtube_config_service.dart';

/// Loads Astuces / Tips videos from the configured YouTube playlist.
///
/// Prefer the live playlist Atom feed (`playlistId`). Falls back to the
/// curated `config/youtube.videos` list when the playlist is missing or the
/// feed cannot be reached.
class YoutubePlaylistService {
  YoutubePlaylistService({
    http.Client? client,
    YoutubeConfigService? configService,
  })  : _client = client ?? http.Client(),
        _configService = configService ?? YoutubeConfigService.instance,
        _ownsClient = client == null;

  final http.Client _client;
  final YoutubeConfigService _configService;
  final bool _ownsClient;

  static final YoutubePlaylistService instance = YoutubePlaylistService();

  /// Canonical public Atom/RSS URL for a playlist (no API key).
  static Uri playlistAtomUri(String playlistId) {
    return Uri.https(
      'www.youtube.com',
      '/feeds/videos.xml',
      <String, String>{'playlist_id': playlistId},
    );
  }

  /// Fetches playlist videos, then curated fallback if needed.
  ///
  /// When both the live playlist feed and the curated Firestore list are
  /// available, they are merged (playlist order first, then curated-only ids)
  /// so longer admin-maintained catalogs are not truncated by the Atom page.
  Future<YoutubePlaylistResult> loadTipsVideos({
    bool forceRefresh = false,
  }) async {
    await _configService.ensureInitialized();
    final config = _configService.config;
    final playlistId = normalizePlaylistId(config.playlistId) ?? '';
    final curated = config.videos
        .where((v) => v.id.trim().isNotEmpty)
        .toList(growable: false);

    List<YoutubeVideoEntry> fromPlaylist = const [];
    Object? playlistError;
    if (playlistId.isNotEmpty) {
      try {
        fromPlaylist = await fetchPlaylistVideos(playlistId);
      } catch (e, st) {
        playlistError = e;
        debugPrint('[YoutubePlaylist] feed failed for $playlistId: $e\n$st');
      }
    } else if (config.playlistId.trim().isNotEmpty) {
      debugPrint(
        '[YoutubePlaylist] invalid playlistId="${config.playlistId.trim()}"',
      );
    }

    if (fromPlaylist.isNotEmpty && curated.isNotEmpty) {
      return YoutubePlaylistResult(
        videos: mergeVideos(fromPlaylist, curated),
        source: YoutubeTipsSource.playlistAndCurated,
        playlistId: playlistId,
      );
    }
    if (fromPlaylist.isNotEmpty) {
      return YoutubePlaylistResult(
        videos: fromPlaylist,
        source: YoutubeTipsSource.playlist,
        playlistId: playlistId,
      );
    }
    if (curated.isNotEmpty) {
      return YoutubePlaylistResult(
        videos: curated,
        source: YoutubeTipsSource.curated,
        playlistId: playlistId.isEmpty ? null : playlistId,
      );
    }
    return YoutubePlaylistResult(
      videos: const [],
      source: YoutubeTipsSource.empty,
      playlistId: playlistId.isEmpty ? null : playlistId,
      error: playlistError?.toString(),
    );
  }

  @visibleForTesting
  static List<YoutubeVideoEntry> mergeVideos(
    List<YoutubeVideoEntry> primary,
    List<YoutubeVideoEntry> secondary,
  ) {
    final seen = <String>{};
    final merged = <YoutubeVideoEntry>[];
    for (final video in [...primary, ...secondary]) {
      final id = video.id.trim();
      if (id.isEmpty || !seen.add(id)) continue;
      merged.add(video);
    }
    return List<YoutubeVideoEntry>.unmodifiable(merged);
  }

  /// Extracts a playlist id from a bare id or common YouTube playlist URLs.
  @visibleForTesting
  static String? normalizePlaylistId(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;

    // Bare playlist id (PL… / UU… / OL… etc.).
    final bare = RegExp(r'^[A-Za-z0-9_-]{10,}$');
    if (bare.hasMatch(value) && !value.contains('/') && !value.contains('.')) {
      return value;
    }

    final uri = Uri.tryParse(value);
    if (uri == null) return null;

    final list = uri.queryParameters['list']?.trim();
    if (list != null && list.isNotEmpty) return list;

    // /playlist?list=… already covered; also path segments like /playlist/PL…
    final segments = uri.pathSegments;
    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      if (bare.hasMatch(seg) &&
          (seg.startsWith('PL') ||
              seg.startsWith('UU') ||
              seg.startsWith('OL') ||
              seg.startsWith('LL'))) {
        return seg;
      }
    }
    return null;
  }

  /// Public Atom feed for a playlist (no API key).
  ///
  /// On web, YouTube's Atom host often blocks CORS — we then retry via a
  /// JSON feed proxy that allows browser requests.
  Future<List<YoutubeVideoEntry>> fetchPlaylistVideos(String playlistId) async {
    final id = normalizePlaylistId(playlistId) ?? '';
    if (id.isEmpty) return const [];

    final atomUri = playlistAtomUri(id);

    try {
      final response =
          await _client.get(atomUri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final videos = parsePlaylistAtomFeed(response.body);
        if (videos.isNotEmpty) return videos;
      } else {
        debugPrint(
          '[YoutubePlaylist] atom HTTP ${response.statusCode} for $id',
        );
      }
    } catch (e, st) {
      debugPrint('[YoutubePlaylist] atom fetch error: $e\n$st');
    }

    // Web / CORS fallback: rss2json returns the same playlist with CORS.
    return _fetchPlaylistViaRss2Json(id);
  }

  Future<List<YoutubeVideoEntry>> _fetchPlaylistViaRss2Json(
    String playlistId,
  ) async {
    final rssUrl = playlistAtomUri(playlistId).toString();
    final uri = Uri.https(
      'api.rss2json.com',
      '/v1/api.json',
      <String, String>{'rss_url': rssUrl},
    );

    final response =
        await _client.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw StateError('rss2json HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw StateError('rss2json: unexpected payload');
    }
    final map = Map<String, dynamic>.from(decoded);
    if (map['status']?.toString() != 'ok') {
      throw StateError('rss2json status=${map['status']}');
    }

    final items = map['items'];
    if (items is! List) return const [];

    final videos = <YoutubeVideoEntry>[];
    final seen = <String>{};
    for (final item in items) {
      if (item is! Map) continue;
      final entry = Map<String, dynamic>.from(item);
      final id = YoutubeConfigService.normalizeVideoId(
            entry['guid']?.toString(),
          ) ??
          YoutubeConfigService.normalizeVideoId(entry['link']?.toString());
      if (id == null || id.isEmpty || !seen.add(id)) continue;

      final title = (entry['title'] ?? '').toString().trim();
      final description = (entry['description'] ?? '').toString().trim();
      final thumbnail = (entry['thumbnail'] ?? '').toString().trim();

      videos.add(
        YoutubeVideoEntry(
          id: id,
          title: title.isEmpty ? id : title,
          description: description.isEmpty ? null : description,
          thumbnailUrl: thumbnail.isEmpty
              ? 'https://i.ytimg.com/vi/$id/hqdefault.jpg'
              : thumbnail,
        ),
      );
    }

    return List<YoutubeVideoEntry>.unmodifiable(videos);
  }

  /// Parses YouTube playlist Atom/XML into [YoutubeVideoEntry]s.
  @visibleForTesting
  static List<YoutubeVideoEntry> parsePlaylistAtomFeed(String xml) {
    final entries = RegExp(
      r'<entry\b[\s\S]*?</entry>',
      caseSensitive: false,
    ).allMatches(xml);

    final videos = <YoutubeVideoEntry>[];
    final seen = <String>{};

    for (final match in entries) {
      final entry = match.group(0) ?? '';
      final id = _extractVideoId(entry);
      if (id == null || id.isEmpty || !seen.add(id)) continue;

      final title = _decodeXml(_firstGroup(
            entry,
            RegExp(
              r'<title(?:\s[^>]*)?>([\s\S]*?)</title>',
              caseSensitive: false,
            ),
          ) ??
          '');
      final description = _decodeXml(_firstGroup(
        entry,
        RegExp(
          r'<media:description(?:\s[^>]*)?>([\s\S]*?)</media:description>',
          caseSensitive: false,
        ),
      ));
      final thumbnail = _firstAttr(
            entry,
            RegExp(
              r'<media:thumbnail\b[^>]*\burl="([^"]+)"',
              caseSensitive: false,
            ),
          ) ??
          'https://i.ytimg.com/vi/$id/hqdefault.jpg';

      videos.add(
        YoutubeVideoEntry(
          id: id,
          title: title.isEmpty ? id : title,
          description: (description == null || description.trim().isEmpty)
              ? null
              : description.trim(),
          thumbnailUrl: thumbnail,
        ),
      );
    }

    return List<YoutubeVideoEntry>.unmodifiable(videos);
  }

  static String? _extractVideoId(String entry) {
    final ytId = _firstGroup(
      entry,
      RegExp(
        r'<yt:videoId(?:\s[^>]*)?>([\s\S]*?)</yt:videoId>',
        caseSensitive: false,
      ),
    )?.trim();
    final normalizedYt = YoutubeConfigService.normalizeVideoId(ytId);
    if (normalizedYt != null) return normalizedYt;

    final entryId = _firstGroup(
      entry,
      RegExp(r'<id(?:\s[^>]*)?>([\s\S]*?)</id>', caseSensitive: false),
    )?.trim();
    if (entryId != null) {
      final marker = 'yt:video:';
      final idx = entryId.indexOf(marker);
      if (idx >= 0) {
        return YoutubeConfigService.normalizeVideoId(
          entryId.substring(idx + marker.length),
        );
      }
    }

    final link = _firstAttr(
      entry,
      RegExp(
        r'<link\b[^>]*\bhref="([^"]+)"',
        caseSensitive: false,
      ),
    );
    return YoutubeConfigService.normalizeVideoId(link);
  }

  static String? _firstGroup(String input, RegExp pattern) {
    final match = pattern.firstMatch(input);
    return match?.group(1);
  }

  static String? _firstAttr(String input, RegExp pattern) {
    final match = pattern.firstMatch(input);
    return match?.group(1)?.trim();
  }

  static String _decodeXml(String? raw) {
    if (raw == null) return '';
    return raw
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAllMapped(
          RegExp(r'&#(\d+);'),
          (m) => String.fromCharCode(int.parse(m.group(1)!)),
        )
        .trim();
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}

enum YoutubeTipsSource {
  playlist,
  curated,
  playlistAndCurated,
  empty,
}

class YoutubePlaylistResult {
  const YoutubePlaylistResult({
    required this.videos,
    required this.source,
    this.playlistId,
    this.error,
  });

  final List<YoutubeVideoEntry> videos;
  final YoutubeTipsSource source;
  final String? playlistId;
  final String? error;

  bool get isEmpty => videos.isEmpty;
}
