import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/fieldGpsCorners.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/screen/field_localization_screen.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/tracker_field_service.dart';
import 'package:grinta/util/french_address_parser.dart';

/// Shared field GPS resolution + localization UI (USB sync and Intense).
class FieldGpsLocalizationHelper {
  FieldGpsLocalizationHelper._();

  /// Ensures [match] has GPS corners for pitch heatmap analysis.
  ///
  /// Order: match document → `TRACKER_Fields` → confirm dialog → localization
  /// screen. Returns `null` if the user declines or cancels.
  static Future<FieldGpsCorners?> ensureMatchFieldGpsCorners(
    BuildContext context, {
    required models.Match match,
    MatchService? matchService,
    TrackerFieldService? trackerFieldService,
    bool askConfirmation = true,
  }) async {
    if (match.fieldGpsCorners != null) {
      return match.fieldGpsCorners;
    }

    final fieldService = trackerFieldService ?? TrackerFieldService();
    final matches = matchService ?? MatchService();

    final stored = await loadFieldGpsCornersFromTrackerFields(
      match,
      trackerFieldService: fieldService,
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
    );
  }

  static Future<FieldGpsCorners?> loadFieldGpsCornersFromTrackerFields(
    models.Match match, {
    TrackerFieldService? trackerFieldService,
  }) async {
    final fieldService = trackerFieldService ?? TrackerFieldService();
    final fieldId = match.fieldId?.trim() ?? '';
    if (fieldId.isNotEmpty) {
      final byId = await fieldService.getById(fieldId);
      if (byId?.fieldGpsCorners != null) return byId!.fieldGpsCorners;
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
    return trackerField?.fieldGpsCorners;
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

  /// Opens the localization screen and persists corners on the match +
  /// `TRACKER_Fields`.
  static Future<FieldGpsCorners?> localizeAndSaveMatchField(
    BuildContext context, {
    required models.Match match,
    MatchService? matchService,
    TrackerFieldService? trackerFieldService,
  }) async {
    final result = await openLocalizationScreen(
      context,
      initialName: match.nomDuTerrain?.trim() ?? '',
      initialAddress: match.terrainAdresse1?.trim() ?? '',
    );
    if (result == null || !context.mounted) return null;

    match.fieldGpsCorners = result.fieldGpsCorners;
    try {
      await (matchService ?? MatchService()).updateMatch(match);
    } catch (e) {
      debugPrint('localizeAndSaveMatchField updateMatch failed: $e');
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final terrainNom = result.fieldName.trim().isNotEmpty
          ? result.fieldName.trim()
          : (match.nomDuTerrain?.trim() ?? '');
      try {
        await (trackerFieldService ?? TrackerFieldService())
            .saveFromMatchLocalization(
          terrainNom: terrainNom,
          terrainAdresse1: match.terrainAdresse1 ?? '',
          fieldGpsCorners: result.fieldGpsCorners,
          uid: uid,
        );
      } catch (e) {
        debugPrint('TrackerFieldService save failed: $e');
      }
    }

    return result.fieldGpsCorners;
  }

  /// Opens the field localization screen (admin / match / discovery).
  static Future<FieldLocalizationResult?> openLocalizationScreen(
    BuildContext context, {
    String initialName = '',
    String initialAddress = '',
  }) {
    return Navigator.push<FieldLocalizationResult>(
      context,
      analyticsMaterialRoute(
        screenName: AnalyticsScreenNames.fields,
        builder: (_) => FootballFieldLocalizationScreen(
          initialName: initialName,
          initialAddress: initialAddress,
        ),
      ),
    );
  }

  /// Saves a localization result to `TRACKER_Fields` (admin tooling).
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
}
