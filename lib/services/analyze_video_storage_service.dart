import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/services/analyze_video_match_selection.dart';
import 'package:grinta/services/analyze_video_tactics.dart';

const int kDebugVideoMaxBytes = 200 * 1024 * 1024;
const String kDebugVideoFolder = 'video';
const String kDebugVideoContentType = 'video/mp4';

enum DebugVideoStorageError {
  notSignedIn,
  invalidFormat,
  tooLarge,
  emptyFile,
  uploadFailed,
}

class DebugVideoStorageException implements Exception {
  const DebugVideoStorageException(this.code, [this.details]);

  final DebugVideoStorageError code;
  final Object? details;

  @override
  String toString() => 'DebugVideoStorageException($code, $details)';
}

class DebugVideoItem {
  const DebugVideoItem({
    required this.name,
    required this.storagePath,
    required this.downloadUrl,
    this.matchId,
    this.teamId,
    this.seasonId,
    this.matchLabel,
    this.team1KitColor,
    this.team2KitColor,
    this.refereeKitColor,
  });

  final String name;
  final String storagePath;
  final String downloadUrl;
  final String? matchId;
  final String? teamId;
  final String? seasonId;
  final String? matchLabel;
  final String? team1KitColor;
  final String? team2KitColor;
  final String? refereeKitColor;
}

DebugVideoItem debugVideoItemWithMetadata({
  required String name,
  required String storagePath,
  required String downloadUrl,
  Map<String, String>? customMetadata,
}) {
  final metadata = customMetadata ?? const <String, String>{};
  String? read(String key) {
    final value = metadata[key]?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  return DebugVideoItem(
    name: name,
    storagePath: storagePath,
    downloadUrl: downloadUrl,
    matchId: read('matchId'),
    teamId: read('teamId'),
    seasonId: read('seasonId'),
    matchLabel: read('matchLabel'),
    team1KitColor: read('team1KitColor'),
    team2KitColor: read('team2KitColor'),
    refereeKitColor: read('refereeKitColor'),
  );
}

bool isDebugVideoMp4Filename(String name) {
  return name.trim().toLowerCase().endsWith('.mp4');
}

bool isDebugVideoWithinSizeLimit(int byteLength) {
  return byteLength > 0 && byteLength <= kDebugVideoMaxBytes;
}

String sanitizeDebugVideoFilename(String originalName) {
  final trimmed = originalName.trim();
  final lastDot = trimmed.lastIndexOf('.');
  var base = lastDot > 0 ? trimmed.substring(0, lastDot) : trimmed;
  var ext = lastDot > 0 ? trimmed.substring(lastDot + 1) : 'mp4';
  base = base.replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_');
  base = base.replaceAll(RegExp(r'_+'), '_');
  base = base.replaceAll(RegExp(r'^_+|_+$'), '');
  if (base.isEmpty) base = 'video';
  ext = ext.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '').toLowerCase();
  if (ext.isEmpty) ext = 'mp4';
  return '$base.$ext';
}

String buildDebugVideoStoragePath({
  required String uid,
  required String originalName,
  required int timestampMs,
}) {
  final safeUid = uid.trim();
  final safeName = sanitizeDebugVideoFilename(originalName);
  return '$kDebugVideoFolder/$safeUid/${timestampMs}_$safeName';
}

