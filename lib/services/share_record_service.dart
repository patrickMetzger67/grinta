import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/model/share.dart';
import 'package:share_plus/share_plus.dart' hide Share;

export 'package:grinta/model/share.dart' show Share, ShareStatType, ShareStatus;

/// Firestore `share` (singular — same convention as `team`, `season`, `ranking`).
abstract final class ShareCollections {
  static const share = 'share';
  static const shareScore = 'shareScore';
}

/// Points for the share ranking (no existing XP system in the app).
abstract final class ShareScorePoints {
  static const perShare = 10;
  static const perView = 1;
  static const perInteraction = 2;
}

/// Maps iOS/Android share-sheet activity identifiers to a social network.
///
/// Snapchat: out of scope for insights (no official API in this slice).
/// WhatsApp stays on the native share sheet (no views).
String shareNetworkFromActivity(String? raw) {
  final value = (raw ?? '').trim().toLowerCase();
  if (value.isEmpty ||
      value.contains('unavailable') ||
      value.contains('dismiss')) {
    return 'unknown';
  }
  if (value.contains('whatsapp')) return 'whatsapp';
  if (value.contains('instagram')) return 'instagram';
  if (value.contains('facebook') || value.contains('messenger')) {
    return 'facebook';
  }
  if (value.contains('twitter') ||
      value.contains('x-client') ||
      value.contains('.x.') ||
      value.endsWith('.x') ||
      value.contains('com.twitter')) {
    return 'twitter';
  }
  if (value.contains('tiktok')) return 'tiktok';
  if (value.contains('message') || value.contains('sms')) return 'messages';
  if (value.contains('mail') || value.contains('gmail')) return 'mail';
  if (value.contains('telegram')) return 'telegram';
  if (value.contains('snapchat')) return 'snapchat';
  if (value.contains('linkedin')) return 'linkedin';
  return 'other';
}

bool shouldPersistShareResult(ShareResult result) {
  return result.status == ShareResultStatus.success ||
      result.status == ShareResultStatus.unavailable;
}

Share buildShare({
  required String userId,
  required String statId,
  required String statType,
  required String where,
  String? platformShareId,
}) {
  return Share(
    userId: userId,
    where: where,
    platformShareId: platformShareId,
    statId: statId,
    statType: statType,
    status: ShareStatus.shared,
    views: 0,
    interactions: 0,
  );
}

Map<String, dynamic> buildShareScoreCreate({required String userId}) {
  return <String, dynamic>{
    'userId': userId,
    'shareCount': 1,
    'sharePoints': ShareScorePoints.perShare,
    'views': 0,
    'interactions': 0,
    'viewPoints': 0,
    'interactionPoints': 0,
    'totalPoints': ShareScorePoints.perShare,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

/// Persists a successful native share and increments [shareScore]/{userId}.
class ShareRecordService {
  ShareRecordService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> recordIfShared({
    required ShareResult result,
    required String statId,
    required String statType,
  }) async {
    if (!shouldPersistShareResult(result)) return;

    final userId = _auth.currentUser?.uid.trim() ?? '';
    if (userId.isEmpty) {
      debugPrint('ShareRecordService: skip persist, no signed-in user');
      return;
    }

    final trimmedStatId = statId.trim();
    if (trimmedStatId.isEmpty) {
      debugPrint('ShareRecordService: skip persist, empty statId');
      return;
    }

    final where = shareNetworkFromActivity(result.raw);
    final platformShareId = result.raw.trim().isEmpty ? null : result.raw.trim();

    try {
      await _firestore.collection(ShareCollections.share).add(
            buildShare(
              userId: userId,
              statId: trimmedStatId,
              statType: statType,
              where: where,
              platformShareId: platformShareId,
            ).toCreateMap(),
          );
      await _incrementShareScore(userId);
    } catch (e, st) {
      debugPrint('ShareRecordService.recordIfShared failed: $e\n$st');
    }
  }

  Future<void> _incrementShareScore(String userId) async {
    final ref =
        _firestore.collection(ShareCollections.shareScore).doc(userId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        tx.set(ref, buildShareScoreCreate(userId: userId));
        return;
      }
      tx.update(ref, <String, dynamic>{
        'shareCount': FieldValue.increment(1),
        'sharePoints': FieldValue.increment(ShareScorePoints.perShare),
        'totalPoints': FieldValue.increment(ShareScorePoints.perShare),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
