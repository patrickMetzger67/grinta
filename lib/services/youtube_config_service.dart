import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/services/user_root_service.dart';

/// One curated YouTube video entry stored in `config/youtube.videos`.
class YoutubeVideoEntry {
  const YoutubeVideoEntry({
    required this.id,
    required this.title,
    this.description,
    this.thumbnailUrl,
  });

  /// YouTube video id (11 chars) or a value accepted by [YoutubeConfigService.normalizeVideoId].
  final String id;
  final String title;
  final String? description;
  final String? thumbnailUrl;

  factory YoutubeVideoEntry.fromMap(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) {
      return const YoutubeVideoEntry(id: '', title: '');
    }
    return YoutubeVideoEntry(
      id: (data['id'] ?? '').toString().trim(),
      title: (data['title'] ?? '').toString().trim(),
      description: _optionalString(data['description']),
      thumbnailUrl: _optionalString(data['thumbnailUrl']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      if (description != null && description!.trim().isNotEmpty)
        'description': description!.trim(),
      if (thumbnailUrl != null && thumbnailUrl!.trim().isNotEmpty)
        'thumbnailUrl': thumbnailUrl!.trim(),
    };
  }

  YoutubeVideoEntry copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnailUrl,
  }) {
    return YoutubeVideoEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }

  static String? _optionalString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

/// Remote YouTube / Astuces config from Firestore `config/youtube`.
///
/// ## Firestore schema
/// Document: `config/youtube`
/// ```json
/// {
///   "channelId": "",
///   "channelUrl": "",
///   "playlistId": "",
///   "topVideo": "",
///   "welcomePlayer": "",
///   "welcomeCoach": "",
///   "videos": [
///     { "id": "...", "title": "...", "description": "...", "thumbnailUrl": "..." }
///   ]
/// }
/// ```
class YoutubeConfig {
  const YoutubeConfig({
    this.channelId = '',
    this.channelUrl = '',
    this.playlistId = '',
    this.topVideo = '',
    this.welcomePlayer = '',
    this.welcomeCoach = '',
    this.videos = const <YoutubeVideoEntry>[],
  });

  static const YoutubeConfig defaults = YoutubeConfig();

  /// YouTube channel id (`UC…`).
  final String channelId;

  /// Public channel URL.
  final String channelUrl;

  /// Playlist id used for Astuces (optional).
  final String playlistId;

  /// Video of the week (YouTube video id).
  final String topVideo;

  /// Welcome video for player profiles (YouTube video id).
  final String welcomePlayer;

  /// Welcome video for coach profiles (YouTube video id).
  final String welcomeCoach;

  /// Curated list of Astuce videos.
  final List<YoutubeVideoEntry> videos;

  factory YoutubeConfig.fromMap(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return defaults;

    final rawVideos = data['videos'];
    final videos = <YoutubeVideoEntry>[];
    if (rawVideos is List) {
      for (final entry in rawVideos) {
        if (entry is Map<String, dynamic>) {
          final video = YoutubeVideoEntry.fromMap(entry);
          if (video.id.isNotEmpty) {
            videos.add(video);
          }
        } else if (entry is Map) {
          final video = YoutubeVideoEntry.fromMap(
            Map<String, dynamic>.from(entry),
          );
          if (video.id.isNotEmpty) {
            videos.add(video);
          }
        }
      }
    }

    return YoutubeConfig(
      channelId: (data['channelId'] ?? '').toString().trim(),
      channelUrl: (data['channelUrl'] ?? '').toString().trim(),
      playlistId: (data['playlistId'] ?? '').toString().trim(),
      topVideo: YoutubeConfigService.normalizeVideoId(
            (data['topVideo'] ?? '').toString(),
          ) ??
          '',
      welcomePlayer: YoutubeConfigService.normalizeVideoId(
            (data['welcomePlayer'] ?? '').toString(),
          ) ??
          '',
      welcomeCoach: YoutubeConfigService.normalizeVideoId(
            (data['welcomeCoach'] ?? '').toString(),
          ) ??
          '',
      videos: List<YoutubeVideoEntry>.unmodifiable(videos),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'channelId': channelId.trim(),
      'channelUrl': channelUrl.trim(),
      'playlistId': playlistId.trim(),
      'topVideo': topVideo.trim(),
      'welcomePlayer': welcomePlayer.trim(),
      'welcomeCoach': welcomeCoach.trim(),
      'videos': videos.map((v) => v.toMap()).toList(growable: false),
    };
  }

  YoutubeConfig copyWith({
    String? channelId,
    String? channelUrl,
    String? playlistId,
    String? topVideo,
    String? welcomePlayer,
    String? welcomeCoach,
    List<YoutubeVideoEntry>? videos,
  }) {
    return YoutubeConfig(
      channelId: channelId ?? this.channelId,
      channelUrl: channelUrl ?? this.channelUrl,
      playlistId: playlistId ?? this.playlistId,
      topVideo: topVideo ?? this.topVideo,
      welcomePlayer: welcomePlayer ?? this.welcomePlayer,
      welcomeCoach: welcomeCoach ?? this.welcomeCoach,
      videos: videos ?? this.videos,
    );
  }

  YoutubeVideoEntry? findVideo(String videoId) {
    final normalized = YoutubeConfigService.normalizeVideoId(videoId);
    if (normalized == null || normalized.isEmpty) return null;
    for (final video in videos) {
      if (video.id == normalized) return video;
    }
    return null;
  }
}