class DebugVideoStorageService {
  DebugVideoStorageService({
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  static final DebugVideoStorageService instance = DebugVideoStorageService();

  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  String? get _uid {
    final uid = _auth.currentUser?.uid.trim();
    if (uid == null || uid.isEmpty) return null;
    return uid;
  }

  void validateMp4({
    required String filename,
    required int byteLength,
  }) {
    if (byteLength <= 0) {
      throw const DebugVideoStorageException(DebugVideoStorageError.emptyFile);
    }
    if (!isDebugVideoMp4Filename(filename)) {
      throw const DebugVideoStorageException(
        DebugVideoStorageError.invalidFormat,
      );
    }
    if (!isDebugVideoWithinSizeLimit(byteLength)) {
      throw const DebugVideoStorageException(DebugVideoStorageError.tooLarge);
    }
  }

  Future<DebugVideoItem> uploadMp4({
    required Uint8List bytes,
    required String filename,
    void Function(double progress)? onProgress,
    String? matchId,
    String? teamId,
    String? seasonId,
    String? matchLabel,
    String? team1KitColor,
    String? team2KitColor,
    String? refereeKitColor,
  }) async {
    final uid = _uid;
    if (uid == null) {
      throw const DebugVideoStorageException(DebugVideoStorageError.notSignedIn);
    }

    validateMp4(filename: filename, byteLength: bytes.lengthInBytes);

    final path = buildDebugVideoStoragePath(
      uid: uid,
      originalName: filename,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
    );
    final ref = _storage.ref().child(path);
    final customMetadata = debugVideoMatchMetadata(
      matchId: matchId,
      teamId: teamId,
      seasonId: seasonId,
      matchLabel: matchLabel,
      team1KitColor: team1KitColor,
      team2KitColor: team2KitColor,
      refereeKitColor: refereeKitColor,
    );
    final task = ref.putData(
      bytes,
      SettableMetadata(
        contentType: kDebugVideoContentType,
        customMetadata: customMetadata.isEmpty ? null : customMetadata,
      ),
    );

    final subscription = task.snapshotEvents.listen((TaskSnapshot snapshot) {
      final total = snapshot.totalBytes;
      if (total <= 0) return;
      onProgress?.call(
        (snapshot.bytesTransferred / total).clamp(0.0, 1.0),
      );
    });

    try {
      await task;
      onProgress?.call(1);
      final downloadUrl = await ref.getDownloadURL();
      return debugVideoItemWithMetadata(
        name: ref.name,
        storagePath: path,
        downloadUrl: downloadUrl,
        customMetadata: customMetadata,
      );
    } catch (error, stackTrace) {
      debugPrint('DebugVideoStorageService: upload failed: $error\n$stackTrace');
      throw DebugVideoStorageException(
        DebugVideoStorageError.uploadFailed,
        error,
      );
    } finally {
      await subscription.cancel();
    }
  }

  Future<List<DebugVideoItem>> listUserVideos() async {
    final uid = _uid;
    if (uid == null) {
      throw const DebugVideoStorageException(DebugVideoStorageError.notSignedIn);
    }

    final result = await _storage.ref().child('$kDebugVideoFolder/$uid').listAll();
    final items = <DebugVideoItem>[];
    for (final ref in result.items) {
      if (!isDebugVideoMp4Filename(ref.name)) continue;
      try {
        final downloadUrl = await ref.getDownloadURL();
        Map<String, String>? customMetadata;
        try {
          final metadata = await ref.getMetadata();
          customMetadata = metadata.customMetadata;
        } catch (_) {}
        items.add(
          debugVideoItemWithMetadata(
            name: ref.name,
            storagePath: ref.fullPath,
            downloadUrl: downloadUrl,
            customMetadata: customMetadata,
          ),
        );
      } catch (error) {
        debugPrint(
          'DebugVideoStorageService: skip ${ref.fullPath}: $error',
        );
      }
    }
    items.sort((a, b) => b.name.compareTo(a.name));
    return items;
  }

  Future<void> saveTacticsRecording({
    required String videoStoragePath,
    required AnalyzeTacticsRecording recording,
  }) async {
    final uid = _uid;
    if (uid == null) {
      throw const DebugVideoStorageException(DebugVideoStorageError.notSignedIn);
    }
    final path = tacticsStoragePathForVideo(videoStoragePath);
    if (path.isEmpty) {
      throw const DebugVideoStorageException(DebugVideoStorageError.emptyFile);
    }
    final bytes = Uint8List.fromList(
      utf8.encode(jsonEncode(recording.toJson())),
    );
    try {
      await _storage.ref().child(path).putData(
        bytes,
        SettableMetadata(contentType: 'application/json'),
      );
    } catch (error, stackTrace) {
      debugPrint('DebugVideoStorageService: tactics save failed: $error\n$stackTrace');
      throw DebugVideoStorageException(
        DebugVideoStorageError.uploadFailed,
        error,
      );
    }
  }

  Future<void> deleteTacticsRecording(String videoStoragePath) async {
    final path = tacticsStoragePathForVideo(videoStoragePath);
    if (path.isEmpty) return;
    try {
      await _storage.ref().child(path).delete();
    } catch (_) {}
  }

  Future<AnalyzeTacticsRecording?> loadTacticsRecording(
    String videoStoragePath,
  ) async {
    final path = tacticsStoragePathForVideo(videoStoragePath);
    if (path.isEmpty) return null;
    try {
      final data = await _storage.ref().child(path).getData(8 * 1024 * 1024);
      if (data == null || data.isEmpty) return null;
      final decoded = jsonDecode(utf8.decode(data));
      if (decoded is! Map) return null;
      return AnalyzeTacticsRecording.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List> downloadVideoBytes(String storagePath) async {
    final path = storagePath.trim();
    if (path.isEmpty) {
      throw const DebugVideoStorageException(DebugVideoStorageError.emptyFile);
    }
    final data = await _storage.ref().child(path).getData(kDebugVideoMaxBytes);
    if (data == null || data.isEmpty) {
      throw const DebugVideoStorageException(DebugVideoStorageError.emptyFile);
    }
    return data;
  }
}
