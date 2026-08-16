import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/fieldGpsCorners.dart';
import 'package:grinta/model/field_club.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/screen/field_localization_screen.dart';
import 'package:grinta/services/field_club_service.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/tracker_field_service.dart';
import 'package:grinta/util/french_address_parser.dart';

/// Shared field GPS resolution + localization UI (USB sync and Intense).
class FieldGpsLocalizationHelper {
  FieldGpsLocalizationHelper._();

  /// Returns [corners] when all four pitch corners are present.
  ///
  /// Used to decide whether stored GPS can be reused without re-prompting.
  /// Incomplete outlines are ignored so the user can fix them.
  static FieldGpsCorners? completeCornersOrNull(FieldGpsCorners? corners) {
    if (corners == null || !corners.isComplete) return null;
    return corners;
  }

  /// Ensures [match] has GPS corners for pitch-aligned heatmap analysis.
  ///
  /// Order: match document → `fieldClub` (by [models.Match.fieldId]) →
  /// `TRACKER_Fields` → confirm dialog → localization screen.
  /// Returns `null` if the user declines or cancels — callers should still
  /// sync and fall back to the satellite heatmap from GPS samples.
  static Future<FieldGpsCorners?> ensureMatchFieldGpsCorners(
    BuildContext context, {
    required models.Match match,
    MatchService? matchService,
    TrackerFieldService? trackerFieldService,
    FieldClubService? fieldClubService,
    bool askConfirmation = true,
  }) async {
    final fromMatch = completeCornersOrNull(match.fieldGpsCorners);
    if (fromMatch != null) {
      return fromMatch;
    }

    final fieldService = trackerFieldService ?? TrackerFieldService();
    final clubService = fieldClubService ?? FieldClubService();
    final matches = matchService ?? MatchService();

    final stored = await loadStoredFieldGpsCorners(
      match,
      trackerFieldService: fieldService,
      fieldClubService: clubService,
    );
    if (stored != null) {
      match.fieldGpsCorners = stored;
      try {
        await matches.updateMatch(match);
      } catch (e) {
        debugPrint('ensureMatchFieldGpsCorners updateMatch failed: $e');
      }
      return stored;
    }

    if (!context.mounted) return null;

    if (askConfirmation) {
      final shouldLocalize = await confirmFieldGeolocation(context);
      if (shouldLocalize != true || !context.mounted) return null;
    }

    return localizeAndSaveMatchField(
      context,
      match: match,
      matchService: matches,
      trackerFieldService: fieldService,
      fieldClubService: clubService,
    );
  }

  /// Loads pitch GPS for a match without prompting.
  ///
  /// Prefers `fieldClub/{fieldId}` (match create/edit + admin), then falls back
  /// to legacy `TRACKER_Fields` (USB sync address-hash ids).
  static Future<FieldGpsCorners?> loadStoredFieldGpsCorners(
    models.Match match, {
    TrackerFieldService? trackerFieldService,
    FieldClubService? fieldClubService,
  }) async {
    final fromClub = await loadFieldGpsCornersByFieldId(
      match.fieldId,
      fieldClubService: fieldClubService,
      trackerFieldService: trackerFieldService,
    );
    if (fromClub != null) return fromClub;

    return loadFieldGpsCornersFromTrackerFields(
      match,
      trackerFieldService: trackerFieldService,
    );
  }

  /// Resolves GPS corners by document id: `fieldClub` first, then
  /// `TRACKER_Fields` (legacy).
  static Future<FieldGpsCorners?> loadFieldGpsCornersByFieldId(
    String? fieldId, {
    FieldClubService? fieldClubService,
    TrackerFieldService? trackerFieldService,
  }) async {
    final id = fieldId?.trim() ?? '';
    if (id.isEmpty) return null;

    try {
      final clubField =
          await (fieldClubService ?? FieldClubService()).getById(id);
      final fromClub = completeCornersOrNull(clubField?.fieldGpsCorners);
      if (fromClub != null) return fromClub;
    } catch (e) {
      debugPrint('loadFieldGpsCornersByFieldId fieldClub failed: $e');
    }

    try {
      final trackerField =
          await (trackerFieldService ?? TrackerFieldService()).getById(id);
      return completeCornersOrNull(trackerField?.fieldGpsCorners);
    } catch (e) {
      debugPrint('loadFieldGpsCornersByFieldId TRACKER_Fields failed: $e');
      return null;
    }
  }