/// Loads, streams and (root-only) saves `config/youtube`.
class YoutubeConfigService extends ChangeNotifier {
  YoutubeConfigService._();

  static final YoutubeConfigService instance = YoutubeConfigService._();

  static const String collectionName = 'config';
  static const String documentId = 'youtube';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StreamController<YoutubeConfig> _configController =
      StreamController<YoutubeConfig>.broadcast();

  YoutubeConfig _config = YoutubeConfig.defaults;
  bool _initialized = false;
  Future<void>? _initFuture;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;

  YoutubeConfig get config => _config;

  bool get isInitialized => _initialized;

  Stream<YoutubeConfig> get configStream => _configController.stream;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.collection(collectionName).doc(documentId);

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initFuture ??= _load();
    await _initFuture;
  }

  Future<void> reload() async {
    await _subscription?.cancel();
    _subscription = null;
    _initialized = false;
    _initFuture = null;
    await ensureInitialized();
    notifyListeners();
  }

  /// Live snapshots of `config/youtube` (emits defaults when missing).
  Stream<YoutubeConfig> watch() {
    return _doc.snapshots().map((snapshot) {
      if (!snapshot.exists) return YoutubeConfig.defaults;
      return YoutubeConfig.fromMap(snapshot.data());
    });
  }

  Future<YoutubeConfig> fetch() async {
    final snapshot = await _doc.get();
    if (!snapshot.exists) return YoutubeConfig.defaults;
    return YoutubeConfig.fromMap(snapshot.data());
  }

  Future<void> save(YoutubeConfig config) async {
    await UserRootService.instance.reload();
    if (!UserRootService.instance.isRoot) {
      throw StateError('permission-denied');
    }

    final normalizedVideos = <YoutubeVideoEntry>[];
    final seen = <String>{};
    for (final video in config.videos) {
      final id = normalizeVideoId(video.id);
      final title = video.title.trim();
      if (id == null || id.isEmpty || title.isEmpty) continue;
      if (!seen.add(id)) continue;
      normalizedVideos.add(
        YoutubeVideoEntry(
          id: id,
          title: title,
          description: video.description,
          thumbnailUrl: video.thumbnailUrl,
        ),
      );
    }

    final next = YoutubeConfig(
      channelId: config.channelId.trim(),
      channelUrl: config.channelUrl.trim(),
      playlistId: config.playlistId.trim(),
      topVideo: normalizeVideoId(config.topVideo) ?? '',
      welcomePlayer: normalizeVideoId(config.welcomePlayer) ?? '',
      welcomeCoach: normalizeVideoId(config.welcomeCoach) ?? '',
      videos: normalizedVideos,
    );

    await _doc.set(next.toMap(), SetOptions(merge: true));
    _applyConfig(next);
  }

  Future<void> _load() async {
    await _subscription?.cancel();

    try {
      final doc = await _doc.get();
      if (doc.exists) {
        _applyConfig(YoutubeConfig.fromMap(doc.data()), notify: false);
      } else if (kDebugMode) {
        debugPrint(
          'YoutubeConfigService: $collectionName/$documentId missing — '
          'using defaults',
        );
      }

      _subscription = _doc.snapshots().listen(
        (snapshot) {
          if (!snapshot.exists) return;
          _applyConfig(YoutubeConfig.fromMap(snapshot.data()));
        },
        onError: (Object e, StackTrace st) {
          debugPrint('YoutubeConfigService snapshot error: $e\n$st');
        },
      );
    } catch (e, st) {
      debugPrint('YoutubeConfigService load failed: $e\n$st');
    }

    _initialized = true;
    _configController.add(_config);
    notifyListeners();
  }

  void _applyConfig(YoutubeConfig next, {bool notify = true}) {
    _config = next;
    _configController.add(_config);
    if (notify) {
      notifyListeners();
    }
  }

  /// Extracts a YouTube video id from a raw id or common URL forms.
  ///
  /// Returns null when the value cannot be recognized.
  static String? normalizeVideoId(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;

    // Already a bare id (YouTube ids are typically 11 chars).
    final bare = RegExp(r'^[A-Za-z0-9_-]{6,20}$');
    if (bare.hasMatch(value) && !value.contains('/') && !value.contains('.')) {
      return value;
    }

    final uri = Uri.tryParse(value);
    if (uri == null) return null;

    // youtu.be/<id>
    if (uri.host.contains('youtu.be')) {
      final id = uri.pathSegments.isEmpty ? '' : uri.pathSegments.first.trim();
      return id.isEmpty ? null : id;
    }

    if (uri.host.contains('youtube.com') || uri.host.contains('youtube-nocookie.com')) {
      final v = uri.queryParameters['v']?.trim();
      if (v != null && v.isNotEmpty) return v;

      // /shorts/<id>, /embed/<id>, /live/<id>
      final segments = uri.pathSegments;
      for (var i = 0; i < segments.length - 1; i++) {
        final marker = segments[i].toLowerCase();
        if (marker == 'shorts' || marker == 'embed' || marker == 'live' || marker == 'v') {
          final id = segments[i + 1].trim();
          if (id.isNotEmpty) return id;
        }
      }
    }

    return null;
  }
}
