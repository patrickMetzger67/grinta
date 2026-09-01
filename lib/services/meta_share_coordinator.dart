import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/config/meta_config.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/meta_share_strings.dart';
import 'package:grinta/model/meta_sync_config.dart';
import 'package:grinta/services/meta_connect_service.dart';
import 'package:grinta/services/share_record_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/share_sheet.dart';

enum MetaShareDestination { instagram, facebook, shareSheet }

/// Two share modes:
/// 1. Native PNG share sheet (default if Meta is not connected).
/// 2. Graph API publish only when IG/FB is already connected.
class MetaShareCoordinator {
  MetaShareCoordinator({
    MetaConnectService? connectService,
    ShareRecordService? shareRecordService,
    FirebaseFunctions? functions,
  })  : _connectService = connectService ?? MetaConnectService.instance,
        _shareRecordService = shareRecordService ?? ShareRecordService(),
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: kMetaFunctionsRegion);

  final MetaConnectService _connectService;
  final ShareRecordService _shareRecordService;
  final FirebaseFunctions _functions;

  Future<void> shareOrPublish({
    required BuildContext context,
    required Uint8List pngBytes,
    required String fileName,
    required String statId,
    required String statType,
    String? caption,
    Rect? sharePositionOrigin,
  }) async {
    MetaSyncConfig? status;
    try {
      status = await _connectService.readStatus();
    } catch (e, st) {
      debugPrint('MetaShareCoordinator.readStatus failed: $e\n$st');
    }

    // Not connected → current share sheet. Do not prompt OAuth.
    if (status == null || !status.canPublish) {
      await _shareViaSheet(
        context: context,
        pngBytes: pngBytes,
        fileName: fileName,
        statId: statId,
        statType: statType,
        sharePositionOrigin: sharePositionOrigin,
      );
      return;
    }

    if (!context.mounted) return;
    final destination = await _pickDestination(context, status);
    if (destination == null || !context.mounted) return;

    if (destination == MetaShareDestination.shareSheet) {
      await _shareViaSheet(
        context: context,
        pngBytes: pngBytes,
        fileName: fileName,
        statId: statId,
        statType: statType,
        sharePositionOrigin: sharePositionOrigin,
      );
      return;
    }

    await _publishViaApi(
      context: context,
      platform: destination == MetaShareDestination.instagram
          ? 'instagram'
          : 'facebook',
      pngBytes: pngBytes,
      statId: statId,
      statType: statType,
      caption: caption,
    );
  }

  Future<void> _shareViaSheet({
    required BuildContext context,
    required Uint8List pngBytes,
    required String fileName,
    required String statId,
    required String statType,
    Rect? sharePositionOrigin,
  }) async {
    final result = await sharePng(
      pngBytes: pngBytes,
      fileName: fileName,
      sharePositionOrigin: sharePositionOrigin,
    );
    if (!context.mounted) return;
    await _shareRecordService.recordIfShared(
      result: result,
      statId: statId,
      statType: statType,
    );
  }

  Future<void> _publishViaApi({
    required BuildContext context,
    required String platform,
    required Uint8List pngBytes,
    required String statId,
    required String statType,
    String? caption,
  }) async {
    final strings = MetaShareStrings.of(context.l10n);
    try {
      final callable = _functions.httpsCallable(
        kMetaPublishFunctionName,
        options: HttpsCallableOptions(timeout: const Duration(seconds: 70)),
      );
      await callable.call(<String, dynamic>{
        'platform': platform,
        'imageBase64': base64Encode(pngBytes),
        'caption': caption ?? '',
        'statId': statId,
        'statType': statType,
      });
      if (context.mounted) {
        AppSnackbar.show(context, strings.publishSuccess, isError: false);
      }
    } catch (e, st) {
      debugPrint('publishShareToMeta failed: $e\n$st');
      if (context.mounted) {
        AppSnackbar.show(context, strings.publishFailed, isError: true);
      }
    }
  }

  Future<MetaShareDestination?> _pickDestination(
    BuildContext context,
    MetaSyncConfig status,
  ) {
    final strings = MetaShareStrings.of(context.l10n);
    final colors = context.appColors;
    return showModalBottomSheet<MetaShareDestination>(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(strings.publishTitle, style: settingsMenuTitle(sheetContext)),
              const SizedBox(height: 8),
              if (status.hasInstagram)
                ListTile(
                  leading: Icon(Icons.camera_alt_outlined, color: colors.primary),
                  title: Text(strings.publishInstagram),
                  onTap: () => Navigator.pop(
                    sheetContext,
                    MetaShareDestination.instagram,
                  ),
                ),
              if (status.hasFacebookPage)
                ListTile(
                  leading: Icon(Icons.facebook, color: colors.primary),
                  title: Text(strings.publishFacebook),
                  onTap: () => Navigator.pop(
                    sheetContext,
                    MetaShareDestination.facebook,
                  ),
                ),
              ListTile(
                leading: Icon(Icons.ios_share_outlined, color: colors.primary),
                title: Text(strings.publishShareSheet),
                onTap: () => Navigator.pop(
                  sheetContext,
                  MetaShareDestination.shareSheet,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

TextStyle settingsMenuTitle(BuildContext context) {
  final base = Theme.of(context).textTheme.titleMedium ??
      Theme.of(context).textTheme.bodyLarge!;
  return base.copyWith(
    color: context.appColors.textPrimary,
    fontWeight: FontWeight.w600,
  );
}