  static Future<FieldGpsCorners?> loadFieldGpsCornersFromTrackerFields(
    models.Match match, {
    TrackerFieldService? trackerFieldService,
  }) async {
    final fieldService = trackerFieldService ?? TrackerFieldService();
    final fieldId = match.fieldId?.trim() ?? '';
    if (fieldId.isNotEmpty) {
      final byId = await fieldService.getById(fieldId);
      final fromId = completeCornersOrNull(byId?.fieldGpsCorners);
      if (fromId != null) return fromId;
    }

    final terrainNom = match.nomDuTerrain?.trim() ?? '';
    final parsed =
        FrenchAddressParser.parseTerrainAdresse1(match.terrainAdresse1);
    final computedId = FrenchAddressParser.computeFieldId(
      terrainNom: terrainNom.isNotEmpty
          ? terrainNom
          : (match.terrainAdresse1?.trim() ?? ''),
      ville: parsed.ville,
    );
    if (computedId.isEmpty) return null;

    final trackerField = await fieldService.getById(computedId);
    return completeCornersOrNull(trackerField?.fieldGpsCorners);
  }

  static Future<bool?> confirmFieldGeolocation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.syncFieldGeolocationPromptTitle),
        content: Text(dialogContext.l10n.syncFieldGeolocationPromptMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.l10n.actionNo),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.l10n.actionYes),
          ),
        ],
      ),
    );
  }

  /// Opens the localization screen and persists corners on the match,
  /// `fieldClub` (when [models.Match.fieldId] points there), and
  /// `TRACKER_Fields` (legacy address-hash cache).
  ///
  /// Prefills the map with match / fieldClub corners when available so the
  /// pitch outline (“tracé”) is visible when revisiting an already geolocated
  /// field.
  static Future<FieldGpsCorners?> localizeAndSaveMatchField(
    BuildContext context, {
    required models.Match match,
    MatchService? matchService,
    TrackerFieldService? trackerFieldService,
    FieldClubService? fieldClubService,
  }) async {
    final clubService = fieldClubService ?? FieldClubService();
    final fieldService = trackerFieldService ?? TrackerFieldService();

    FieldClub? clubField;
    final fieldId = match.fieldId?.trim() ?? '';
    if (fieldId.isNotEmpty) {
      try {
        clubField = await clubService.getById(fieldId);
      } catch (e) {
        debugPrint('localizeAndSaveMatchField load fieldClub failed: $e');
      }
    }

    final existingCorners = completeCornersOrNull(match.fieldGpsCorners) ??
        completeCornersOrNull(clubField?.fieldGpsCorners) ??
        await loadStoredFieldGpsCorners(
          match,
          trackerFieldService: fieldService,
          fieldClubService: clubService,
        );
    if (!context.mounted) return null;

    final geo = clubField?.location?.geopoint;
    final result = await openLocalizationScreen(
      context,
      initialName: (match.nomDuTerrain?.trim().isNotEmpty == true)
          ? match.nomDuTerrain!.trim()
          : (clubField?.name.trim() ?? ''),
      initialAddress: (match.terrainAdresse1?.trim().isNotEmpty == true)
          ? match.terrainAdresse1!.trim()
          : (clubField?.address.trim() ?? ''),
      initialFieldGpsCorners: existingCorners,
      initialTarget: geo == null ? null : LatLng(geo.latitude, geo.longitude),
    );
    if (result == null || !context.mounted) return null;

    return persistMatchFieldGpsCorners(
      match: match,
      corners: result.fieldGpsCorners,
      fieldName: result.fieldName,
      fieldAddress: result.fieldAddress,
      matchService: matchService,
      trackerFieldService: fieldService,
      fieldClubService: clubService,
      existingFieldClub: clubField,
    );
  }

  /// Persists [corners] on the match, linked `fieldClub`, and legacy
  /// `TRACKER_Fields` cache.
  static Future<FieldGpsCorners> persistMatchFieldGpsCorners({
    required models.Match match,
    required FieldGpsCorners corners,
    String fieldName = '',
    String fieldAddress = '',
    MatchService? matchService,
    TrackerFieldService? trackerFieldService,
    FieldClubService? fieldClubService,
    FieldClub? existingFieldClub,
  }) async {
    match.fieldGpsCorners = corners;
    final name = fieldName.trim().isNotEmpty
        ? fieldName.trim()
        : (match.nomDuTerrain?.trim() ?? '');
    if (name.isNotEmpty) {
      match.nomDuTerrain = name;
    }
    final address = fieldAddress.trim().isNotEmpty
        ? fieldAddress.trim()
        : (match.terrainAdresse1?.trim() ?? '');
    if (address.isNotEmpty) {
      match.terrainAdresse1 = address;
    }

    try {
      await (matchService ?? MatchService()).updateMatch(match);
    } catch (e) {
      debugPrint('persistMatchFieldGpsCorners updateMatch failed: $e');
    }

    final clubService = fieldClubService ?? FieldClubService();
    final fieldId = match.fieldId?.trim() ?? '';
    if (fieldId.isNotEmpty) {
      try {
        final existing =
            existingFieldClub ?? await clubService.getById(fieldId);
        if (existing != null) {
          await clubService.updateFieldGpsCorners(
            fieldClubId: fieldId,
            fieldGpsCorners: corners,
          );
        }
      } catch (e) {
        debugPrint('persistMatchFieldGpsCorners fieldClub update failed: $e');
      }
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await (trackerFieldService ?? TrackerFieldService())
            .saveFromMatchLocalization(
          terrainNom: name,
          terrainAdresse1: match.terrainAdresse1 ?? address,
          fieldGpsCorners: corners,
          uid: uid,
        );
      } catch (e) {
        debugPrint('TrackerFieldService save failed: $e');
      }
    }

    return corners;
  }

  /// Opens the field localization screen (admin / match / discovery).
  static Future<FieldLocalizationResult?> openLocalizationScreen(
    BuildContext context, {
    String initialName = '',
    String initialAddress = '',
    FieldGpsCorners? initialFieldGpsCorners,
    LatLng? initialTarget,
  }) {
    return Navigator.push<FieldLocalizationResult>(
      context,
      analyticsMaterialRoute(
        screenName: AnalyticsScreenNames.fields,
        builder: (_) => FootballFieldLocalizationScreen(
          initialName: initialName,
          initialAddress: initialAddress,
          initialFieldGpsCorners: initialFieldGpsCorners,
          initialTarget: initialTarget ?? const LatLng(46.227638, 2.213749),
        ),
      ),
    );
  }

  /// Saves a localization result to `TRACKER_Fields` (legacy match tooling).
  static Future<void> saveLocalizationResult({
    required FieldLocalizationResult result,
    required String uid,
    TrackerFieldService? trackerFieldService,
  }) async {
    final terrainNom = result.fieldName.trim();
    final address = result.fieldAddress.trim();
    await (trackerFieldService ?? TrackerFieldService())
        .saveFromMatchLocalization(
      terrainNom: terrainNom.isNotEmpty ? terrainNom : address,
      terrainAdresse1: address,
      fieldGpsCorners: result.fieldGpsCorners,
      uid: uid,
    );
  }

  /// Saves a localization result on a `fieldClub` document (admin tooling).
  static Future<FieldClub> saveLocalizationResultToFieldClub({
    required FieldLocalizationResult result,
    required String clubId,
    required String name,
    required String address,
    FieldClub? existing,
    FieldClubService? fieldClubService,
  }) async {
    final normalizedClubId = clubId.trim();
    if (normalizedClubId.isEmpty) {
      throw ArgumentError('clubId must not be empty.');
    }

    final field = FieldClub(
      id: existing?.id ?? '',
      address: address.trim(),
      clubId: normalizedClubId,
      name: name.trim(),
      location: existing?.location,
      surface: existing?.surface,
      updateDate: existing?.updateDate,
      fieldGpsCorners: result.fieldGpsCorners,
    );

    return (fieldClubService ?? FieldClubService()).upsert(field);
  }
}
